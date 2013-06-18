# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gargor/version'

Gem::Specification.new do |spec|
  spec.name          = "gargor"
  spec.version       = Gargor::VERSION
  spec.authors       = ["Yoshihiro TAKAHARA"]
  spec.email         = ["y.takahara@gmail.com"]
  spec.description   = %q{An auto-tuning tool for internet servers w/ Genetic Algorithm and Chef. You can get good settings during sleeping ;) }
  spec.summary       = %q{It is software which uses generic algorithm to support parameter tuning of the servers controlled by Chef.}
  spec.homepage      = "https://github.com/tumf/gargor"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
