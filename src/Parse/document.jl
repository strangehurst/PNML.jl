"""
$(TYPEDEF)
$(TYPEDFIELDS)

Corresponds to <pnml> tag.
Wrap the collection of PNML nets from a single XML pnml document.
Adds the IDRegistry to [`PnmlModel`](@ref).
"""
struct Document{N,X}
    nets::N
    xml::X
    reg::IDRegistry
end

Document(s::AbstractString, reg=IDRegistry())   = Document(parse_pnml(root(parsexml(s)); reg), reg)
Document(doc::EzXML.Document, reg=IDRegistry()) = Document(parse_pnml(root(doc); reg), reg)
Document(pnml::PnmlModel, reg=IDRegistry())     = Document(pnml.nets, xmlnode(pnml), reg)

"""
Return all `nets` of `doc`.

$(TYPEDSIGNATURES)
"""
nets(doc::Document) = doc.nets
#=
"""
Build pnml from a string 'str' containing XML.
See [`parse_file`](@ref) and `Document("string")`.

$(TYPEDSIGNATURES)
"""
parse_str(str::AbstractString) = Document(EzXML.parsexml(str))

"""
Build pnml from a fileneame string `fname`.
See [`parse_str`](@ref) and `Document("string")`.

$(TYPEDSIGNATURES)
"""
parse_file(fname::AbstractString) = Document(EzXML.readxml(fname))
=#
Base.summary(doc::Document) = summary(stdout, doc)
function Base.summary(io::IO, doc::Document{N,X}) where {N,X}
    string(typeof(doc), " with ", length(doc.nets), " nets")
end

function Base.show(io::IO, doc::Document{N,X}) where {N,X}
    summary(doc)
    foreach(doc.nets) do net
        println(io, net)
    end
    #TODO Print ID Registry
end

function Base.show(io::IO, ::MIME"text/plain", doc::Document{N,X}) where {N,X}
    print(io, "Document:", doc)
end
