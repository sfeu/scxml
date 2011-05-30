require 'rubygems'
require 'statemachine'

# This code is only used in parallel with others
module MINT
   class AIChoiceElement
     def initialize_statemachine
       if @statemachine.blank?
         @statemachine = Statemachine.build do
            superstate :AIChoiceElement do
              trans :initialized, :organize, :organized
              trans :organized, :present, :presenting
              trans :suspended, :organize, :organized

              superstate :presenting do
                event :suspend, :suspended

                trans :defocused, :focus, :focused
                trans :defocused, :next, :focused, :focus_next
                trans :defocused, :prev, :focused, :focus_prev
                trans :defocused, :parent, :focused, :focus_parent
                trans :focused, :defocus, :defocused
                trans :focused, :drag, :dragging, :self_choose, In(:unchosen)
                trans :focused, :drag, :dragging, nil, In(:chosen)
                trans :dragging, :drop, :defocused
              end
            end
         end
       end
     end
   end
end