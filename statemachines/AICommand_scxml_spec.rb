require File.dirname(__FILE__) + '/../spec_helper'

describe "AIO" do
  before (:each) do
    parser = StatemachineParser.new
    @statemachine = parser.build_from_scxml "aui-scxml/AIO.scxml"
   end


  it "should start in :initialized" do
      @statemachine.state.should == :initialized
  end

  it "should enter the superstate :presenting" do
      @statemachine.organize
      @statemachine.state.should == :organized
      @statemachine.present
      @statemachine.state.should == :defocused
  end

  it "should support transitions inside the superstate" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.state.should == :focused
      @statemachine.defocus
      @statemachine.state.should == :defocused
  end

  it "should leave the superstate" do
      @statemachine.organize
      @statemachine.present
      @statemachine.suspend
      @statemachine.state.should == :suspended
  end
end