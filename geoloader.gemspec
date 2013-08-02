# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'geoloader/version'

Gem::Specification.new do |spec|
  spec.name          = "geoloader"
  spec.version       = Geoloader::VERSION
  spec.authors       = ["Wayne Graham"]
  spec.email         = ["wayne.graham@virginia.edu"]
  spec.description   = %q{Automation for GIS infrastructure}
  spec.summary       = %q{Helper utilities for loading GIS datasets in to GIS infrastructure}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "gdal", "~>0.0.5"
  spec.add_dependency "nokogiri", "~> 1.6.0"
  spec.add_dependency "rest-client", "~> 1.6.7"
  spec.add_dependency "awesome_print", "~> 1.1.0"
  spec.add_dependency "curb", "~>0.8.4"
  spec.add_dependency "rgeoserver", "~>0.5.9"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~>2.13.0"

end
