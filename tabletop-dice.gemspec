# -*- encoding: utf-8 -*-
$: << './lib'
require 'dice/version'

Gem::Specification.new do |s|
  s.name = 'tabletop-dice'
  s.version = Dice::VERSION
  s.authors = ["Daniel Sheppard"]
  s.date = Time.now.strftime("YYYY-MM-DD")
  s.description = %q{Dice roller for http://onlinetabletop.appspot.com.}
  s.email = ["danshep@gmail.com"]
  s.executables = []
  s.extra_rdoc_files = ["README.txt"]
  s.files = Dir["lib/**/*"] + Dir["{*.txt,Rakefile}"]
  s.homepage = %q{http://onlinetabletop.appspot.com/}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{}
  s.test_files = Dir["spec/**/*_spec.rb"]
  #s.platform = "java"
  #s.add_dependency("bitescript", ">= 0.0.6")
end
