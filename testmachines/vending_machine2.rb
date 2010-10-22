require 'rubygems'
require 'statemachine'

 class VendingMachineContext
	def activate
		puts "activating"
	end
	
	def release(product)
		puts "releasing product: #{product}"
	end
	
	def refund
		puts "refuding dollar"
	end
	
	def sales_mode
		puts "going into sales mode"
	end
	
	def operation_mode
		puts "going into operation mode"
	end
end

if __FILE__ == $0
	vending_machine = Statemachine.build do
		state :waiting do
			event :dollar, :paid, :activate		# event, destination state, action
			event :selection, :waiting
			on_entry :sales_mode				# action
			on_exit :operation_mode
		end
		trans :paid, :selection, :waiting, :release		# state, event, destination state, action
		trans :paid, :dollar, :paid, :refund
		context VendingMachineContext.new				
	end
	
	vending_machine.dollar
	vending_machine.dollar
	vending_machine.selection "Peanuts"
end