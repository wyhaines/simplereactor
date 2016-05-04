# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simplereactor/version'

Gem::Specification.new do |spec|
  spec.name          = "simplereactor"
  spec.version       = SimpleReactor::VERSION
  spec.authors       = ["Kirk Haines"]
  spec.email         = ["wyhaines@gmail.com"]

  spec.summary       = %q{Pure Ruby event reactor.}
  spec.description   = %q{Pretty minimalistic implememntation of an event reactor, in pure Ruby, but it's still fast enough to be useful.}
  spec.homepage      = "http://github.com/wyhaines/simplereactor"
  spec.license       = "MIT"

  # Pr:event pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
