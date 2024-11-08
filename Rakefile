$LOAD_PATH << File.join(__dir__, "../lib")

require 'rdoc/task'
require 'rake/testtask'

RDoc::Task.new do |rdoc|
  readme = "README"
  rdoc.main = readme
  rdoc.rdoc_files.include("lib/**/*.rb", readme, "doc/*.rdoc")
end

Rake::TestTask.new do |t|
  t.test_files = FileList["test/test_*.rb"]
end
