require File.dirname(__FILE__) + '/../../spec_helper'

describe "AISingleChoiceElement" do
  before (:each) do
    @statemachine = Statemachine.build do
      superstate :AISingleChoiceElement do
        trans :initialized, :organize, :organized
        trans :organized, :present, :presenting_H
        trans :suspended, :organize, :organized

        superstate :presenting do
          event :suspend, :suspended

          parallel :p do
            statemachine :s1 do
              superstate :selection do
                # TODO make In() work
                trans :unchosen, :choose, :chosen#, :all_unchoose, In(:focused)
                trans :chosen, :unchoose, :unchosen
              end
            end
            statemachine :s2 do
              superstate :presentingAIChoiceElement do
                event :suspend, :suspended

                trans :defocused, :focus, :focused
                trans :defocused, :next, :focused#, :focus_next
                trans :defocused, :prev, :focused#, :focus_prev
                trans :defocused, :parent, :focused#, :focus_parent
                trans :focused, :defocus, :defocused
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

  it "should support parallel transitions" do
    @statemachine.organize
    @statemachine.present
    @statemachine.focus
    @statemachine.choose
    @statemachine.states_id.should == [:chosen, :focused]
    @statemachine.drag
    @statemachine.states_id.should == [:chosen, :dragging]
    @statemachine.unchoose
    @statemachine.drop
    @statemachine.states_id.should == [:unchosen, :defocused]
  end

  #TODO implement test to check if In() is working

end