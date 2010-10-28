require 'statemachine'
require 'scxml2.rb'

describe 'state' do
  before (:each) do   
   
    parser = StatemachineParser.new
    @sm = parser.build_from_scxml "testmachines/superstates.xml" 
  end

  it "should start with the correct initial state" do
    @sm.state.should==:child2
  end
  
  it "should support basic transition for nested children states" do
    @sm.to_child1
    @sm.state.should==:child1
  end

end
