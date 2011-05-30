require 'rubygems'
require 'statemachine'

module MINT
   class AICommand < AIO
     def initialize_statemachine
       if @statemachine.blank?
         @statemachine = Statemachine.build do
            superstate :AICommand do
              trans :initialized, :organize, :organized
              trans :organized, :present, :presenting
              trans :suspended, :organize, :organized

              superstate :presenting do
                event :suspend, :suspended

                trans :defocused, :focus, :focused_H
                trans :defocused, :next, :focused_H, :focus_next
                trans :defocused, :prev, :focused_H, :focus_prev
                trans :defocused, :parent, :focused_H, :focus_parent

                superstate :focused do
                  event :defocus, :defocused

                  trans :deactivated, :activate, :activated
                  trans :activated, :deactivate, :deactivated
                end
              end
            end
         end
       end
     end
   end
end