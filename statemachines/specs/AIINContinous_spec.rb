require File.dirname(__FILE__) + '/../../spec_helper'

describe "AIINContinous" do
  before (:each) do
    @statemachine = Statemachine.build do
      superstate :AIINContinous do
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

            # TODO how to implement the sensitivity condition?
            trans :waiting, :decrease, :decreasing#, nil, (x1<x0-sensitivy)
            trans :waiting, :increase, :increasing#, nil, (x1>x0-sensitivy)
            trans :increasing, :decrease, :decreasing#, nil, (x1<x0-sensitivy)
            trans :decreasing, :increase, :increasing#, nil, (x1>x0-sensitivy)

            # TODO how to implement transitions without events
            #trans :decreasing, nil, :waiting, nil, (Dt>tmax)
            #trans :increasing, nil, :waiting, nil, (Dt>tmax)
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
      @statemachine.increase
      @statemachine.state.should == :increasing
      @statemachine.decrease
      @statemachine.state.should == :decreasing
  end

  #TODO implement test for spontaneous transitions
=begin
  it "should support spontaneous transitions" do
  end
=end

end