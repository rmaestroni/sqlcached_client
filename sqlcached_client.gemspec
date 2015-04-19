# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sqlcached_client/version'

Gem::Specification.new do |spec|
  spec.name          = "sqlcached_client"
  spec.version       = SqlcachedClient::VERSION
  spec.authors       = ["Roberto Maestroni"]
  spec.email         = ["r.maestroni@gmail.com"]
  spec.summary       = %q{A Ruby client for sqlcached}
  spec.description   = %q{A Ruby client for sqlcached}
  spec.homepage      = "https://github.com/rmaestroni/sqlcached_client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 4.2"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
