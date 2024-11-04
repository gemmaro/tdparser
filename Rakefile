# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, "../lib")

require 'rake/testtask'
require 'rdoc/task'

Rake::TestTask.new do |t|
  t.test_files = FileList["test/test_*.rb"]
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include("lib/**/*.rb")
end
