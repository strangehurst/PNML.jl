"""
$(TYPEDEF)

$(TYPEDFIELDS)

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
$(TYPEDSIGNATURES)

Return nets of `d` matching the given pntd `type`.
"""
function find_nets end
find_nets(d::Document, type::AbstractString) = find_nets(d, pntd(type))
find_nets(d::Document, type::Symbol) = filter(n->n[:type] === type, d.nets)

"""
$(TYPEDSIGNATURES)

Return first net contained by `d`.
"""
first_net(d::Document) = first(d.nets)

"""
$(TYPEDSIGNATURES)

Return all `nets` of `d`.
"""
nets(d::Document) = d.nets
  
"""
$(TYPEDSIGNATURES)

Build pnml from a string.
"""
function parse_str(str)::PNML.Document
    ezdoc = EzXML.parsexml(str)
    parse_doc(ezdoc)
end

"""
$(TYPEDSIGNATURES)

Build pnml from a file.
"""
function parse_file(fn)::PNML.Document
    ezdoc = EzXML.readxml(fn)
    parse_doc(ezdoc)
end

"""
$(TYPEDSIGNATURES)

Return a PNML.Document built from an XML Doncuent.
A well formed PNML XML document has a single root node: 'pnml'.
"""
function parse_doc(doc::EzXML.Document)::PNML.Document
    reg = PNML.IDRegistry()
    Document(parse_pnml(root(doc); reg), reg)
end


"""
$(TYPEDSIGNATURES)

Merge page content into the 1st page of each pnml net.
Note that refrence nodes are still present. They can be removed later
with [`deref!`](@ref).
"""
function flatten_pages! end

function flatten_pages!(doc::PNML.Document)
    foreach(flatten_pages!, nets(doc))
end

function flatten_pages!(net::PnmlDict)
    @assert net[:tag] === :net

    # Some of the keys are optional. They may be removed by a compress before flatten.
    for key in [:places, :trans, :arcs, :tools, :labels, :refT, :refP, :declarations]
        tmp = PnmlDict[]
        foreach(net[:pages]) do page
            if haskey(page, key) && !isnothing(page[key])
                push!.(Ref(tmp), page[key]) #TODO test this syntax
                empty!(page[key])
            end
        end
        if !isempty(tmp)
            net[:pages][1][key] = tmp
        end
    end
    net
end
