"""
$(TYPEDEF)
$(TYPEDFIELDS)

Used by/in unclaimed high-level pnml labels.  
Is an abstract syntax tree (ast) expressed in XML.
Since we do not have knowledge of ast _here_ we place it in a `unclamed_label`

# Extra 
There are various defined structure ast variants:
  - Sort of a Place type [builtin, multi, product, user]
  - Term of Place HLMarking  [variable, operator]
  - Term of Transition Condition  [variable, operator]
  - Term of Arc Inscription [variable, operato`r]
  - Declarations of Declaration * [sort, variable, operator]
"""
struct Structure{T} #TODO
    tag::Symbol
    dict::T #TODO AnyElement for bring-up? What should be here?
    #TODO xml
end
Structure(p::Pair{Symbol,PnmlDict}) = Structure(p.first, p.second)

convert(::Type{Maybe{Structure}}, pdict::PnmlDict) = Structure(pdict)
