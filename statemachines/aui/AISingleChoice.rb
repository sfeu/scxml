require 'rubygems'
require 'statemachine'

module MINT
   class AISingleChoice
     def initialize_statemachine
       if @statemachine.blank?
         @statemachine = Statemachine.build do
            superstate :AISingleChoice do
              trans :initialized, :organize, :organized
              trans :organized, :present, :presenting
              trans :suspended, :organize, :organized

              superstate :presenting do
                event :suspend, :suspended

                parallel :p do
                  statemachine :s1 do
                    trans :listing, :drop, :dropped, :drop_all_dragging, In(:focused)
                    # TODO how to implement transitions without events
                    # trans :dropped, nil , :listing, :unfocus_self
                  end
                  statemachine :s2 do
                    superstate :presentingAIC do
                      event :suspend, :suspended

                      trans :defocused, :focus, :focused
                      trans :defocused, :next, :focused, :focus_next
                      trans :defocused, :prev, :focused, :focus_prev
                      trans :defocused, :parent, :focused, :focus_parent
                      trans :defocused, :child, :focused, :focus_child
                      trans :focused, :defocus, :defocused
                    end
                  end
                end
              end
            end
         end
       end
     end
   end
end