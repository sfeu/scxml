require 'rubygems'
require 'statemachine'

module MINT
   class AIMultiChoiceElement
     def initialize_statemachine
       if @statemachine.blank?
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
                      trans :unchosen, :choose, :chosen, nil, In(:focused)
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
     end
   end
end