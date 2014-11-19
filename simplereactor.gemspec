# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simplereactor"

Gem::Specification.new do |s|
  s.name        = "simplereactor"
  s.version     = SimpleReactor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kirk Haines"]
  s.email       = ["khaines@engineyard.com"]
  s.homepage    = ""
  s.summary     = %q{Simplereactor is a very simple, pure Ruby event based IO reactor, with no external requirements. Use it when all you need is some simple, no frills event based IO.}
  s.description = s.summary

  s.rubyforge_project = "simplereactor"

  s.files         = `git ls-files |`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
