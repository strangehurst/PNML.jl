"""
$(TYPEDEF)
$(TYPEDFIELDS)

High-level Annotation Labels place meaning in <structure> that is consumed by "claimed" labels.
Is is expected to contain an abstract syntax tree (ast) for the many-sorted algebra expressed in XML.
We implement this to allow use of <structure> tags by other PnmlTypes.

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
