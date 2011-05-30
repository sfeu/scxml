require 'rubygems'
require 'statemachine'

module MINT
   class AIINContinous < AIIN
     def initialize_statemachine
       if @statemachine.blank?
         @statemachine = Statemachine.build do
            superstate :AIINContinous do
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

                  # TODO how to implement the sensitivity condition?
                  trans :waiting, :decrease, :decreasing#, nil, (x1<x0-sensitivy)
                  trans :waiting, :increase, :increasing#, nil, (x1>x0-sensitivy)
                  trans :increasing, :decrease, :decreasing#, nil, (x1<x0-sensitivy)
                  trans :decreasing, :increase, :increasing#, nil, (x1>x0-sensitivy)

                  # TODO how to implement transitions without events
                  #trans :decreasing, nil, :waiting, nil, (Dt>tmax)
                  #trans :increasing, nil, :waiting, nil, (Dt>tmax)
                end
              end
            end
         end
       end
     end
   end
end