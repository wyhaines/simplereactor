# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simplereactor/version'

Gem::Specification.new do |spec|
  spec.name          = "simplereactor"
  spec.version       = SimpleReactor::VERSION
  spec.authors       = ["Kirk Haines"]
  spec.email         = ["wyhaines@gmail.com"]

  spec.summary       = %q{Simple Reactor}
  spec.description   = %q{Simple Reactor}
  spec.homepage      = "http://github.com/wyhaines/simplereactor"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
