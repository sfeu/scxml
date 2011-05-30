require 'rubygems'
require 'statemachine'

module MINT
   class AIOUTContinous
     def initialize_statemachine
       if @statemachine.blank?
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
     end
   end
end