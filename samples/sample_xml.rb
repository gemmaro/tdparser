# frozen_string_literal: true

require 'tdparser'
require 'tdparser/utils'
require 'tdparser/xml'

translator = TDParser.define { |g|
  extend TDParser::XMLParser

  g.xml =
    (element("a") {
      element("b") {
        g.xmlseq
      } >> dom_constructor(&:children)
    } >> dom_constructor { |node| node.name = "AB"; node }) |
    (element(String) {
      g.xmlseq
    } >> dom_constructor { |node|
           node.name = node.name.upcase
           node
         }) |
    (doctype {
      g.xmlseq
    } >> dom_constructor { |node| node }) |
    (text >> proc { |x| x[0] }) |
    (elementdecl >> proc { |x| x[0] }) |
    (xmldecl >> proc { |x| x[0] }) |
    (comment >> proc { |x| x[0] }) |
    (any_node >> proc { |x| x[0] })

  g.xmlseq =
    ((g.xml * 0) >> proc { |x| x[0].collect { |y| y[0] } }) |

  def translate(src)
    gen = TDParser::XMLTokenGenerator.new(src)
    xmlseq.parse(gen)
  end
}

if ENV["TEST"]
  XMLTranslator = translator
  return
end

seq = translator.translate(<<EOS)
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
puts(doc)
