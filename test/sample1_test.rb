# frozen_string_literal: true
require "test_helper"
require "sample1"

class Sample1Test < Test::Unit::TestCase
  test 'my parser' do
    parser = MyParser.new
    assert_equal 11, parser.parse("1+10")
    assert_equal(-19, parser.parse("2 - 1 - 20"))
    assert_equal 0, parser.parse("1 + 2 - 3")
  end
end
