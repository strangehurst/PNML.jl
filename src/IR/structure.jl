"""
$(TYPEDEF)
$(TYPEDFIELDS)

Structure used by high-level pnml labels.
"""
struct Structure
    value::PnmlDict
    #TODO xml
end

"""
$(TYPEDSIGNATURES)
"""
convert(::Type{Maybe{Structure}}, pdict::PnmlDict) = Structure(pdict)
