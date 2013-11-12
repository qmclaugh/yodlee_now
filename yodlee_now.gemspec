# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yodlee_now/version'

Gem::Specification.new do |gem|
  gem.name          = "yodlee_now"
  gem.version       = YodleeNow::VERSION
  gem.authors       = ["Quinn McLaughlin"]
  gem.email         = ["quinn@coincidence.net"]
  gem.description   = %q{'A simple gem to quickly get high level access to Yodlee's aggregated financial data.'}
  gem.summary       = %q{'Access the Yodlee REST API easily.''}
  gem.homepage      = "http://github.com/qmclaugh/yodlee_now"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency 'net-ssh'
  # gem.add_dependency 'open-uri'
  # gem.add_dependency 'libv8', '~> 3.16.14.0'

end
