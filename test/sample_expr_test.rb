require "test_helper"
require "sample_expr"

class SampleExprTest < Test::Unit::TestCase
  test 'sample expr' do
    assert_equal 1, SampleExprParser.parse("1")
    assert_equal 11, SampleExprParser.parse("1+10")
    assert_equal 0, SampleExprParser.parse("2 - 1 * 20 + 18")
    assert_equal 21, SampleExprParser.parse("2 - (1 - 20)")
    assert_equal 0, SampleExprParser.parse("1 + 2 - 3")
  end
end
