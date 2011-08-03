require File.dirname(__FILE__) + '/../../spec_helper'

describe "AIMultiChoiceElement" do
  before (:each) do
    @statemachine = Statemachine.build do
      superstate :AIMultiChoiceElement do
        trans :initialized, :organize, :organized
        trans :organized, :present, :presenting_H
        trans :suspended, :organize, :organized

        superstate :presenting do
          event :suspend, :suspended
          parallel :p do
            statemachine :s1 do
              superstate :selection do
                # TODO make In() work
                trans :unchosen, :choose, :chosen#, nil, In(:focused)
                trans :chosen, :unchoose, :unchosen
              end
            end
            statemachine :s2 do
              superstate :presentingAIChoiceElement do
                event :suspend, :suspended

                trans :defocused, :focus, :focused
                trans :defocused, :next, :focused, :focus_next
                trans :defocused, :prev, :focused, :focus_prev
                trans :defocused, :parent, :focused, :focus_parent
                trans :focused, :defocus, :defocused
                #would the implementation of "if" be like this?
                # TODO make In() work
                trans :focused, :drag, :dragging#, :self_choose, In(:unchosen)
                trans :focused, :drag, :dragging#, nil, In(:chosen)
                trans :dragging, :drop, :defocused
              end
            end
          end
        end
      end
   end
  end

  it "should enter :presenting" do
    @statemachine.organize
    @statemachine.present
    @statemachine.states_id.should == [:unchosen, :defocused]
  end

    it "should support parallel transitions" do
    @statemachine.organize
    @statemachine.present
    @statemachine.focus
    @statemachine.choose
    @statemachine.states_id.should == [:chosen, :focused]
  end

  it "should leave :presenting and return to the proper states" do
    @statemachine.organize
    @statemachine.present
    @statemachine.focus
    @statemachine.choose
    @statemachine.states_id.should == [:chosen, :focused]
    @statemachine.suspend
    @statemachine.state.should == :suspended
    @statemachine.organize
    @statemachine.present
  end

  #TODO implement test to check if In() is working
end