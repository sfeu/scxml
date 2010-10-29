require 'rubygems'
require 'statemachine'

module Statemachine
class SuperstateBuilder < Builder
    include StateBuilding
    include SuperstateBuilding

    def initialize(id, superstate, statemachine)
      super statemachine
      p "id: #{id}"
      p "superstate: #{superstate}"
      @subject = Superstate.new(id, superstate, statemachine)
      p "subject: #{@subject}"
      superstate.startstate_id = id if superstate.startstate_id == nil
      statemachine.add_state(@subject)
    end
end

    class StateBuilder < Builder
    include StateBuilding

    def initialize(id, superstate, statemachine)
      super statemachine
      p "id: #{id}"
      p "superstate: #{superstate}"
      @subject = acquire_state_in(id, superstate)
      p "subject: #{@subject}"
    end
  end
end


if __FILE__ == $0 
	@state = Statemachine.build do
	  superstate :state do
        startstate :state2
        superstate :state1 do
            state :state4 do
			  event :event4, :state2, Proc.new {puts("This is action4")}
            end
            event :event1, :state4, Proc.new {puts("This is action1")}
        end
        state :state2 do
			event :event2, :state3, Proc.new {puts("This is action2")}
        end
        state :state3 do
			event :event3, :state1, Proc.new {puts("This is action3")}
        end
      end
    end
    
    @state.event2
    puts @state.state
    @state.event3
    puts @state.state
    @state.event1
    puts @state.state
    @state.event4
    puts @state.state
end

		