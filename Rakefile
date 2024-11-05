# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, "../lib")

require 'rake/testtask'
require 'rdoc/task'

Rake::TestTask.new do |t|
  t.libs << "samples" << "test"
  t.test_files = FileList["test/*_test.rb"]
  t.verbose = true
end

RDoc::Task.new do |rdoc|
  guide = "doc/guide.rdoc"
  rdoc.main = guide
  rdoc.rdoc_files.include("lib/**/*.rb", "doc/faq.rdoc", guide)
end
