require File.dirname(__FILE__) + '/spec_helper'

describe 'state' do
  before (:each) do
    parser = StatemachineParser.new
    @sm = parser.build_from_scxml "testmachines/handgestures-scxmlgui.scxml"
  end

  it "should start with the correct initial state >no_hands<" do
    @sm.state.should==:no_hands
  end

  it "should support transition to superstate and find correct start state" do
    @sm.one_hand
    @sm.state.should==:wait_one
  end

  it "should leave a deeply nested state through a superstate transition" do
    @sm.two_hands
    @sm.state.should==:wait_two
    @sm.narrow
    @sm.state.should==:narrowing
    @sm.confirm
    @sm.state.should==:narrowed
    @sm.no_hands # transition defined in superstate!
    @sm.state.should == :no_hands
  end

end
