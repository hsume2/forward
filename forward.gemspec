# -*- encoding: utf-8 -*-
require File.expand_path('../lib/forward/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['blahed']
  gem.email         = ['travis@50east.co']
  gem.summary       = 'Forward Lets You Share localhost over the Web. Demo a Website Without Hosting.'
  gem.homepage      = 'https://forwardhq.com'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|features)/})
  gem.name          = 'forward'
  gem.require_paths = ['lib']
  gem.version       = Forward::VERSION

  gem.add_dependency 'json', '~> 1.4.6'
  gem.add_dependency 'highline', '~> 1.6.13'
  gem.add_dependency 'net-ssh', '~> 2.4.0'

  gem.add_development_dependency 'minitest', '~> 3.0.0'
  gem.add_development_dependency 'mocha', '~> 0.11.4'
  gem.add_development_dependency 'fakeweb', '~> 1.3.0'
  gem.add_development_dependency 'fakefs', '~> 0.4.0'
end
