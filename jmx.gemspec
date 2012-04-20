# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jmx/version"

Gem::Specification.new do |s|
  s.name        = 'jmx'
  s.version     = JMX::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Thomas E. Enebo'
  s.email       = 'tom.enebo@gmail.com'
  s.homepage    = 'http://github.com/enebo/jmx'
  s.summary     = %q{Access and create MBeans in a friendly Ruby syntax}
  s.description = %q{Access and create MBeans in a friendly Ruby syntax}

  s.rubyforge_project = "jmx"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.has_rdoc      = true
end
