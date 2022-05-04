"""
$(TYPEDEF)
$(TYPEDFIELDS)

Used by/in unclaimed high-level pnml labels.
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
    dict::T
    xml::XMLNode
end
Structure(p::Pair{Symbol,PnmlDict}, node::XMLNode) = Structure(p.first, p.second, node)

tag(s::Structure) = s.tag
dict(s::Structure) = s.dict
xmlnode(s::Structure) = s.xml