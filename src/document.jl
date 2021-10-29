"""
$(TYPEDEF)

Wrap the collection of PNML nets from a single XML tree.
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end

Document(p::PnmlDict, reg=IDRegistry()) = Document(p[:nets], p[:xml], reg)
Document(s::AbstractString, reg=IDRegistry()) = Document(parse_pnml(root(parsexml(s)); reg), reg)
 
"""
$(SIGNATURES)

Return nets of `d` matching the given pntd `type`.
"""
function find_nets end
find_nets(d::Document, type::AbstractString) = find_nets(d, pntd(type))
find_nets(d::Document, type::Symbol) = filter(n->n[:type] === type, d.nets)

"""
$(SIGNATURES)

Return first net contained by `d`.
"""
first_net(d::Document) = first(d.nets)

"""
$(SIGNATURES)

Return all `nets` of `d`.
"""
nets(d::Document) = d.nets
  

"""
$(SIGNATURES)

Build pnml from a string.
"""
function parse_str(str)#::PNML.Document
    ezdoc = EzXML.parsexml(str)
    parse_doc(ezdoc)
end

"""
$(SIGNATURES)

Build pnml from a file.
"""
function parse_file(fn)#::PNML.Document
    ezdoc = EzXML.readxml(fn)
    parse_doc(ezdoc)
end

"""
$(SIGNATURES)

Return a PNML.Document built from an XML Doncuent.
A well formed PNML XML document has a single root node: 'pnml'.
"""
function parse_doc(doc::EzXML.Document)#::PNML.Document
    reg = PNML.IDRegistry()
    Document(parse_pnml(root(doc); reg), reg)
end



