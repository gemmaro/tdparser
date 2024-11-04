# frozen_string_literal: true

require 'tdp'
require 'rexml/parsers/pullparser'
require 'rexml/document'

module TDPXML
  module XMLParser
    class XMLTokenGenerator < TDParser::TokenGenerator
      def initialize(src)
        @xparser = REXML::Parsers::BaseParser.new(src)
        super(){|g|
          while(@xparser.has_next?)
            e = @xparser.pull()
            g.yield(e)
          end
        }
      end
    end

    class XArray < Array
      def ===(ary)
        if super(ary)
          return true
        end
        if !ary.is_a?(Array)
          return false
        end
        each_with_index{|v,idx|
          case ary[idx]
          when v
          else
            return false
          end
        }
        true
      end
    end

    class XHash < Hash
      def ===(h)
        if super(h)
          return true
        end
        if !h.is_a?(Hash)
          return false
        end
        each{|k,v|
          case h[k]
          when v
          else
            return false
          end
        }
        true
      end
    end

    def start_element(name=String)
      token(XArray[:start_element, name, Hash])
    end

    def end_element(name=String)
      token(XArray[:end_element, name])
    end

    def element(elem=String, &inner)
      if inner
        crule = inner.call()|empty()
      else
        crule = empty()
      end
      (start_element(elem) - crule - end_element(elem)) >> Proc.new{|x|
        name = x[0][1]
        attrs = x[0][2]
        node = REXML::Element.new()
        node.name = name
        node.attributes.merge!(attrs)
        [node,x[1]]
      }
    end

    def text(match=String)
      token(XArray[:text, match]) >> Proc.new{|x|
        REXML::Text.new(x[0][1])
      }
    end

    def pi()
      token(XArray[:processing_instruction, String, String]) >> Proc.new{|x|
        REXML::Instruction.new(x[0][1],x[0][2])
      }
    end

    def cdata(match=String)
      token(XArray[:cdata, match]) >> Proc.new{|x|
        REXML::CData.new(x[0][1])
      }
    end

    def comment(match=String)
      token(XArray[:comment, match]) >> Proc.new{|x|
        REXML::Comment.new(x[0][1])
      }
    end

    def xmldecl()
      token(XArray[:xmldecl]) >> Proc.new{|x|
        REXML::XMLDecl.new(x[0][1],x[0][2], x[0][3])
      }
    end

    def start_doctype(name=String)
      token(XArray[:start_doctype, name])
    end

    def end_doctype()
      token(XArray[:end_doctype])
    end

    def doctype(name=String, &inner)
      if (inner)
        crule = inner.call()|empty()
      else
        crule = empty()
      end
      (start_doctype(name) - crule - end_doctype()) >> Proc.new{|x|
        node = REXML::DocType.new(x[0][1..-1])
        [node, x[1]]
      }
    end

    def externalentity(entity=String)
      token(XArray[:externalentity, entity]) >> Proc.new{|x|
        REXML::ExternalEntity.new(x[0][1])
      }
    end

    def elementdecl(elem=String)
      token(XArray[:elementdecl, elem]) >> Proc.new{|x|
        REXML::ElementDecl.new(x[0][1])
      }
    end

    def entitydecl(_entity=String)
      token(XArray[:entitydecl, elem]) >> Proc.new{|x|
        REXML::Entity.new(x[0])
      }
    end

    def attlistdecl(_decl=String)
      token(XArray[:attlistdecl]) >> Proc.new{|x|
        REXML::AttlistDecl.new(x[0][1..-1])
      }
    end

    def notationdecl(_decl=String)
      token(XArray[:notationdecl]) >> Proc.new{|x|
        REXML::NotationDecl.new(*x[0][1..-1])
      }
    end

    def any_node(&b)
      (element(&b) | doctype(&b) | text() | pi() | cdata() |
       comment() | xmldecl() | externalentity() | elementdecl() |
       entitydecl() | attlistdecl() | notationdecl()) >> Proc.new{|x| x[2]}
    end

    def dom_constructor(&act)
      Proc.new{|x|
        node = x[0][0]
        child = x[0][1]
        if (child.is_a?(Array))
          child.each{|c| node.add(c) }
        else
          node.add(child)
        end
        if (act)
          act[node]
        else
          node
        end
      }
    end
  end
end
