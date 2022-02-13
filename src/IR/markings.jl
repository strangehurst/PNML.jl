
###############################################################################
# PNML Nodes
###############################################################################

"""
$(TYPEDEF)
"""
abstract type Marking <: AbstractLabel end

#-------------------
"""
Labels a Place/Transition pntd Place instance.

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest
julia> using PNML

julia> p = PNML.PTMarking(PNML.PnmlDict(:value=>nothing));

julia> p.value
0

julia> p = PNML.PTMarking(PNML.PnmlDict(:value=>12.34));

julia> p.value
12.34
```

"""
struct PTMarking{N<:Number} <: Marking
    value::N
    com::ObjectCommon
    # PTMarking does not use ObjectCommon.graphics,
    # but rather, TokenGraphics in ObjectCommon.tools.
end

function PTMarking(pdict::PnmlDict)
    PTMarking(onnothing(pdict[:value], 0), ObjectCommon(pdict))
end
convert(::Type{Maybe{PTMarking}}, pdict::PnmlDict) = PTMarking(pdict)

(ptm::PTMarking)() = ptm.value

#-------------------
"""
PNML HLMarking labels a Place instance.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct HLMarking <: Marking
    text::Maybe{String}
    structure::Maybe{PnmlLabel}
    com::ObjectCommon
end

HLMarking(pdict::PnmlDict) =
    HLMarking(pdict[:text], pdict[:structure], ObjectCommon(pdict))
convert(::Type{Maybe{HLMarking}}, pdict::PnmlDict) = HLMarking(pdict)

"Evaluate the marking expression."
(hlm::HLMarking)() = @warn "HLMarking functor not implemented"

