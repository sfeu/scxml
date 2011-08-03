require File.dirname(__FILE__) + '/../../spec_helper'

describe "AIMultiChoice" do
  before (:each) do
    @statemachine = Statemachine.build do
      superstate :AIMultiChoice do
        trans :initialized, :organize, :organized
        trans :organized, :present, :presenting
        trans :suspended, :organize, :organized

        superstate :presenting do
          event :suspend, :suspended
            parallel :p do
              statemachine :s1 do
                # TODO make In() work
                trans :listing, :drop, :dropped#, nil, In(:focused)#, :drop_all_dragging, In(:focused)
                trans :listing, :choose_all, :choosing
                trans :listing, :unchoose_all, :unchoosing
                # TODO how to implement transitions without events
                # trans :dropped, nil, :listing, :unfocus_self
                # trans :choosing, nil, :listing, :choose_all_childs
                # trans :unchoosing, nil, :listing, :unchoose_all_childs
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

  it "should support parallel transitions" do
    @statemachine.organize
    @statemachine.present
    @statemachine.states_id.should == [:listing, :defocused]
    @statemachine.choose_all
    @statemachine.focus
    @statemachine.states_id.should == [:choosing, :focused]
    @statemachine.defocus
    @statemachine.states_id.should == [:choosing, :defocused]
  end

  # TODO implement test to check if In() is working
  # TODO implement test for spontaneous transitions

end