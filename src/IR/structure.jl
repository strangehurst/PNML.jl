"""
$(TYPEDEF)
$(TYPEDFIELDS)

Structure used by high-level pnml labels.

"""
struct Structure{T} #TODO 
    dict::T #TODO AnyElement for bring-up? What should be here?
    #TODO xml
end

convert(::Type{Maybe{Structure}}, pdict::PnmlDict) = Structure(pdict)
