# PnmlNet Utilities.

adjacent_place(net::PnmlNet, a::Arc) = adjacent_place(netdata(net), source(a), target(a))

#-----------------------------------------------------------------
# Given x ∈ S ∪ T
#   - the set •x = {y | (y, x) ∈ F } is the preset of x.
#   - the set x• = {y | (x, y) ∈ F } is the postset of x.


# ISO 15909-1:2019 Concept 4 precondition of a transition, preset or •t
"""
    preset(net, id) -> Iterator

Iterate ids of input (arc's source) for output transition or place `id`.

See [`PNet.in_inscriptions`](@ref) and [`transition_function`](@ref PNet.transition_function).
"""
preset(net::PnmlNet, id::Symbol) = begin
    Iterators.map(x -> source(arcdict(net)[x]), tgt_arcs(net, id))
end

# ISO 15909-1:2019 Concept 5 postcondition of a transition, postset or t•
"""
    postset(net, id) -> Iterator

Iterate ids of output (arc's target) for source transition or place `id`.

See [`PNet.out_inscriptions`](@ref) and [`transition_function`](@ref PNet.transition_function).
"""
postset(net::PnmlNet , id::Symbol) = begin
    Iterators.map(x -> target(arcdict(net)[x]), src_arcs(net, id))
end


"""
    inscriptions(net::PnmlNet) -> Iterator

Iterate over REFID => inscription(arc) pairs of `net`. This is the same order as `arcs`.
"""
function inscriptions end
function inscriptions(net::PnmlNet) #TODO! non-ground terms
    Iterators.map((arc_id, a)->arc_id => inscription(a)(NamedTuple()), pairs(PNML.arcdict(net)))
end

function conditions(net::PnmlNet) #TODO! non-ground terms
    Iterators.map((tr_id, t)->condition(t)(NamedTuple()), pairs(PNML.transitiondict(net)))
end

"""
inscription_value(::Type{T}, a, z, varsub) -> T

If `a` is nothing return `z` else evaluate inscription expression with varsub)`;
where `z` is `zero` or zero-like PnmlMultiset of same type as inscription and adjacent place.
and `varsub` is a possibly empty variable substitution for High-level net compatibility.
"""
function inscription_value end

function inscription_value(::Type{T}, a, z, varsub) where {T}
if isnothing(a)
    z::T
else
    eval(PNML.toexpr(PNML.term(PNML.inscription(a)), varsub))::T
end
end

"Convert inscription value of PN_HLPNG from multiset to cardinality of the multiset."
function _cvt_inscription_value(net::PnmlNet, a, z, varsub)
    val = inscription_value(PNML.inscription_value_type(net), a, z, varsub)
    return PNML.pntd(net) isa PT_HLPNG ? cardinality(val) : val
end

#==========================================================================
Notes based on ISO/IEC 15909-1:2019 (Part 1, 2nd Edition).

Color class (concept 13) a non-empty finite set, may be linearly ordered, circular or unordered.
Color domain (concept 14) a finite cartesian product of color classes.
C is a mapping which defines for each place and each transition its color domain.
W is the weight function, associates with each arc a general color function from C(t) to Bag(C(p)).

Color functions (concept 16, 17),
Let D be a color domain
Basic color functions are:
- projection that selects one component of a color
- successor that selects successor of color component
- all that maps any color to the "sum" of color components in class Cᵢ (`<all>` operator)
Class/General color functions
- linear combination (fᵢ) of basic color functions that select >0 tokens

Arcs must have a weight function (inscrition) that is a general color function.

Color Domain vs. Place SortType
ProductSort defines a color domain with >1 color classes (aka other Sorts).
Color functions select a single color component from the domain.
ProductSort -> PnmlTuple elements.
Selecting one tuple field is well founded math, julia handles it.
ProductSort only used by high-level nets.
Tuple elements will evaluate to Bags whose basis matches the place's ProductSort sorttype.

Need a PnmlMultiset that serves as `zero` for `*` and `+`.
PnmlMultiset with basis of `zero` or `null` sort, hold an empty Multiset{T}
matching eltype T for type stability, and acting like `zero`.
#~ See the zero method.
#todo test these axioms
Let z be the special PnmlMultiset
Let m be an ordinary PnmlMultiset
z * m = z
z + m = m

Where can special PnmlMultiset appear: incidence_matrix, where it represents no arc.
They are forbidden as a marking since the basis used is imaginary.
Will not appear in input marking or output of fir!(incidence, enabled, marking).

===========================================================================#

"""
    rewrite(net)

Rewrite TermInterface expressions.
"""
function rewrite(net::PnmlNet, marking)
    # TODO!
end


########################################################################################
# firing rule
########################################################################################
"""
    input_matrix(petrinet::AbstractPetriNet) -> Matrix{inscription_value_type(net)}
    input_matrix(petrinet::PnmlNet) -> Matrix{inscription_value_type(net)}

Create and return a matrix ntransitions x nplaces.
"""
function input_matrix end
function input_matrix(net::PnmlNet, marking)
    # PT_HLPNG will convert multiset of DotConstant to cardinality (an integer value).
    ivt = pntd(net) isa PT_HLPNG ? Int : PNML.inscription_value_type(net)
    imatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return input_matrix!(imatrix, net, marking) # Dispatch on net type.
end

#! Default `<:Number`
function input_matrix!(imatrix, net::PnmlNet, marking)
    varsub = NamedTuple() # PT_HLPNG  is only supported High-level net here
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id) in enumerate(PNML.place_idset(net))
            z = zero_marking(place(net, place_id)) # 0 or empty multiset similar to placetype
            a = arc(net, place_id, transition_id)
            imatrix[t, p] = _cvt_inscription_value(net, a, z, varsub)::Number
        end
    end
return imatrix
end

"""
    output_matrix(petrinet::AbstractPetriNet) -> Matrix{inscription_value_type(net)}
    output_matrix(petrinet::PnmlNet) -> Matrix{inscription_value_type(net)}

Create and return a matrix ntransitions x nplaces.
"""
function output_matrix end
function output_matrix(net::PnmlNet, marking)
    ivt = pntd(net) isa PT_HLPNG ? Int : PNML.inscription_value_type(net)
    omatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return output_matrix!(omatrix, net, marking) # Dispatch on net type.
end

function output_matrix!(omatrix, net::PnmlNet, marking)
    varsub = NamedTuple()
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id) in enumerate(PNML.place_idset(net))
            z = zero_marking(place(net, place_id))
            a = arc(net, transition_id, place_id)
            omatrix[t, p] = _cvt_inscription_value(net, a, z, varsub)::Number
        end
    end
return omatrix
end

"""
    incidence_matrix(petrinet, marking) -> LArray

When token identity is collective, marking and inscription values are Numbers and matrix
`C[arc(transition,place)] = inscription(arc(transition,place)) - inscription(arc(place,transition))`
is called the incidence_matrix.

High-level nets have tokens with individual identity, perhaps tuples of them,
usually multisets of finite enumerations, can be other sorts including numbers, strings, lists.
Symmetric nets are restricted, and thus easier to deal with and reason about.
"""
function incidence_matrix end

# There will be
function incidence_matrix(net::PnmlNet, marking) #{<:AbstractHLCore}, marking)
    varsub = NamedTuple() #^ Here we support only PT_HLPNG
    ivt = pntd(net) isa PT_HLPNG ? Int : PNML.inscription_value_type(net)
    C = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id)  in enumerate(PNML.place_idset(net))
            z = zero_marking(place(net, place_id))

            tp = arc(net, transition_id, place_id)
            l = _cvt_inscription_value(net, tp, z, varsub)::Number
            pt = arc(net, place_id, transition_id)
            r = _cvt_inscription_value(net, pt, z, varsub)::Number

            C[t, p] = l - r
        end
    end
    return C
end

# Vector{NamedTuple} cached in transition field.
varsubs(net::PnmlNet, transition_id::REFID) = varsubs(transition(net, transition_id))
