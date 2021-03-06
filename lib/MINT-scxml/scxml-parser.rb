require 'rubygems'
require "bundler/setup"
require 'statemachine'
require 'rexml/document'
require 'rexml/streamlistener'


class State
  attr_accessor :id, :initial
end

class Transition
  attr_accessor :event, :target, :cond
end

class StatemachineParser < Statemachine::StatemachineBuilder
  include REXML
  include StreamListener

  def initialize(context = nil, logger = nil, queue = nil)
    super()

    @statemachine.messenger = logger
    @statemachine.message_queue = queue
    @statemachine.context= context

    # The current variables are used to temporarily store the value of the _"type"
    # in order to acquire the necessary data before adding the to its proper stack
    @current_transition = nil
    @current_state = nil
    @current_element = nil

    # Stacks
    # These stacks (created as Arrays but used as stacks: push & pop) are used
    # to store and treat the structure of the scxml file read.
    # Some require auxiliary stacks due to the necessity of different treatments
    # in different situations (e.g.: substate_aux is necessary due to the fact that
    # a parallel state's superstate can have substates that would only be treated when
    # the superstate is closed, which only happens after the parallel state is treated.
    # Which in turn can have its own set of substates).
    # Obs: These variables are used as stacks due to two basic situations: the ability of
    #      nested elements in statemachines and the need to create a single structure to be
    #      passed to element's constructors.
    @actions = Array.new            # stores the actions to later be added to the transition they belong.
    @actions_aux = Array.new
    @state = Array.new              # stores the order of nested states to be treated and used further on.
    @substate = Array.new           # similar to state, it stores the substates in order to later be added
                                    # and have the proper transition treatment related to its parent state
    @substate_aux = Array.new
    @transitions = Array.new        # stores the transitions in order to be later added to its proper state.
          # so on and so forth.
    @parallel_state = Array.new
    @history_states = Array.new
    @history_target = Array.new

    # These variables are used to store the value of the element that gives its
    # name in order to be used as parameters or "situation check" in future parts
    # of the parser.
    @parallel = nil
    @history_state = nil

    # These variables are used to help in the creation of actions that have if clauses.
    @if_actions = Array.new
    @if_actions_aux = Array.new
    @if = Array.new
    @tag = Array.new
    @cond = Array.new

    # These boolean variables are used to determine in which case we are on
    # so to treat each case properly.
    #   If a history state was read, if inside a parallel state and if it has
    #   an outermost scxml_state (the latter implicates on different treatments due
    #   to the fact that it is added to the states stack and therefore it might not be
    #   empty as expected in certain situations)
    @history = false
    @is_parallel = false
    @scxml_state = false
  end

  # This function parses scxml from a file
  def build_from_scxml(filename)
    source = File.new filename
    Document.parse_stream(source, self)
    #@statemachine.reset
    @statemachine
  end

  # This function parses scxml directly from the string parameter "stringbuffer"
  def build_from_scxml_string(stringbuffer)
    Document.parse_stream(stringbuffer, self)
    #@statemachine.reset
    @statemachine
  end


  # This function deals with the different scenarios for the creation of actions with if
  def creating_ifs
    if @if.size == 1
      @if_actions.push(@if_actions_aux.last) if @if_actions_aux.size != 0
      if @actions_aux.size != 0
        @actions_aux.each do |j|
          @if_actions.push(j)
        end
        @actions_aux = []
      end
      @actions.push([@tag.last, @cond.last, @if_actions])
    else
      if @if_actions.size != 0
        @if_actions_aux.push(@if_actions)
      end
      @actions_aux.push([@tag.last, @cond.last, @if_actions_aux.last])
    end
    @if_actions = []
    @cond.pop
    @tag.pop
    @if_actions_aux.pop if @if_actions_aux.size != 0
  end

  # This function defines the actions to be taken for each different tag when the tag is opened
  def tag_start(name, attributes)
    case name
      when 'scxml'
        # If the initial tag <scxml> has a n  ame attribute, define it as the most outer super state
        if attributes['name']
          @scxml_state = true
          @current_state = State.new
          @current_state.id = attributes['id']
          @current_state.initial = attributes['initial']
          state = Statemachine::SuperstateBuilder.new(attributes['name'].to_sym, @subject, @statemachine)
          # If the current state has an initial state defined, add it to the state created.
          if @current_state.initial != nil
            state.startstate(@current_state.initial.to_sym)
          end
          # Adds it to a list of "open" states
          @state.push(state)
        end
      when 'parallel'
        @is_parallel = true
        # If the parent superstate of the parallel state has substates, save them for later
        if not @substate.empty?
          @substate_aux = @substate
          @substate = []
        end
        # If there is a state that encapsulates the parallel state, change it to a superstate
        if not @state.empty? and @state.last.is_a? Statemachine::StateBuilder
          state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @state.last.subject.superstate, @state.last.subject.statemachine)
          @state.pop            # pops the old one
          @state.push(state)    # pushes the new one
        end
        if @state.empty?
          @parallel = Statemachine::ParallelStateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
        else
          @parallel = Statemachine::ParallelStateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
        end

      when 'state'
        @current_state = State.new
        @current_state.id = attributes['id']
        @current_state.initial = attributes['initial']
        if @state.empty?
          # It is not a substate
          if @current_state.initial != nil
            # and it is a superstate
            state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
            state.startstate(@current_state.initial.to_sym)
          else
            # and it is a state
            state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
          end
        else
          #It is a substate
          if @state.last.is_a? Statemachine::StateBuilder
            # Its parent is not a superstate yet
            if @is_parallel and @parallel_state.empty?
              state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @parallel.subject, @state.last.subject.statemachine)
            else
              state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @state.last.subject.superstate, @state.last.subject.statemachine)
            end
            @state.pop            # pops the old one
            @state.push(state)    # pushes the new one
            if @is_parallel
              @parallel_state.pop
              @parallel_state.push(state)
            end
          end
          if @current_state.initial != nil
            # and it is a superstate
            if @is_parallel and @parallel_state.empty?
              state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @parallel.subject, @statemachine)
            else
              state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
            end
            state.startstate(@current_state.initial.to_sym)
          else
            # and it is a state
            if @is_parallel and @parallel_state.empty?
              state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @parallel.subject, @statemachine)
            else
              state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
            end
          end
        end
        @state.push(state)
        @parallel_state.push(state) if @is_parallel
      when 'transition'
        @current_transition = Transition.new
        if attributes['target'] == @history_state.to_s and @history_state
          @current_transition.target = attributes['target']+"_H"
        else
          @current_transition.target = attributes['target']
        end
        if attributes['event']
          @current_transition.event = attributes['event']
        else
          @current_transition.event = nil
        end
        if attributes['cond']
          @current_transition.cond = attributes['cond']
        else
          @current_transition.cond = true
        end
        @transitions.push(@current_transition)
      when 'onentry'
      when 'onexit'
      when 'history'
        @history = true
        @history_states.push(@state.last.subject.id)
        @history_state = @state.last.subject.id
      when 'if'
        @if.push(true)
        if @if.size >= 1
          @if_actions_aux.push(@if_actions) if @if_actions.size != 0
          @if_actions = []
        end
        @cond.push(attributes['cond'])
        @tag.push("if")
      when 'elseif'
        creating_ifs
        @cond.push(attributes['cond'])
        @tag.push("elseif")
      when 'else'
        creating_ifs
        @cond.push(true)
        @tag.push("else")
      when 'log'
        if @if.last
          @if_actions.push(["log", attributes['expr']])
        else
          @actions.push(["log", attributes['expr']])
        end
      when 'send'
        if @if.last
          @if_actions.push(["send", attributes['target'], attributes['event']])
        else
          @actions.push(["send", attributes['target'], attributes['event']])
        end
      when 'invoke'
        if @if.last
          @if_actions.push(["invoke", attributes['src'].to_sym])
        else
          @actions.push(["invoke", attributes['src'].to_sym])
        end
      when 'script'
        @script = true
        @script_code = ""
      else
        @current_element = name
    end
  end

  # This function defines the actions to be taken for each different tag when the tag is closed
  def tag_end(name)
    case name
      when 'parallel'
        @statemachine.add_state(@parallel.subject)
        @is_parallel = false
        @substate = @substate_aux
        @substate_aux = []
      when 'state'
        if @state.last.is_a? Statemachine::SuperstateBuilder
          s = statemachine.get_state(@state.last.subject.id)

          if (s.id == @history_state)
            if @history_target.last
              s.default_history = @history_target.last.to_sym
              @history_target.pop
            end
          end

          # Every state belonging to this superstate should respond to the superstate's transitions
          @substate.each do |j|
            if s
              s1 = statemachine.get_state(j.subject.id)
              s.transitions.each do |k|
                s1.add(k) if s1
              end
            end
          end
        end

        # In case of parallel statemachines the outmost states will become parallel statemachines
        # only considering parallel on a root level
        if @parallel_state.size == 1 and @parallel.is_a? Statemachine::ParallelStateBuilder
          statemachine_aux = Statemachine::Statemachine.new(@parallel.subject)
          statemachine_aux.add_state(@parallel_state.last.subject)
          @statemachine.remove_state(@parallel_state.last.subject)
          @substate.each do |j|
            j.subject.modify_statemachine(statemachine_aux)
            statemachine_aux.add_state(j.subject)
            @statemachine.remove_state(j.subject)
          end
          #statemachine_aux.reset
          @parallel.subject.add_statemachine(statemachine_aux)
        end

        @substate.push(@state.last)

        if (@state.size == 1 and not @scxml_state) or (@state.size == 2 and @scxml_state) or (@parallel_state.size == 1)
          @substate = []
          # TODO make this better. Too inefficient
          while @history_states.size != 0
            # change every transitions where @history_states.last was the target state to history_states.last+"_H"
            # for every history state
            @statemachine.states.each_value do |s|
              s.transitions.each do |t|
                if t.destination_id == @history_states.last
                  t.destination_id = (t.destination_id.to_s + "_H").to_s
                end
              end
            end
            @history_states.pop
          end
        end
        @state.pop
        @parallel_state.pop if @is_parallel
      when 'transition'
        if @transitions.last.event == nil
          if @history
            @history_target.push(@transitions.last.target)
            @history = false
          else
            if @is_parallel and @parallel_state.empty?
              @parallel.event(nil, @transitions.last.target.to_sym, @actions, @transitions.last.cond)
            else
              @state.last.event(nil, @transitions.last.target.to_sym, @actions, @transitions.last.cond)
            end
          end
        else
          if @transitions.last.target != nil
            if @is_parallel and @parallel_state.empty?
              @parallel.event(@transitions.last.event.to_sym, @transitions.last.target.to_sym, @actions, @transitions.last.cond)
            else
              @state.last.event(@transitions.last.event.to_sym, @transitions.last.target.to_sym, @actions, @transitions.last.cond)
            end
          else
            # if it doesn't have a target state, it is its own target state
            if @is_parallel and @parallel_state.empty?
              @parallel.event(@transitions.last.event.to_sym, @state.last.subject.id.to_sym, @actions, @transitions.last.cond)
            else
              @state.last.event(@transitions.last.event.to_sym, @state.last.subject.id.to_sym, @actions, @transitions.last.cond)
            end
          end
        end
        @actions=[]
        @transitions.pop
      when 'onentry'
        if @is_parallel and @parallel_state.empty?
          @parallel.on_entry(@actions)
        else
          @state.last.on_entry(@actions)
        end
        @actions=[]
      when 'onexit'
        if @is_parallel and @parallel_state.empty?
          @parallel.on_exit(@actions)
        else
          @state.last.on_exit(@actions)
        end
        @actions=[]
      when 'history'
        @history = false
      when 'if'
        creating_ifs
        @if.pop
      when 'script'
        @script = false
        if @if.last
          @if_actions.push(["script", @script_code])
        else
          @actions.push(["script", @script_code])
        end
      else

    end
  end

  def text(text)
    if @script
      @script_code += text
    end
  end

  def xmldecl(version, encoding, standalone)
  end
end
