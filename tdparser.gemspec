# frozen_string_literal: true

require_relative 'lib/tdparser/version'

Gem::Specification.new do |spec|
  spec.name                  = name = 'tdparser'
  spec.version               = TDParser::VERSION
  spec.authors               = ['Takaaki Tateishi', 'gemmaro']
  spec.email                 = ['ttate@ttsky.net', 'gemmaro.dev@gmail.com']

  spec.summary               = 'Top down parser library'
  spec.description           = 'TDParser (formerly TDP4R) is a top-down parser library that consists of parser combinators and utility functions.'
  spec.license               = 'BSD-3-Clause'
  spec.required_ruby_version = '>= 3.1'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.homepage = homepage = "https://git.disroot.org/gemmaro/#{name}"
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'bug_tracker_uri'       => "#{homepage}/issues",
    'changelog_uri'         => "#{homepage}/src/branch/main/CHANGELOG.md",
    'documentation_uri'     => "https://gemmaro.github.io/#{name}",
    'homepage_uri'          => homepage,
    'source_code_uri'       => homepage,
    'wiki_uri'              => "#{homepage}/wiki",
  }

  spec.require_paths = ['lib']
end
