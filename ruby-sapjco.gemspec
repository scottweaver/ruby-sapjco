# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ruby-sapjco/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Scott T Weaver"]
  gem.email         = ["scott.t.weaver@gmail.com"]
  gem.description   = %q{A simple wrapper over the the top of the SAP JCO Java API}
  gem.summary       = %q{A simple wrapper over the the top of the SAP JCO Java API}
  gem.homepage      = "https://github.com/scottweaver/ruby-sapjco"

  gem.requirements  << %q{You must have SAPJCo 3.0.x properly configured on your system.  This means
    having the libsapjco3.so in your system's library path.  You will also need to make sure the sapjco3.jar
    is availble from the JVM that starts JRuby.}

  gem.add_dependency 'haml' 
  gem.add_dependency 'launchy'
  gem.add_dependency 'logging-facade'
  

  gem.add_development_dependency('rspec')
  # gem.add_development_dependency('guard-rspec')
  # gem.add_development_dependency('rb-inotify')
  # gem.add_development_dependency('libnotify')
  gem.add_development_dependency('haml')
  gem.add_development_dependency('launchy')
  gem.add_development_dependency('simplecov')
  
  


  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ruby-sapjco"
  gem.require_paths = ["lib"]
  gem.version       = Ruby::Sapjco::VERSION
end
