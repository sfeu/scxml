# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{MINT-scxml}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Jessica H. Colnago, Sebastian Feuerstack}]
  s.date = %q{2011-11-01}
  s.description = %q{}
  s.email = %q{Sebastian@Feuerstack.org}
  s.extra_rdoc_files = [%q{History.txt}, %q{Manifest.txt}, %q{README.txt}]
  s.files = [%q{.autotest}, %q{.idea/workspace.xml}, %q{Gemfile}, %q{Gemfile.lock}, %q{History.txt}, %q{MINT-scxml.gemspec}, %q{Manifest.txt}, %q{README.rdoc}, %q{README.txt}, %q{Rakefile}, %q{lib/MINT-scxml.rb}, %q{lib/MINT-scxml/scxml-parser.rb}, %q{spec/atm_spec.rb}, %q{spec/parser_spec.rb}, %q{spec/spec.opts}, %q{spec/spec_helper.rb}, %q{spec/test_handgestures_spec.rb}, %q{spec/testmachines/atm_enhanced.rb}, %q{spec/testmachines/handgestures-scxmlgui.png}, %q{spec/testmachines/handgestures-scxmlgui.scxml}, %q{spec/testmachines/multiplestates.rb}, %q{spec/testmachines/traffic_light_enhanced.rb}, %q{spec/testmachines/vending_machine1.rb}, %q{spec/testmachines/vending_machine2.rb}, %q{spec/testmachines/vending_machine3.rb}, %q{spec/testmachines/vending_machine4.rb}, %q{spec_helper.rb}, %q{statemachines/AICommand_scxml_spec.rb}, %q{statemachines/AIO_scxml_spec.rb}, %q{statemachines/aui-scxml/AIC.scxml}, %q{statemachines/aui-scxml/AICommand.scxml}, %q{statemachines/aui-scxml/AICommand2.scxml}, %q{statemachines/aui-scxml/AIO.scxml}, %q{statemachines/aui/AIC.rb}, %q{statemachines/aui/AIChoiceElement.rb}, %q{statemachines/aui/AICommand.rb}, %q{statemachines/aui/AIIN.rb}, %q{statemachines/aui/AIINContinous.rb}, %q{statemachines/aui/AIMultiChoice.rb}, %q{statemachines/aui/AIMultiChoiceElement.rb}, %q{statemachines/aui/AIOUTContinous.rb}, %q{statemachines/aui/AISingleChoice.rb}, %q{statemachines/aui/AISingleChoiceElement.rb}, %q{statemachines/aui/aio.rb}, %q{statemachines/specs/AICommand_spec.rb}, %q{statemachines/specs/AIINContinous_spec.rb}, %q{statemachines/specs/AIMultiChoiceElement_spec.rb}, %q{statemachines/specs/AIMultiChoice_spec.rb}, %q{statemachines/specs/AIOUTContinous_spec.rb}, %q{statemachines/specs/AIO_spec.rb}, %q{statemachines/specs/AISingleChoiceElement_spec.rb}, %q{statemachines/specs/AISingleChoice_spec.rb}, %q{.gemtest}]
  s.homepage = %q{http://www.multi-access.de}
  s.rdoc_options = [%q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{MINT-scxml}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<MINT-statemachine>, ["~> 1.2.3"])
      s.add_development_dependency(%q<hoe>, ["~> 2.9"])
    else
      s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.3"])
      s.add_dependency(%q<hoe>, ["~> 2.9"])
    end
  else
    s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.3"])
    s.add_dependency(%q<hoe>, ["~> 2.9"])
  end
end
