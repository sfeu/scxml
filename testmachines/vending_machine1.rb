require 'rubygems'
require 'statemachine'

if __FILE__ == $0

	vending_machine = Statemachine.build do
	trans :waiting, :dollar, :paid
	trans :paid, :selection, :waiting
	trans :waiting, :selection, :waiting
	trans :paid, :dollar, :paid
	end
	
	puts vending_machine.state
	vending_machine.dollar
	puts vending_machine.state
	vending_machine.selection
	puts vending_machine.state
end