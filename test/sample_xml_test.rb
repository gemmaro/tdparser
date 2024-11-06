require 'test_helper'
require 'sample_xml'

class SampleXMLTest < Test::Unit::TestCase
  test 'sample XML' do
    seq = XMLTranslator.translate(<<~EOS)
      <?xml version="1.0" ?>
      <!DOCTYPE body [
       <!ELEMENT body (#PCDATA, strong*)>
       <!ELEMENT strong (#PCDATA)>
       ]>
      <list>
        <!-- comment -->
        <a><b><c>hoge</c></b></a>
        <b>b?</b>
      </list>
    EOS
    doc = REXML::Document.new
    seq.each { |x| doc.add(x) }
    assert_equal <<~EOS, doc.to_s
      <?xml version='1.0'?>
      <!DOCTYPE body [
      <!ELEMENT body (#PCDATA, strong*)>
      <!ELEMENT strong (#PCDATA)>
      ]>
      <LIST>
       <!-- comment -->
       <AB><C>hoge</C></AB>
       <B>b?</B>
      </LIST>
    EOS
  end
end
