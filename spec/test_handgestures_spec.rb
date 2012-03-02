require File.dirname(__FILE__) + '/spec_helper'

class TestContext
  def print_distance
  end
  def start_confirm_timeout
  end
  def stop_confirm_timeout
  end
  def reset_confirm_ticker
  end
  def command_timeout_start_prev
  end
  def command_timeout_start_next
  end
  def command_timeout_stop
  end
  def issued_rev
  end
  def issued_next
  end
  def tick
  end
end

describe 'state' do
  before (:each) do
    context = TestContext.new
    parser = StatemachineParser.new(context)
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
