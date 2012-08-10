# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ruby-sapjco"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Scott T Weaver"]
  s.date = "2012-08-10"
  s.description = "A simple wrapper over the the top of the SAP JCO Java API."
  s.email = "scott.t.weaver@gmail.com"
  s.extra_rdoc_files = ["README.md", "lib/sapjco.rb"]
  s.files = ["Gemfile", "Gemfile.lock", "Guardfile", "Manifest", "README.md", "Rakefile", "config.yml.example", "lib/sapjco.rb", "ruby-sapjco.gemspec", "spec/sapjco/sapjco_spec.rb", "spec/spec_helper.rb", "stderr.echoe", "stdout.echoe"]
  s.homepage = "https://github.com/scottweaver/ruby-sapjco"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Ruby-sapjco", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "ruby-sapjco"
  s.rubygems_version = "1.8.24"
  s.summary = "A simple wrapper over the the top of the SAP JCO Java API."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
