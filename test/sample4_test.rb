require "test_helper"
require "sample4"

class Sample4Test < Test::Unit::TestCase
  test "sample 4" do
    parser = Sample4Parser.new
    assert_equal 11, parser.parse("1+10")
    assert_equal 0, parser.parse("2 - 1 * 20 + 18")
    assert_equal 21, parser.parse("2 - (1 - 20)")
    assert_equal 0, parser.parse("1 + 2 - 3")
  end
end
