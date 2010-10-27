require 'rubygems'
require 'statemachine'

#class StateContext
#
#	def action1
#		puts "This is action1"
#	end
#
#end


if __FILE__ == $0 
	@state = Statemachine.build do
		state :state1 do
			event :event1, :state2#, :action1
		end
	end
end

		