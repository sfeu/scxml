require 'statemachine'
require 'scxml2.rb'

describe 'state' do
  before (:each) do   
    # we could change StatemachineParser.build_from_scxml to something
    # like this - if it helps:
    #
    # @parser = SCXMLParser.new
    # @statemachine = @parser.build_from_scxml "state.xml" 
    
    @state = StatemachineParser.build_from_scxml "state.xml" 
  end

  it "should start with the correct state >state1<" do
    @state.state.should equal(:state1)
  end
  
  it "should support transitions" do
    @state.event1
    @state.state.should==:state2
  end
  
end
