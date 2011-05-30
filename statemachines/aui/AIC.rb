require 'rubygems'
require 'statemachine'

module MINT
   class AIC < AIO
     def initialize_statemachine
       if @statemachine.blank?
         @statemachine = Statemachine.build do
            superstate :AIC do
              trans :initialized, :organize, :organized
              trans :organized, :present, :presenting
              trans :suspended, :organize, :organized

              superstate :presenting do
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