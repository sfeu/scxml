require 'rubygems'
require 'statemachine'

if __FILE__ == $0
	@state = Statemachine.build do
      state :state1 do
         event :event1, :state2, Proc.new {puts("This is action1")}
      end

      state :state2 do
         event :event2, :state3, Proc.new {puts("This is action2")}
      end

      state :state3 do
         event :event3, :state1, Proc.new {puts("This is action3")}
      end
    end

    @state.event1
    puts @state.state
    @state.event2
    puts @state.state
    @state.event3
    puts @state.state
end
