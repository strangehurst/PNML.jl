"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level Annotation Labels place meaning in <structure>.

Is an abstract syntax tree (ast) expressed in XML.
Note the structural similarity to [`PnmlLabel`](@ref) and [`AnyElement`](@ref)


# Extra
There are various defined structure ast variants:
  - Sort of a Place type [builtin, multi, product, user]
  - Term of Place HLMarking  [variable, operator]
  - Term of Transition Condition  [variable, operator]
  - Term of Arc Inscription [variable, operator]
  - Declarations of Declaration * [sort, variable, operator]
"""
struct Structure{T} #TODO
    tag::Symbol
    el::T
    xml::XMLNode
end

Structure(p::Pair{Symbol, Vector{Pair{Symbol,Any}}}, xml::XMLNode) = begin
    #@show p.first typeof(p)
    Structure(p.first, namedtuple(p.second), xml)
end
Structure(p::Pair{Symbol,<:NamedTuple}, node::XMLNode) = Structure(p.first, p.second, node)

tag(s::Structure) = s.tag
elements(s::Structure) = s.el
xmlnode(s::Structure) = s.xml

"""
$(TYPEDSIGNATURES)

Return [`Structure`](@ref) wrapping an [`unclaimed_label`](@ref) holding a <structure>.
Should be inside of an label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "structure")
    @warn "parse_structure is not a well defined thing."
    Structure(unclaimed_label(node, pntd, idregistry), node) #TODO anyelement
end
