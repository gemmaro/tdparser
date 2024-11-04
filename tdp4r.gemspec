require 'rubygems'
spec = Gem::Specification.new{|s|
  s.name = 'tdp4r'
  s.version = '1.4.1'
  s.summary = 'TDP4R is a top-down parser library that consists of parser combinators and utility functions.'
  s.author = 'Takaaki Tateishi'
  s.email  = 'ttate@ttsky.net'
  s.homepage = 'http://rubyforge.org/projects/tdp4r/'
  s.rubyforge_project = 'tdp4r'
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,samples,test,doc}/**/*").delete_if{|item|
    item.include?("CVS") ||
    item.include?("rdoc") ||
    false
  }
  s.test_files = ['test/test_tdp.rb']
  s.require_path = 'lib'
  s.autorequire = 'tdp'
}
if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec).build()
end
