# coding: utf-8
#lib = File.expand_path('../lib', __FILE__)
#$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "access_stack"
  s.version       = "0.1.0"
  s.authors       = ["Nathaniel Symer"]
  s.email         = ["nate@natesymer.com"]
  s.summary       = "Abstract object pooling for cool people."
  s.description   = "Abstract object pooling for cool people. See homepage."
  s.homepage      = "http://github.com/fhsjaagshs/access_stack"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.6"
  s.add_development_dependency "rake", "~> 10"
	s.add_development_dependency "rspec", "~> 3.0", ">= 3.0.0"
  s.add_development_dependency "threadsafety", "~> 0"
end
