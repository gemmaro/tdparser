# frozen_string_literal: true

require 'tdparser'
require 'rexml/parsers/pullparser'
require 'rexml/document'

module TDParser
  class XMLTokenGenerator < TDParser::TokenGenerator
    def initialize(src)
      @xparser = REXML::Parsers::BaseParser.new(src)
      super() { |g|
        while @xparser.has_next?
          e = @xparser.pull
          g.yield(e)
        end
      }
    end
  end

  class XMLArray < Array
    def ===(ary)
      if super(ary)
        return true
      end
      if !ary.is_a?(Array)
        return false
      end
      each_with_index { |v, idx|
        v === ary[idx] or return false
      }
      true
    end
  end

  module XMLParser
    class XHash < Hash
      def ===(h)
        if super(h)
          return true
        end
        if !h.is_a?(Hash)
          return false
        end
        each { |k, v|
          v === h[k] or return false
        }
        true
      end
    end

    def start_element(name = String)
      token(XMLArray[:start_element, name, Hash])
    end

    def end_element(name = String)
      token(XMLArray[:end_element, name])
    end

    def element(elem = String, &inner)
      if inner
        crule = inner.call | empty
      else
        crule = empty
      end
      (start_element(elem) - crule - end_element(elem)) >> Proc.new { |x|
        name = x[0][1]
        attrs = x[0][2]
        node = REXML::Element.new
        node.name = name
        node.attributes.merge!(attrs)
        [node, x[1]]
      }
    end

    def text(match = String)
      token(XMLArray[:text, match]) >> Proc.new { |x|
        REXML::Text.new(x[0][1])
      }
    end

    def pi
      token(XMLArray[:processing_instruction, String, String]) >> Proc.new { |x|
        REXML::Instruction.new(x[0][1], x[0][2])
      }
    end

    def cdata(match = String)
      token(XMLArray[:cdata, match]) >> Proc.new { |x|
        REXML::CData.new(x[0][1])
      }
    end

    def comment(match = String)
      token(XMLArray[:comment, match]) >> Proc.new { |x|
        REXML::Comment.new(x[0][1])
      }
    end

    def xmldecl
      token(XMLArray[:xmldecl]) >> Proc.new { |x|
        REXML::XMLDecl.new(x[0][1], x[0][2], x[0][3])
      }
    end

    alias xml_decl xmldecl

    def start_doctype(name = String)
      token(XMLArray[:start_doctype, name])
    end

    def end_doctype
      token(XMLArray[:end_doctype])
    end

    def doctype(name = String, &inner)
      if inner
        crule = inner.call | empty
      else
        crule = empty
      end
      (start_doctype(name) - crule - end_doctype) >> Proc.new { |x|
        node = REXML::DocType.new(x[0][1..-1])
        [node, x[1]]
      }
    end

    def externalentity(entity = String)
      token(XMLArray[:externalentity, entity]) >> Proc.new { |x|
        REXML::ExternalEntity.new(x[0][1])
      }
    end

    alias external_entity externalentity

    def elementdecl(elem = String)
      token(XMLArray[:elementdecl, elem]) >> Proc.new { |x|
        REXML::ElementDecl.new(x[0][1])
      }
    end

    alias element_decl elementdecl

    def entitydecl(_entity = String)
      token(XMLArray[:entitydecl, elem]) >> Proc.new { |x|
        REXML::Entity.new(x[0])
      }
    end

    alias entity_decl entitydecl

    def attlistdecl(_decl = String)
      token(XMLArray[:attlistdecl]) >> Proc.new { |x|
        REXML::AttlistDecl.new(x[0][1..-1])
      }
    end

    alias attribute_list_declaration attlistdecl

    def notationdecl(_decl = String)
      token(XMLArray[:notationdecl]) >> Proc.new { |x|
        REXML::NotationDecl.new(*x[0][1..-1])
      }
    end

    alias notation_decl notationdecl

    def any_node(&b)
      (element(&b) | doctype(&b) | text | pi | cdata |
       comment | xmldecl | externalentity | elementdecl |
       entitydecl | attlistdecl | notationdecl) >> Proc.new { |x| x[2] }
    end

    def dom_constructor(&act)
      Proc.new { |x|
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
      }
    end
  end
end
