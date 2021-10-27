"""
Wrap the collection of PNML nets from a single XML tree.
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end

Document(p::PnmlDict, reg=IDRegistry()) = Document(p[:nets], p[:xml], reg)
Document(s::AbstractString, reg=IDRegistry()) = Document(parse_pnml(root(parsexml(s)); reg), reg)
         
"Return nets of `d` matching the given pntd `type`."
function find_nets end
find_nets(d::Document, type::AbstractString) = find_nets(d, pntd(type))
find_nets(d::Document, type::Symbol) = filter(n->n[:type] === type, d.nets)

"Return first net contained by `d`."
first_net(d::Document) = first(d.nets)

"Return all `nets` of `d`."
nets(d::Document) = d.nets
  

"Build pnml from a string."
function parse_str(str)::PNML.Document
    doc = EzXML.parsexml(str)
    parse_doc(doc)
end

"Build pnml from a file."
function parse_file(fn)::PNML.Document
    doc = EzXML.readxml(fn)
    parse_doc(doc)
end

""" parse_doc(doc::EzXML.Document)

Return a PNML.Document built from an XML Doncuent.
A well formed PNML XML document has a single root node: 'pnml'.
"""
function parse_doc(doc::EzXML.Document)::PNML.Document
    reg = PNML.IDRegistry()
    Document(parse_pnml(root(doc); reg), reg)
end



