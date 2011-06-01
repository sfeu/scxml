require File.dirname(__FILE__) + '/spec_helper'

describe "AIO" do
  before (:each) do
    @statemachine = Statemachine.build do
        superstate :AIO do
           trans :initialized, :organize, :organized
           trans :organized, :present, :presenting
           trans :suspended, :organize, :organized

           superstate :presenting do
             event :suspend, :suspended

             trans :defocused, :focus, :focused
             trans :defocused, :next, :focused#, :focus_next
             trans :defocused, :prev, :focused#, :focus_prev
             trans :defocused, :parent, :focused#, :focus_parent
             trans :focused, :defocus, :defocused
           end
        end
     end
  end


  it "should start in 'initialized'" do
      @statemachine.state.should == :initialized
  end

  it "should enter the superstate" do
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