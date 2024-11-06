# frozen_string_literal: true

require_relative 'lib/tdparser/version'

Gem::Specification.new do |spec|
  spec.name = 'tdparser'
  spec.version = TDParser::VERSION
  spec.authors = ['Takaaki Tateishi']
  spec.email = ['ttate@jaist.ac.jp']

  spec.summary = 'Top down parser library'
  spec.description = 'TDParser (formerly TDP4R) is a parser combinator library in Ruby, which helps us to construct a top down parser using method calls.'
  spec.required_ruby_version = '>= 3.1'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(['git', 'ls-files', '-z'], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?('bin/', 'test/', 'spec/', 'features/', '.git', 'appveyor', 'Gemfile')
    end
  end

  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
end
