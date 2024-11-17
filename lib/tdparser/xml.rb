# frozen_string_literal: true

require 'tdparser'
require 'rexml/parsers/pullparser'
require 'rexml/document'

module TDParser
  class XMLTokenGenerator < TDParser::TokenGenerator
    def initialize(src)
      @xparser = REXML::Parsers::BaseParser.new(src)
      super()  do |g|
        while @xparser.has_next?
          e = @xparser.pull
          g.yield(e)
        end
      end
    end
  end

  module XMLParser
    XMLTokenGenerator = ::TDParser::XMLTokenGenerator # TODO: Delete in later version

    class XArray < Array # :nodoc:
      def ===(ary)
        return true if super(ary)
        return false unless ary.is_a?(Array)

        each_with_index do |v, idx|
          case ary[idx]
          when v
          else
            return false
          end
        end
        true
      end
    end

    class XHash < Hash # :nodoc:
      def ===(h)
        return true if super(h)
        return false unless h.is_a?(Hash)

        each do |k, v|
          case h[k]
          when v
          else
            return false
          end
        end
        true
      end
    end

    def start_element(name = String)
      token(XArray[:start_element, name, Hash])
    end

    def end_element(name = String)
      token(XArray[:end_element, name])
    end

    def element(elem = String, &inner)
      crule = if inner
                inner.call | empty
              else
                empty
              end
      (start_element(elem) - crule - end_element(elem)) >> proc do |x|
        name = x[0][1]
        attrs = x[0][2]
        node = REXML::Element.new
        node.name = name
        node.attributes.merge!(attrs)
        [node, x[1]]
      end
    end

    def text(match = String)
      token(XArray[:text, match]) >> proc do |x|
        REXML::Text.new(x[0][1])
      end
    end

    def pi
      token(XArray[:processing_instruction, String, String]) >> proc do |x|
        REXML::Instruction.new(x[0][1], x[0][2])
      end
    end

    def cdata(match = String)
      token(XArray[:cdata, match]) >> proc do |x|
        REXML::CData.new(x[0][1])
      end
    end

    def comment(match = String)
      token(XArray[:comment, match]) >> proc do |x|
        REXML::Comment.new(x[0][1])
      end
    end

    def xmldecl
      token(XArray[:xmldecl]) >> proc do |x|
        REXML::XMLDecl.new(x[0][1], x[0][2], x[0][3])
      end
    end

    def start_doctype(name = String)
      token(XArray[:start_doctype, name])
    end

    def end_doctype
      token(XArray[:end_doctype])
    end

    def doctype(name = String, &inner)
      crule = if inner
                inner.call | empty
              else
                empty
              end
      (start_doctype(name) - crule - end_doctype) >> proc do |x|
        node = REXML::DocType.new(x[0][1..])
        [node, x[1]]
      end
    end

    def externalentity(entity = String)
      token(XArray[:externalentity, entity]) >> proc do |x|
        REXML::ExternalEntity.new(x[0][1])
      end
    end

    def elementdecl(elem = String)
      token(XArray[:elementdecl, elem]) >> proc do |x|
        REXML::ElementDecl.new(x[0][1])
      end
    end

    def entitydecl(_entity = String)
      token(XArray[:entitydecl, elem]) >> proc do |x|
        REXML::Entity.new(x[0])
      end
    end

    def attlistdecl(_decl = String)
      token(XArray[:attlistdecl]) >> proc do |x|
        REXML::AttlistDecl.new(x[0][1..])
      end
    end

    def notationdecl(_decl = String)
      token(XArray[:notationdecl]) >> proc do |x|
        REXML::NotationDecl.new(*x[0][1..])
      end
    end

    def any_node(&)
      (element(&) | doctype(&) | text | pi | cdata |
       comment | xmldecl | externalentity | elementdecl |
       entitydecl | attlistdecl | notationdecl) >> proc { |x| x[2] }
    end

    def dom_constructor(&act)
      proc do |x|
        node = x[0][0]
        child = x[0][1]
        if child.is_a?(Array)
          child.each { |c| node.add(c) }
        else
          node.add(child)
        end
        if act
          act[node]
        else
          node
        end
      end
    end
  end
end
