require 'rubygems'
require 'statemachine'

if __FILE__ == $0
	vending_machine = Statemachine.build do
		superstate :operational do
			state :waiting do
				event :dollar, :paid
				event :selection, :waiting
			end
			trans :paid, :selection, :waiting
			trans :paid, :dollar, :paid
			
			event :repair, :repair_mode, Proc.new {puts "Entering Repair Mode"}
		end
		
		trans :repair_mode, :operate, :operational_H, Proc.new {puts "Exit Repair Mode"}
		
		on_entry_of :waiting, Proc.new {puts "Entering Waiting State"}
		on_entry_of :paid, Proc.new {puts "Entering Paid State"}

	end
	
	vending_machine.repair
	vending_machine.operate
	vending_machine.dollar
	vending_machine.repair
	vending_machine.operate
end