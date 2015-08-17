# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_log_deinterleaver/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_log_deinterleaver"
  spec.version       = RailsLogDeinterleaver::VERSION
  spec.authors       = ["Matt Fawcett"]
  spec.email         = ["fawcett@viddler.com"]

  spec.summary       = "Convert interleaved rails logs into a more readable format"
  spec.description   = %q(Multiple rails instances writing to the same log cause entries to be interleaved,
                          making them hard to ready. This command line script groups them by request, using the pid. )
  spec.homepage      = "https://github.com/mattfawcett/rails_log_deinterleaver"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = "rails_log_deinterleaver"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.7"

  spec.add_dependency "file-tail", "~> 1.1"
  spec.add_dependency "trollop", "~> 2.1"
end
