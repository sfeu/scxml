require "spec_helper"

describe "AICommand" do
  before (:each) do
    parser = StatemachineParser.new
    @statemachine = parser.build_from_scxml "aui-scxml/AICommand2.scxml"
   end


  it "should enter the nested superstate :focused" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.state.should == :deactivated
  end

  it "should support transitions inside :focused" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.activate
      @statemachine.state.should == :activated
      @statemachine.deactivate
      @statemachine.state.should == :deactivated
  end

  it "should leave the superstate :focused and return to the same point it left" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.activate
      @statemachine.state.should == :activated
      @statemachine.defocus
      @statemachine.state.should == :defocused
      @statemachine.focus
      @statemachine.state.should == :activated
  end
end