# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "MINT-scxml"
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jessica H. Colnago, Sebastian Feuerstack"]
  s.date = "2012-11-20"
  s.description = "This gem implements a state chart XML (SCXML) parser that generates a ruby statemachine."
  s.email = "Sebastian@Feuerstack.org"
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["Gemfile", "Gemfile.lock", "History.txt", "MINT-scxml.gemspec", "Manifest.txt", "README.rdoc", "Rakefile", "lib/MINT-scxml.rb", "lib/MINT-scxml/scxml-parser.rb", "spec/atm_spec.rb", "spec/if_spec.rb", "spec/parser_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "spec/test_handgestures_spec.rb", "spec/testmachines/atm_enhanced.rb", "spec/testmachines/button.scxml", "spec/testmachines/handgestures-scxmlgui.png", "spec/testmachines/handgestures-scxmlgui.scxml", "spec/testmachines/multiplestates.rb", "spec/testmachines/traffic_light_enhanced.rb", "spec/testmachines/vending_machine1.rb", "spec/testmachines/vending_machine2.rb", "spec/testmachines/vending_machine3.rb", "spec/testmachines/vending_machine4.rb", "spec_helper.rb", "statemachines/AICommand_scxml_spec.rb", "statemachines/AIO_scxml_spec.rb", "statemachines/specs/AICommand_spec.rb", "statemachines/specs/AIINContinous_spec.rb", "statemachines/specs/AIMultiChoiceElement_spec.rb", "statemachines/specs/AIMultiChoice_spec.rb", "statemachines/specs/AIOUTContinous_spec.rb", "statemachines/specs/AIO_spec.rb", "statemachines/specs/AISingleChoiceElement_spec.rb", "statemachines/specs/AISingleChoice_spec.rb", ".gemtest"]
  s.homepage = "http://www.multi-access.de"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "MINT-scxml"
  s.rubygems_version = "1.8.15"
  s.summary = "This gem implements a state chart XML (SCXML) parser that generates a ruby statemachine."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<MINT-statemachine>, ["~> 1.3.0"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<newgem>, [">= 1.5.3"])
      s.add_development_dependency(%q<hoe>, ["~> 3.1"])
    else
      s.add_dependency(%q<MINT-statemachine>, ["~> 1.3.0"])
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<newgem>, [">= 1.5.3"])
      s.add_dependency(%q<hoe>, ["~> 3.1"])
    end
  else
    s.add_dependency(%q<MINT-statemachine>, ["~> 1.3.0"])
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<newgem>, [">= 1.5.3"])
    s.add_dependency(%q<hoe>, ["~> 3.1"])
  end
end
