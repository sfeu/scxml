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
    @current_transition = nil
    @current_state = nil
    @current_element = nil
    @parallel = nil
    @history_state = nil
    @statemachine.messenger = logger
    @statemachine.message_queue = queue
    @statemachine.context= context
    @actions = Array.new
    @actions_aux = Array.new
    @state = Array.new
    @substate = Array.new
    @transitions = Array.new
    @history_states = Array.new
    @history_target = Array.new
    @parallel_state = Array.new
    @if_actions = Array.new
    @if_actions_aux = Array.new
    @if = Array.new
    @tag = Array.new
    @cond = Array.new
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
        @parallel = Statemachine::ParallelStateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
        @is_parallel = true
        # If there is a state that encapsulates the parallel state, change it to a superstate
        if not @state.empty? and @state.last.is_a? Statemachine::StateBuilder
          state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @state.last.subject.superstate, @state.last.subject.statemachine)
          @state.pop            # pops the old one
          @state.push(state)    # pushes the new one
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
          # It is a substate
          if @current_state.initial != nil
            # and it is a superstate
            if @is_parallel
              state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @parallel.subject, @statemachine)
            else
              state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
            end
            state.startstate(@current_state.initial.to_sym)
          else
            # and it is a state
            if @state.last.is_a? Statemachine::StateBuilder
              # Its parent is not a superstate yet
              if @is_parallel
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
            state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
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
              s.transitions.each do |v,k|
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
              s.transitions.each_value do |t|
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
