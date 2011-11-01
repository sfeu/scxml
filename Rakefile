# -*- ruby -*-

require 'rubygems'
require 'hoe'

# Hoe.plugin :compiler
# Hoe.plugin :cucumberfeatures
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :manifest
Hoe.plugin :newgem
# Hoe.plugin :racc
# Hoe.plugin :rubyforge
# Hoe.plugin :website

Hoe.spec 'MINT-scxml' do
  self.developer 'Jessica H. Colnago, Sebastian Feuerstack', 'Sebastian@Feuerstack.org'
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [['MINT-statemachine','~> 1.2.3']]
  self.email = "Sebastian@Feuerstack.org"

  # HEY! If you fill these out in ~/.hoe_template/Rakefile.erb then
  # you'll never have to touch them again!
  # (delete this comment too, of course)

  # developer('FIX', 'FIX@example.com')

  # self.rubyforge_name = 'scxml-gemx' # if different than 'scxml-gem'
end

# vim: syntax=ruby
