require 'statemachine'
require 'scxml2.rb'

describe 'state' do
  before (:each) do   
    # we could change StatemachineParser.build_from_scxml to something
    # like this - if it helps:
    #
    @parser = StatemachineParser.new
    @statemachine = @parser.build_from_scxml "testmachines/state.xml" 
    
    #@state = StatemachineParser.build_from_scxml "state.xml" 
  end

  it "should start with the correct state >state1<" do
    @statemachine.state.should equal(:state1)
  end
  
  it "should support transitions" do
    @statemachine.event1
    @statemachine.state.should==:state2
  end
  
end
