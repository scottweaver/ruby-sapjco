require 'rake'
require 'echoe'

Echoe.new('ruby-sapjco', '0.0.1') do |p|
  p.description    = "A simple wrapper over the the top of the SAP JCO Java API."
  p.url            = "https://github.com/scottweaver/ruby-sapjco"
  p.author         = "Scott T Weaver"
  p.email          = "scott.t.weaver@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*", "bin/*", "bin_stubs/*", "sapjco3.jar", "config.yml"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }