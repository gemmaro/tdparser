require "test_helper"
require "sample_list"

class SampleListTest < Test::Unit::TestCase
  test "sample list" do
    list = "(a (b c d) (e f g))"
    r = parser.parse(list)
    assert_equal ["a", ["b", "c", "d"], ["e", "f", "g"]], r
  end
end
