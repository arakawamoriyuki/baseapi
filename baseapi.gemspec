# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baseapi/version'

Gem::Specification.new do |spec|
  spec.name          = "baseapi"
  spec.version       = Baseapi::VERSION
  spec.authors       = ["Moriyuki Arakawa"]
  spec.email         = ["fire_extinguisher-@ezweb.ne.jp"]

  spec.summary       = %q{ruby on rails gem baseapi}
  spec.description   = %q{ruby on rails gem baseapi}
  spec.homepage      = "https://github.com/arakawamoriyuki/baseapi"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency 'thor'
end
