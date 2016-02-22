 # -*- encoding: utf-8 -*-
$:.push File.dirname(__FILE__) + '/lib'
require 'acts_as_limitable/version'

Gem::Specification.new do |gem|
  gem.name = %q{acts_as_limitable}

  gem.required_rubygems_version = Gem::Requirement.new(">= 0") if gem.respond_to? :required_rubygems_version=
  gem.authors = ["Darren Hicks"]
  gem.description = %q{Gem that provides rate limiting functionality to rails applications}
  gem.email = %q{darren.hicks@gmail.com}
  gem.extra_rdoc_files = ["README.md", "LICENSE"]

  gem.date = %q{2016-02-15}
  gem.summary = "Rate limiting for Rails."

  gem.add_runtime_dependency 'rails'
  gem.add_runtime_dependency 'redis'
  
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'

  #gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  #gem.files         = `git ls-files`.split("\n")
  gem.files         = ["lib/acts_as_limitable.rb", "lib/acts_as_limitable/version.rb"]
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ['lib']
  gem.version       = ActsAsLimitable::VERSION
end