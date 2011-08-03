require File.dirname(__FILE__) + '/../../spec_helper'

describe "AIINContinous" do
  before (:each) do
    @statemachine = Statemachine.build do
      superstate :AIOUTContinous do
        trans :initialized, :organize, :organized
        trans :organized, :present, :presenting
        trans :suspended, :organize, :organized

        superstate :presenting do
          event :suspend, :suspended

          trans :defocused, :focus, :focused
          trans :defocused, :next, :focused, :focus_next
          trans :defocused, :prev, :focused, :focus_prev
          trans :defocused, :parent, :focused, :focus_parent

          superstate :focused do
            event :defocus, :defocused

            trans :waiting, :progress, :progressing
            trans :waiting, :regress, :regressing

            superstate :moving do
              event :halt, :waiting

              trans :progressing, :regress, :regressing
              trans :regressing, :progress, :progressing
            end
          end
        end
      end
   end
  end


  it "should enter the nested superstate :focused" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.state.should == :waiting
  end

  it "should support transitions inside :focused" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.progress
      @statemachine.state.should == :progressing
  end

  it "should support transitions inside :moving" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.progress
      @statemachine.state.should == :progressing
      @statemachine.regress
      @statemachine.state.should == :regressing
  end

  it "should leave :moving" do
      @statemachine.organize
      @statemachine.present
      @statemachine.focus
      @statemachine.progress
      @statemachine.halt
      @statemachine.state.should == :waiting
   end
end