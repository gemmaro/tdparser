require 'test_helper'
require 'sample2'

class Sample2Test < Test::Unit::TestCase
  test 'sample 2' do
    parser = Sample2Parser.new
    assert_equal 11, parser.parse('1+10')
    assert_equal 0, parser.parse('2 - 1 * 20 + 18')
    assert_equal 21, parser.parse('2 - (1 - 20)')
    assert_equal 0, parser.parse('1 + 2 - 3')
  end
end
