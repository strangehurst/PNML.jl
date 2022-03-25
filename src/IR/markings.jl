
#-------------------
"""
Label of a [`Place`](@ref) in a [`PTNet`](@ref).

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest
julia> using PNML

julia> m = PNML.PTMarking(PNML.PnmlDict(:value=>nothing));

julia> m()
0

julia> m = PNML.PTMarking(PNML.PnmlDict(:value=>1));

julia> m()
1

julia> m = PNML.PTMarking(PNML.PnmlDict(:value=>12.34));

julia> m()
12.34
```

"""
struct PTMarking{N<:Number} <: Annotation
    value::N
    com::ObjectCommon
    # PTMarking does not use ObjectCommon.graphics,
    # but rather, TokenGraphics in ObjectCommon.tools.
end

function PTMarking(pdict::PnmlDict)
    PTMarking(onnothing(pdict, :value, 0), ObjectCommon(pdict))
end
convert(::Type{Maybe{PTMarking}}, pdict::PnmlDict) = PTMarking(pdict)

"""
Evaluate a [`PTMarking`](@ref).
"""
(mark::PTMarking)() = mark.value

#-------------------
"""
Label a Place in a [`AbstractHLCore`](#ref).

$(TYPEDEF)
$(TYPEDFIELDS)

# Examples

```jldoctest
julia> using PNML: HLMarking, PnmlDict, Term

julia> m = HLMarking(PnmlDict(:text=>"the text",
                        :structure=>Term(PnmlDict(:value=>3))));

julia> m()
"HLMarking functor not implemented"
```
"""
struct HLMarking <: HLAnnotation
    text::Maybe{String}
    term::Maybe{Term} # is the expected structure content
    com::ObjectCommon
    #TODO check that there is a text or structure (or both)
end

#TODO default value
HLMarking(pdict::PnmlDict) =
    HLMarking(pdict[:text], pdict[:structure], ObjectCommon(pdict))
convert(::Type{Maybe{HLMarking}}, pdict::PnmlDict) = HLMarking(pdict)

"""
Evaluate a [`HLMarking`](@ref). Returns a value of the same sort as its `Place`.
"""
(hlm::HLMarking)() = "HLMarking functor not implemented"

