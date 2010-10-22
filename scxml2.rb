require 'rubygems'
require 'statemachine'
require 'rexml/document'
require 'rexml/streamlistener'

include REXML
include REXML::StreamListener

class State
  attr_accessor :id, :events
  def initialize
    @events = []
  end
end

class Event
  attr_accessor :event, :target
end

class StatemachineParser

  def self.build_from_scxml(filename)
    @statemachine = nil
    @current_event = nil
    @current_state = nil
	@current_element = nil
	return @statemachine
  end

  def tag_start(name, attributes)
    case name
      when 'state'
        @current_state = State.new
        @current_state.id = attributes['id']
      when 'transition'
        @current_event = Event.new
        @current_event.event = attributes['event']
		@current_event.target = attributes['target']
      else
        @current_element = name
    end
  end

  def tag_end(name)
    case name
      when 'state'
        # Cria em @statemachine um state com id = @current_state.id e block = @current_state.events 
		@statemachine = Statemachine.build.state(@current_state.id,@current_state.events)
	  when 'transition'
        # Cria em @current_state.events um event com event = @current_event.event, destination_id = @current_event.target
		@current_state.events = Statemachine.build.event(@current_event.event, @current_event.target)
	end
  end
end