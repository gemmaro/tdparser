require "test_helper"
require "sample5"

class Sample5Test < Test::Unit::TestCase
  test "sample 5" do
    assert_equal 11, Sample5Parser.parse("1+10")
    assert_equal 0, Sample5Parser.parse("2 - 1 * 20 + 18")
    assert_equal 21, Sample5Parser.parse("2 - (1 - 20)")
    assert_equal 0, Sample5Parser.parse("1 + 2 - 3")
  end
end
