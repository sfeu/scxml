require 'rubygems'
require 'statemachine'

class TrafficLightContext
 
	attr_accessor :statemachine
	
	def color_green
		puts "red  yellow  :GREEN:"
	end
	
	def color_yellow
		puts "red  :YELLOW:  green"
	end
	
	def color_red
		puts ":RED:  yellow  green"
	end
	
end


traffic_light = Statemachine.build do
	
	superstate :operational do
		startstate :green
		state :green do
			event :change, :yellow
			on_entry :color_green
		end
		state :yellow do
			event :change, :red
			on_entry :color_yellow
		end
		state :red do
			event :change, :green
			on_entry :color_red
		end
		event :pedestrian, :pedestrian_mode, Proc.new {puts "Entering Pedestrian Mode"}
	end
	
	trans :pedestrian_mode, :operate, :operational_H, Proc.new {puts "Exit Pedestrian Mode"}
	
	context TrafficLightContext.new
end

traffic_light.change
traffic_light.change
traffic_light.change
traffic_light.pedestrian
traffic_light.operate
traffic_light.change
traffic_light.change
traffic_light.pedestrian
traffic_light.operate
	