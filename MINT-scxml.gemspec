# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{MINT-scxml}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jessica H. Colnago, Sebastian Feuerstack"]
  s.date = %q{2011-08-08}
  s.description = %q{}
  s.email = ["Sebastian@Feuerstack.org"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["Gemfile", "Gemfile.lock", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/MINT-scxml.rb", "lib/MINT-scxml/scxml-parser.rb", "spec/atm_spec.rb", "spec/parser_spec.rb", "spec/spec_helper.rb", "spec/test_handgestures_spec.rb", "spec/testmachines/atm_enhanced.rb", "spec/testmachines/handgestures-scxmlgui.png", "spec/testmachines/handgestures-scxmlgui.scxml", "spec/testmachines/multiplestates.rb", "spec/testmachines/traffic_light_enhanced.rb", "spec/testmachines/vending_machine1.rb", "spec/testmachines/vending_machine2.rb", "spec/testmachines/vending_machine3.rb", "spec/testmachines/vending_machine4.rb", "spec_helper.rb", "statemachines/AICommand_scxml_spec.rb", "statemachines/AIO_scxml_spec.rb", "statemachines/aui-scxml/AIC.scxml", "statemachines/aui-scxml/AICommand.scxml", "statemachines/aui-scxml/AICommand2.scxml", "statemachines/aui-scxml/AIO.scxml", "statemachines/aui/AIC.rb", "statemachines/aui/AIChoiceElement.rb", "statemachines/aui/AICommand.rb", "statemachines/aui/AIIN.rb", "statemachines/aui/AIINContinous.rb", "statemachines/aui/AIMultiChoice.rb", "statemachines/aui/AIMultiChoiceElement.rb", "statemachines/aui/AIOUTContinous.rb", "statemachines/aui/AISingleChoice.rb", "statemachines/aui/AISingleChoiceElement.rb", "statemachines/aui/aio.rb", "statemachines/specs/AICommand_spec.rb", "statemachines/specs/AIINContinous_spec.rb", "statemachines/specs/AIMultiChoiceElement_spec.rb", "statemachines/specs/AIMultiChoice_spec.rb", "statemachines/specs/AIOUTContinous_spec.rb", "statemachines/specs/AIO_spec.rb", "statemachines/specs/AISingleChoiceElement_spec.rb", "statemachines/specs/AISingleChoice_spec.rb"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{MINT-scxml}
  s.rubygems_version = %q{1.5.2}
  s.summary = nil

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<MINT-statemachine>, ["~> 1.2.2"])
      s.add_development_dependency(%q<hoe>, ["~> 2.9"])
    else
      s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.2"])
      s.add_dependency(%q<hoe>, ["~> 2.9"])
    end
  else
    s.add_dependency(%q<MINT-statemachine>, ["~> 1.2.2"])
    s.add_dependency(%q<hoe>, ["~> 2.9"])
  end
end
