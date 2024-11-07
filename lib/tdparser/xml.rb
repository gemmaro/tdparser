# frozen_string_literal: true

require 'tdparser'
require 'rexml/parsers/pullparser'
require 'rexml/document'

module TDParser
  def self.xml_token_generator(src)
    parser = REXML::Parsers::BaseParser.new(src)
    Enumerator.new do |y|
      y << parser.pull while parser.has_next?
    end
  end

  class XMLArray < Array
    def ===(ary)
      if super(ary)
        return true
      end
      unless ary.is_a?(Array)
        return false
      end
      each_with_index { |v, idx|
        v === ary[idx] or return false
      }
      true
    end
  end

  module XMLParser
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
      (start_element(elem) - crule - end_element(elem)) >> proc { |x|
        name = x[0][1]
        attrs = x[0][2]
        node = REXML::Element.new
        node.name = name
        node.attributes.merge!(attrs)
        [node, x[1]]
      }
    end

    def text(match = String)
      token(XMLArray[:text, match]) >> proc { |x|
        REXML::Text.new(x[0][1])
      }
    end

    def pi
      token(XMLArray[:processing_instruction, String, String]) >> proc { |x|
        REXML::Instruction.new(x[0][1], x[0][2])
      }
    end

    def cdata(match = String)
      token(XMLArray[:cdata, match]) >> proc { |x|
        REXML::CData.new(x[0][1])
      }
    end

    def comment(match = String)
      token(XMLArray[:comment, match]) >> proc { |x|
        REXML::Comment.new(x[0][1])
      }
    end

    def xmldecl
      token(XMLArray[:xmldecl]) >> proc { |x|
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
      (start_doctype(name) - crule - end_doctype) >> proc { |x|
        node = REXML::DocType.new(x[0][1..-1])
        [node, x[1]]
      }
    end

    def externalentity(entity = String)
      token(XMLArray[:externalentity, entity]) >> proc { |x|
        REXML::ExternalEntity.new(x[0][1])
      }
    end

    alias external_entity externalentity

    def elementdecl(elem = String)
      token(XMLArray[:elementdecl, elem]) >> proc { |x|
        REXML::ElementDecl.new(x[0][1])
      }
    end

    alias element_decl elementdecl

    def entitydecl(_entity = String)
      token(XMLArray[:entitydecl, elem]) >> proc { |x|
        REXML::Entity.new(x[0])
      }
    end

    alias entity_decl entitydecl

    def attlistdecl(_decl = String)
      token(XMLArray[:attlistdecl]) >> proc { |x|
        REXML::AttlistDecl.new(x[0][1..-1])
      }
    end

    alias attribute_list_declaration attlistdecl

    def notationdecl(_decl = String)
      token(XMLArray[:notationdecl]) >> proc { |x|
        REXML::NotationDecl.new(*x[0][1..-1])
      }
    end

    alias notation_decl notationdecl

    def any_node(&)
      (element(&) | doctype(&) | text | pi | cdata |
       comment | xmldecl | externalentity | elementdecl |
       entitydecl | attlistdecl | notationdecl) >> proc { |x| x[2] }
    end

    def dom_constructor(&act)
      proc { |x|
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
