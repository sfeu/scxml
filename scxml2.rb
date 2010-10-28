# -*- coding: utf-8 -*-
require 'rubygems'
require 'statemachine'
require 'rexml/document'
require 'rexml/streamlistener'

include REXML

class State
  attr_accessor :id, :initial
end

class Transition
  attr_accessor :event, :target, :action
end

class StatemachineParser < Statemachine:: StatemachineBuilder
  include StreamListener
 
  def initialize
	super
    # derived by super class Statemachinebuilder - you need to understand how both variables @statemachine and @subject are used in the builders
    #@statemachine = nil
    @current_transition = nil
    @current_state = nil
    @current_element = nil
    @transitions = Array.new
    @actions = Array.new
    @state = Array.new
  end

  def build_from_scxml(filename)
    source = File.new filename
    Document.parse_stream(source, self)
    @statemachine.reset
	return @statemachine
  end

  def tag_start(name, attributes)
    case name
      when 'state'
        @current_state = State.new
      @current_state.id = attributes['id']
      @current_state.initial = attributes['initial']        # duvida se realmente precisa - precisamos lembrar o initial estado. pq ele vai ser definido mais tarde!  
        if (@state.empty?)   # este estado nao subestado de ninguem
          if (@current_state.initial != nil)     # se for definido um estado inicial
            @state.push(Statemachine::StateBuilder.new(attributes['id'].to_sym, @subject, @statemachine))  #
            #@state.last.startstate(@current_state.initial.to_sym)
          else
            @state.push(Statemachine::StateBuilder.new(attributes['id'].to_sym, @subject, @statemachine))
          end
        else
           @state.push(Statemachine::StateBuilder.new(attributes['id'].to_sym, @state.last, @statemachine)) # here we need to add your idea with the current_state variable
        end
      when 'transition'
        @current_transition = Transition.new
        @current_transition.event = attributes['event']
        @current_transition.target = attributes['target']
        @transitions.push(@current_transition)
      when 'log'
        @actions.push(attributes['expr'])
      else
        @current_element = name
      end
  end

  def tag_end(name) # think we really need this, since only when reaching the end tag we are sure about that we have added all events, actions and so on.
    case name
      when 'state'
         @state.pop
      when 'transition'
        action = @actions.last
        @state.last.event(@transitions.last.event.to_sym, @transitions.last.target.to_sym, proc { puts action })
        @transitions.pop
        @actions.pop
    end
  end

  def xmldecl(version, encoding, standalone)
  end
end
