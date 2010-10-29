require 'rubygems'
require 'statemachine'

if __FILE__ == $0
	@state = Statemachine.build do
      state :state1 do
         event :event1, :state2, Proc.new {puts("This is action1")}
      end
    end

    @state.event1
    puts @state.state
end
