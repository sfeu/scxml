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

  def initialize(logger = nil, queue = nil)
    super()
    @actions = Array.new
    @current_transition = nil
    @current_state = nil
    @current_element = nil
    @parallel = nil
    @state = Array.new
    @statemachine.messenger = logger
    @statemachine.message_queue = queue
    @substate = Array.new
    @transitions = Array.new
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
      when 'parallel'
        @parallel = Statemachine::ParallelStatemachine.new()
      when 'state'
        state = nil
        @current_state = State.new
        @current_state.id = attributes['id']
        @current_state.initial = attributes['initial']
        if (@current_state.initial != nil)                    # we already know it is a superstate
            state = Statemachine::SuperstateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
            state.startstate(@current_state.initial.to_sym)
        else
          if (@state.empty?)      # It isn't a sub state
            state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @subject, @statemachine)
          else                    # this state is a sub state => last state in @state it's its superstate
            if (@state.last.is_a? Statemachine::StateBuilder)       # if @state.last isn't a superstate, change it to one
              state = Statemachine::SuperstateBuilder.new(@state.last.subject.id, @state.last.subject.superstate, @state.last.subject.statemachine)
              @state.pop            # pops the old one
              @state.push(state)    # pushes the new one
            end
            #   @state.last is a superstate => just create the new state using it
            state = Statemachine::StateBuilder.new(attributes['id'].to_sym, @state.last.subject, @statemachine)
          end
        end
        @state.push(state)
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
      when 'log'
        @actions.push(attributes['expr'])
      when 'send'
        @actions.push([attributes['target'], attributes['event']])
      else
        @current_element = name
      end
  end

  def tag_end(name) # think we really need this, since only when reaching the end tag we are sure about that we have added all events, actions and so on.
    case name
      when 'parallel'
        @statemachine = @parallel
      when 'state'
        # Adds the superstate's transitions to all its substates
        if (@state.last.is_a? Statemachine::SuperstateBuilder)
          s = statemachine.get_state(@state.last.subject.id)
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
        # In case of parallel statemachines(?) the outmost states will become parallel statemachines
        # only considering parallel on a root level
        if @state.size == 1 and @parallel.is_a? Statemachine::ParallelStatemachine
          statemachine = Statemachine::Statemachine.new
          @substate.each do |j|
            statemachine.add_state(j)
          end
          @parallel.add(statemachine)
        end

        @substate.push(@state.last)
        @substate = [] if @state.size == 1
        @state.pop
      when 'transition'
        if (@transitions.last.target != nil)     # if it has a target state
          @state.last.event(@transitions.last.event.to_sym, @transitions.last.target.to_sym, @actions, @transitions.last.cond)
        else                                     # it is its own target state
          @state.last.event(@transitions.last.event.to_sym, @state.last.id.to_sym, @actions, @transitions.last.cond)
        end
        @actions=[]
        @transitions.pop
      when 'onentry'
        @state.last.on_entry(@actions)
        @actions=[]
      when 'onexit'
        @state.last.on_exit(@actions)
        @actions=[]
    end
  end

  def xmldecl(version, encoding, standalone)
  end
end
