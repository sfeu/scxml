require File.dirname(__FILE__) + '/../../spec_helper'

describe "AICommand" do
  before (:each) do
    @statemachine = Statemachine.build do
        superstate :AICommand do
          trans :initialized, :organize, :organized
          trans :organized, :present, :presenting
          trans :suspended, :organize, :organized

          superstate :presenting do
             event :suspend, :suspended

             trans :defocused, :focus, :focused_H
             trans :defocused, :next, :focused_H#, :focus_next
             trans :defocused, :prev, :focused_H#, :focus_prev
             trans :defocused, :parent, :focused_H#, :focus_parent

             superstate :focused do
               event :defocus, :defocused

               trans :deactivated, :activate, :activated
               trans :activated, :deactivate, :deactivated
             end
          end
         end
    end
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