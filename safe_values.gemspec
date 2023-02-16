
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'safe_values/version'

Gem::Specification.new do |spec|
  spec.name          = 'safe_values'
  spec.version       = SafeValues::VERSION
  spec.authors       = ['DMM Eikaiwa']
  spec.email         = ['dev@iknow.jp']

  spec.summary       = %q{Struct classes with safer constructors.}
  spec.homepage      = 'http://github.com/iknow/safe_values'
  spec.license       = 'MIT'

  spec.files         = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
end
