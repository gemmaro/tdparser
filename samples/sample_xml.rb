# frozen_string_literal: true

require 'tdparser'
require 'tdparser/utils'
require 'tdparser/xml'

translator = TDParser.define do |g|
  extend TDParser::XMLParser

  g.xml =
    (element('a') do
      element('b') do
        g.xmlseq
      end >> dom_constructor(&:children)
    end >> dom_constructor do |node|
             node.name = 'AB'
             node
           end) |
    (element(String) do
      g.xmlseq
    end >> dom_constructor do |node|
             node.name = node.name.upcase
             node
           end) |
    (doctype do
      g.xmlseq
    end >> dom_constructor { |node| node }) |
    (text >> proc { |x| x[0] }) |
    (elementdecl >> proc { |x| x[0] }) |
    (xmldecl >> proc { |x| x[0] }) |
    (comment >> proc { |x| x[0] }) |
    (any_node >> proc { |x| x[0] })

  g.xmlseq =
    ((g.xml * 0) >> proc { |x| x[0].collect { |y| y[0] } }) |
    def translate(src)
      gen = TDParser::XMLParser::XMLTokenGenerator.new(src)
      xmlseq.parse(gen)
    end
end

if ENV['TEST']
  XMLTranslator = translator
  return
end

seq = translator.translate(<<~EOS)
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
