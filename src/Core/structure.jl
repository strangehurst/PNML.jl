"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level Annotation Labels place meaning in <structure>.
Is is expected to contain an abstract syntax tree (ast) for the many-sorted algebra expressed in XML.

Note the structural similarity to [`PnmlLabel`](@ref) and [`AnyElement`](@ref)

# Extra
There are various defined structure ast variants in pnml:
  - Sort Type of a Place [builtin, multi, product, user]
  - Place HLMarking [variable, operator]
  - Transition Condition [variable, operator]
  - Arc Inscription [variable, operator]
  - Declarations [sort, variable, operator]
These should all have dedicated parsers and objects as *claimed labels*.
Here we provide a fallback for *unclaimed tags*.
"""
struct Structure
    tag::Symbol
    el::Vector{AnyXmlNode}
end

Structure(p::Pair{Symbol, Vector{AnyXmlNode}}) = Structure(p.first, p.second)

tag(s::Structure) = s.tag
elements(s::Structure) = s.el

"""
$(TYPEDSIGNATURES)

Return [`Structure`](@ref) holding a <structure>.
Should be inside of an label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node::XMLNode, pntd::PnmlType, idregistry::PnmlIDRegistry)
    check_nodename(node, "structure")
    #@warn "parse_structure is not a well defined thing, $pntd."
    Structure(unclaimed_label(node, pntd, idregistry)) #TODO anyelement
end
