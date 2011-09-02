# -*- coding: raw-text -*-
require 'rubygems'
require "bundler/setup"
require 'statemachine'
require 'rexml/document'
require 'rexml/streamlistener'

include REXML

class State
  attr_accessor :id, :initial
end

class Transition
  attr_accessor :event, :target, :cond
end

class StatemachineParser < Statemachine::StatemachineBuilder
  include StreamListener

  def initialize(context = nil, logger = nil, queue = nil)
    super()
    @actions = Array.new
    @current_transition = nil
    @current_state = nil
    @current_element = nil
    @parallel = nil
    @state = Array.new
    @statemachine.messenger = logger
    @statemachine.message_queue = queue
    @statemachine.context= context
    @substate = Array.new
    @transitions = Array.new
    @history_states = Array.new
    @history_target = Array.new
    @history_state = nil
    @history = false
    @is_parallel = false
    @scxml_state = false
    @parallel_state = Array.new
  end

  def build_from_scxml(filename)
    source = File.new filename
    Document.parse_stream(source, self)
    @statemachine.reset
	return @statemachine
  end

  # parses scxml directly from string parameter stringbuffer
  def build_from_scxml_string(stringbuffer)
    Document.parse_stream(stringbuffer, self)
    @statemachine.reset
    return @statemachine
  end

  def tag_start(name, attributes)
    case name
      when 'scxml'
        if attributes['name']
          @scxml_state = true
          state = nil
          @current_state = State.new
          @current_state.id = attributes['name']
          @current_state.initial = attributes['initial']
          state = Statemachine::SuperstateBuilder.new(attributes['name'].to_sym, @subject, @statemachine)
          if (@current_state.initial != nil)
            state.startstate(@current_state.initial.to_sym)
          end
          @state.push(state)
        end
      when 'parallel'
        @parallel = Statemachine::ParallelStateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
        @is_parallel = true
        # If there is a state that encapsulates the parallel state, change it to a superstate
        if (not @state.empty? and @state.last.is_a? Statemachine::StateBuilder)
              state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @state.last.subject.superstate, @state.last.subject.statemachine)
              @state.pop            # pops the old one
              @state.push(state)    # pushes the new one
        end
      when 'state'
        @current_state = State.new
        @current_state.id = attributes['id']
        @current_state.initial = attributes['initial']
        if (@state.empty?)  # It is not a substate
           if (@current_state.initial != nil) # AND it is a superstate
             state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
             state.startstate(@current_state.initial.to_sym)
           else  # AND it is a state
             state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
           end
        else # It is a substate
          if (@current_state.initial != nil) # AND it is a superstate
            state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
            state.startstate(@current_state.initial.to_sym)
          else # AND it is a subsubstate
            if (@state.last.is_a? Statemachine::StateBuilder) # but it's parent is not a superstate yet
              state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @state.last.subject.superstate, @state.last.subject.statemachine)
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
        @current_transition.event = attributes['event']
        @current_transition.target = attributes['target']
        if attributes['cond']
          @current_transition.cond = attributes['cond']
        else
          @current_transition.cond = true
        end
        @transitions.push(@current_transition)
      when 'onentry'
      when 'onexit'
      when 'history'
        @history=true
        @history_states.push(@state.last.subject.id)
        @history_state = @state.last.subject.id
      when 'log'
        @actions.push(["log", attributes['expr']])
      when 'send'
        @actions.push(["send", attributes['target'], attributes['event']])
      when 'invoke'
        @actions.push(["invoke", attributes['src'].to_sym])
      else
        @current_element = name
      end
  end

  def tag_end(name)
    case name
      when 'parallel'
        @statemachine.add_state(@parallel.subject)
        @is_parallel = false
      when 'state'
        if (@state.last.is_a? Statemachine::SuperstateBuilder)
          s = statemachine.get_state(@state.last.subject.id)

          # Changing the state's id
          if (s.id == @history_state)
            s.id = (s.id.to_s + "_H").to_sym
            s.default_history=@history_target.last.to_sym
            @history_target.pop
          end

          # Adds the superstate's transitions to all its substates
          @substate.each{|j|
            if (s)
              s1 = statemachine.get_state(j.subject.id)
              s.transitions.each {|v,k|
                if (s1)
                  s1.add(k)
                end
              }
            end
          }
        end
        # In case of parallel statemachines the outmost states will become parallel statemachines
        # only considering parallel on a root level

        if @parallel_state.size == 1 and @parallel.is_a? Statemachine::ParallelStateBuilder
          statemachine_aux = Statemachine::Statemachine.new(@parallel_state.last.subject)
          @substate.each do |j|
            statemachine_aux.add_state(j.subject)
            @statemachine.remove_state(j.subject)
          end
          statemachine_aux.reset
          @parallel.subject.add_statemachine(statemachine_aux)
        end
        @substate.push(@state.last)

        if (@state.size == 1 and not @scxml_state) or (@state.size == 2 and @scxml_state) or (@parallel_state.size == 1)
          @substate = []
          # TODO make this better. Too inefficient
          while (!(@history_states.size == 0))
            # change every transitions where @history_states.last was the target state to history_states.last+"_H"
            # for every history state
            @statemachine.states.each_value do |s|
               s.transitions.each_value do |t|
                 if (t.destination_id == @history_states.last)
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
        if (@transitions.last.event == nil)
          if @history
            @history_target.push(@transitions.last.target)
            @history = false
          else
            # TODO spontaneous transitions
          end
        else
          if (@transitions.last.target != nil)     # if it has a target state
            @state.last.event(@transitions.last.event.to_sym, @transitions.last.target.to_sym, @actions, @transitions.last.cond)
          else                                     # it is its own target state
            @state.last.event(@transitions.last.event.to_sym, @state.last.subject.id.to_sym, @actions, @transitions.last.cond)
          end
        end
        @actions=[]
        @transitions.pop
      when 'onentry'
        @state.last.on_entry(@actions)
        @actions=[]
      when 'onexit'
        @state.last.on_exit(@actions)
        @actions=[]
      when 'history'
        @history = false
    end
  end

  def xmldecl(version, encoding, standalone)
  end
end
