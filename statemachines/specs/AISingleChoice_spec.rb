require File.dirname(__FILE__) + '/../../spec_helper'

describe "AISingleChoice" do
  before (:each) do
    @statemachine = Statemachine.build do
      superstate :AISingleChoice do
        trans :initialized, :organize, :organized
        trans :organized, :present, :presenting
        trans :suspended, :organize, :organized

        superstate :presenting do
          event :suspend, :suspended

          parallel :p do
            statemachine :s1 do
              #trans :listing, :drop, :dropped, :drop_all_dragging, In(:focused)
              # TODO make In() work
              trans :listing, :drop, :dropped, nil, Proc.new {@statemachine.In(:focused)}
              # TODO how to implement transitions without events
              # trans :dropped, nil , :listing, :unfocus_self
            end
            statemachine :s2 do
              superstate :presentingAIC do
                event :suspend, :suspended

                trans :defocused, :focus, :focused
                trans :defocused, :next, :focused#, :focus_next
                trans :defocused, :prev, :focused#, :focus_prev
                trans :defocused, :parent, :focused#, :focus_parent
                trans :defocused, :child, :focused#, :focus_child
                trans :focused, :defocus, :defocused
              end
            end
          end
        end
      end
   end
  end

  it "should enter :presenting " do
    @statemachine.organize
    @statemachine.present
    @statemachine.states_id.should == [:listing, :defocused]
  end

  #TODO test to check In when it starts to work




  it "should support parallel transitions" do
    @statemachine.organize
    @statemachine.present
    @statemachine.drop
    @statemachine.states_id.should == [:listing, :defocused]
    @statemachine.focus
    @statemachine.drop
    @statemachine.states_id.should == [:dropped, :focused]
  end

  it "should leave :presenting and parallel state" do
    @statemachine.organize
    @statemachine.present
    @statemachine.suspend
    @statemachine.state.should == :suspended
  end

end