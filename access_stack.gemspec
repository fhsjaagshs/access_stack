# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'access_stack/version'

Gem::Specification.new do |spec|
  spec.name          = "access_stack"
  spec.version       = AccessStack::VERSION
  spec.authors       = ["Nathaniel Symer"]
  spec.email         = ["nate@natesymer.com"]
  spec.summary       = %q{Abstract object pooling for cool people.}
  spec.description   = %q{Abstract object pooling for cool people. See homepage}
  spec.homepage      = "http://github.com/fhsjaagshs/access_stack"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
	spec.add_development_dependency 'rspec', "~> 3.0.0"
end
