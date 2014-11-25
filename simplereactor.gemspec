# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simplereactor"

Gem::Specification.new do |s|
  s.name        = SimpleReactor::NAME
  s.version     = SimpleReactor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = SimpleReactor::AUTHORS
  s.email       = SimpleReactor::EMAIL
  s.homepage    = SimpleReactor::HOMEPAGE
  s.summary     = SimpleReactor::SUMMARY
  s.description = s.summary # Lame; put something more thorough here.

  s.files         = `git ls-files |`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
