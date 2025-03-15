using Base: Fix2, Fix1

"""
$(TYPEDEF)

Top-level of a **single network** in a pnml model that is some flavor of Petri Net.
Note that pnml can represent nets that are **not** Petri Nets.

Here is where specialization and restriction are applied to achive Proper Petri Behavior.

See [`PnmlModel`](@ref), [`PnmlType`](@ref).

# Extended

Additional constrants can be imposed. We want to run under the motto:
"syntax is not semantics, quack".

Since a PNML.Document model can contain multiple networks it is possible that
a higher-level will create multiple AbstractPetriNet instances, each a different type.

Multiple [`Page`](@ref)s can (are permitted to) be merged into one page
by [`flatten_pages!`](@ref) without losing any Petri Net semantics.
"""
abstract type AbstractPetriNet{PNTD<:PnmlType} end

# Interface is having id::Symbol, net::PnmlNet.
function Base.getproperty(pn::AbstractPetriNet, prop_name::Symbol)
    if prop_name === :id
        return getfield(pn, :id)::Symbol
    elseif prop_name === :net
        return getfield(pn, :net)::PnmlNet
    end
    return getfield(pn, prop_name)
end

nettype(::AbstractPetriNet{T}) where {T <: PnmlType} = T

#TODO Is redundant copy of id in petri net and pnml net needed/wanted?
pid(petrinet::AbstractPetriNet)     = petrinet.id # maybe petrinet.id === pid(pnmlnet(petrinet))
pnmlnet(petrinet::AbstractPetriNet) = petrinet.net

#------------------------------------------------------------------------------------------
# Forward MANY THINGS to the IR implementation pnmlnet.
# TODO Adopt a forwarder?
# TODO
#------------------------------------------------------------------------------------------
name(petrinet::AbstractPetriNet)           = name(pnmlnet(petrinet))
places(petrinet::AbstractPetriNet)         = places(pnmlnet(petrinet))
transitions(petrinet::AbstractPetriNet)    = transitions(pnmlnet(petrinet))
arcs(petrinet::AbstractPetriNet)           = arcs(pnmlnet(petrinet))
refplaces(petrinet::AbstractPetriNet)      = refPlaces(pnmlnet(petrinet))
reftransitions(petrinet::AbstractPetriNet) = refTransitions(pnmlnet(petrinet))

npages(pn::AbstractPetriNet)          = npages(pnmlnet(pn))
nplaces(pn::AbstractPetriNet)         = nplaces(pnmlnet(pn))
ntransitions(pn::AbstractPetriNet)    = ntransitions(pnmlnet(pn))
narcs(pn::AbstractPetriNet)           = narcs(pnmlnet(pn))
nrefplaces(pn::AbstractPetriNet)      = nrefplaces(pnmlnet(pn))
nreftransitions(pn::AbstractPetriNet) = nreftransitions(pnmlnet(pn))

#------------------------------------------------------------------
"Return pnmlnet's place_idset"
place_idset(petrinet::AbstractPetriNet)           = place_idset(pnmlnet(petrinet))
has_place(petrinet::AbstractPetriNet, id::Symbol) = has_place(pnmlnet(petrinet), id)
place(petrinet::AbstractPetriNet, id::Symbol)     = place(pnmlnet(petrinet), id)

initial_marking(petrinet::AbstractPetriNet, id::Symbol) = initial_marking(pnmlnet(petrinet), id)

#------------------------------------------------------------------
transition_idset(petrinet::AbstractPetriNet)           = transition_idset(pnmlnet(petrinet))
has_transition(petrinet::AbstractPetriNet, id::Symbol) = has_transition(pnmlnet(petrinet), id)
transition(petrinet::AbstractPetriNet, id::Symbol)     = transition(pnmlnet(petrinet), id)

condition(petrinet::AbstractPetriNet, id::Symbol)      = condition(pnmlnet(petrinet), id)

#------------------------------------------------------------------
arc_idset(petrinet::AbstractPetriNet)            = arc_idset(pnmlnet(petrinet))
has_arc(petrinet::AbstractPetriNet, id::Symbol)  = has_arc(pnmlnet(petrinet), id)
arc(petrinet::AbstractPetriNet, id::Symbol)      = arc(pnmlnet(petrinet), id)

all_arcs(petrinet::AbstractPetriNet, id::Symbol) = all_arcs(pnmlnet(petrinet), id)
src_arcs(petrinet::AbstractPetriNet, id::Symbol) = src_arcs(pnmlnet(petrinet), id)
tgt_arcs(petrinet::AbstractPetriNet, id::Symbol) = tgt_arcs(pnmlnet(petrinet), id)

"Forward inscription lookup to `pnmlnet`"
inscription(petrinet::AbstractPetriNet, arc_id::Symbol) = inscription(pnmlnet(petrinet), arc_id)
#! ====================================================================================
#^   HL inscription() require a NamedTuple to evaluate the compiled expression
#! ====================================================================================

#------------------------------------------------------------------
refplace_idset(petrinet::AbstractPetriNet)            = refplace_idset(pnmlnet(petrinet))
has_refplace(petrinet::AbstractPetriNet, id::Symbol)  = has_refplace(pnmlnet(petrinet), id)
refplace(petrinet::AbstractPetriNet, id::Symbol)      = refplace(pnmlnet(petrinet), id)

reftransition_idset(petrinet::AbstractPetriNet)       = reftransition_idset(pnmlnet(petrinet))
has_reftransition(petrinet::AbstractPetriNet, id::Symbol) = has_reftransition(pnmlnet(petrinet), id)
reftransition(petrinet::AbstractPetriNet, id::Symbol) = reftransition(pnmlnet(petrinet), id)


#####################################################################################
# Labelled Vectors
#####################################################################################

"""
    inscriptions(petrinet::AbstractPetriNet) -> LVector[id(arc) => inscription(arc)]
"""
function inscriptions(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    #TODO eval(toexpr(term(inscription(a)), NamedTuple())
    LVector((;[arc_id => inscription(a)(NamedTuple()) for (arc_id, a) in pairs(arcdict(net))]...))
end

"""
    rates(petrinet::AbstractPetriNet) -> LVector[id(transition) => rate(transition]

Return a transition-id labelled vector of rate values.

We allow all PNML nets to be stochastic Petri nets. See [`rate`](@ref).
"""
function rates(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    LVector((;[tid => rate(t) for (tid, t) in pairs(transitiondict(net))]...))
end


"""
    initial_markings(petrinet) -> LVector{marking_value_type}

LVector labelled with place id and holding initial marking's value.
Used to create a vector of place markings indexed by place ID.

#TODO refactor from LVector to tuples of pairs.

High-level P/T Nets use cardinality of its multiset place marking value.
Really, the implementation should be the same as for PTNet.

Other HL Nets use multisets.
"""
function initial_markings end #TODO move "lvector tools" section

function initial_markings(petrinet::AbstractPetriNet)
    net = pnmlnet(petrinet)
    return initial_markings(net) # Dispatch on nettype.
end

function initial_markings(net::PnmlNet)
    m1 = LVector((;[id => initial_marking(p)::Number for (id,p) in pairs(placedict(net))]...))
    #todo m1 = tuple([id => initial_marking(p)::Number for (id,p) in pairs(placedict(net))]...)
    return m1
end

# PT_HLPNG multisets of dotconstants map well to integer via cardinality.
function initial_markings(net::PnmlNet{PT_HLPNG})
    m1 = LVector((;[id => cardinality(initial_marking(p)::PnmlMultiset)::Number for (id,p) in pairs(placedict(net))]...))
    return m1
end

#! Other HL need it to be treated as multiset, not simple numbers!
function initial_markings(net::PnmlNet{<:AbstractHLCore})
    # Evaluate the ground term expression into a multiset.
    m1 = LVector((;[id => initial_marking(p)::PnmlMultiset for (id,p) in pairs(placedict(net))]...))
    return m1
end

"""
    conditions(petrinet) -> LVector{condition_value_type(pntd)}

LVector labelled with transition id and holding its condition's value.
"""
function conditions(petrinet::AbstractPetriNet) #TODO move "lvector tools" section
    net = pnmlnet(petrinet)
    # Evaluate conditions here. #TODO! non-ground terms
    LVector((;[id => condition(t)() for (id, t) in pairs(transitiondict(net))]...))
    #todo tuple([id => condition(t)() for (id, t) in pairs(transitiondict(net))]...)
end

#####################################################################################
#
#####################################################################################


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
        eval(toexpr(term(inscription(a)), varsub))::T
        #(inscription(a))(varsub)::T # Evaluates PnmlExpr.
    end
end

# TODO: high-level will be multiset except for PT_HLPNG!
function _cvt_inscription_value(net::PnmlNet, a, z, varsub)
    val = inscription_value(inscription_value_type(net), a, z, varsub)
    return pntd(net) isa PT_HLPNG ? cardinality(val) : val
end

#! ====================================================================================
#^ This use of inscription(arc) returns a callable that has a NamedTuple as an argument.
#^ HL inscription() requires a NamedTuple to evaluate the compiled expression that
#^ may have a variable. So everyone must handle a empty NamedTuple.
#! ====================================================================================

"""
    input_matrix(petrinet::AbstractPetriNet) -> Matrix{inscription_value_type(net)}

Create and return a matrix ntransitions x nplaces.
"""
function input_matrix(petrinet::AbstractPetriNet, marking)
    net = pnmlnet(petrinet)
    # PT_HLPNG will convert multiset of DotConstant to cardinality (an integer value).
    ivt = pntd(net) isa PT_HLPNG ? Int : inscription_value_type(net)
    imatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return input_matrix!(imatrix, net, marking) # Dispatch on net type.
end

#! Default `<:Number`
function input_matrix!(imatrix, net::PnmlNet, marking)
    varsub = NamedTuple() # PT_HLPNG  is only supported High-level net here
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id) in enumerate(place_idset(net))
            z = zero_marking(place(net, place_id)) # 0 or empty multiset similar to placetype
            a = arc(net, place_id, transition_id)
            imatrix[t, p] = _cvt_inscription_value(net, a, z, varsub)::Number
        end
    end
    return imatrix
 end

"""
    output_matrix(petrinet::AbstractPetriNet) -> Matrix{inscription_value_type(net)}

Create and return a matrix ntransitions x nplaces.
"""
function output_matrix(petrinet::AbstractPetriNet, marking)
    net = pnmlnet(petrinet)
    ivt = pntd(net) isa PT_HLPNG ? Int : inscription_value_type(net)
    omatrix = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    return output_matrix!(omatrix, net, marking) # Dispatch on net type.
end

function output_matrix!(omatrix, net::PnmlNet, marking)
    varsub = NamedTuple()
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id) in enumerate(place_idset(net))
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
`C[transition,place] = inscription(transition,place) - inscription(place,transition)`
is called the incidence_matrix.

High-level nets have tokens with individual identity, perhaps tuples of them,
usually multisets of finite enumerations, can be other sorts including numbers, strings, lists.
Symmetric nets are restricted, and thus easier to deal with and reason about.

We use multiset cardinality to turn high-level inscriptions into integers.
"""
function incidence_matrix(petrinet::AbstractPetriNet, marking)
    C = incidence_matrix(pnmlnet(petrinet), marking)
    @show typeof(C) axes(C)
    return C
end

# There will be
function incidence_matrix(net::PnmlNet, marking) #{<:AbstractHLCore}, marking)
    varsub = NamedTuple() #^ Here we support only PT_HLPNG
    ivt = pntd(net) isa PT_HLPNG ? Int : inscription_value_type(net)
    C = Matrix{ivt}(undef, ntransitions(net), nplaces(net))
    for (t, transition_id) in enumerate(transition_idset(net))
        for (p, place_id)  in enumerate(place_idset(net))
            z = zero_marking(place(net, place_id))

            tp = arc(net, transition_id, place_id)
            l = _cvt_inscription_value(net, tp, z, varsub)::Number
            #@show tp l
            pt = arc(net, place_id, transition_id)
            r = _cvt_inscription_value(net, pt, z, varsub)::Number
            #@show pt r

            C[t, p] = l - r
        end
    end
    return C
end


#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
adjacent_place(net::PnmlNet, a::Arc) = adjacent_place(netdata(net), source(a), target(a))

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
    binding_value_sets(net::PnmlNet, marking) -> Vector{Dict{REFID,Any}}

Return dictionary with transaction ID is key and value is binding set for variables of that transition.
Each variable of an enabled transition will have a non-empty binding.
"""
function binding_value_sets(net::PnmlNet, marking)
    bv_sets = Vector{Dict{REFID,Any}}() # One dictionary for each transition.
    # The order of transitions is maintained.
    for t in transitions(net)::Transition
        bvalset = Dict{REFID,Set{eltype(basis)}}() # For this transition
        for a in PNML.preset(net, t)::Arc
            adj = adjacent_place(net, a)
            placesort = sortref(adj)
            vs = vars(inscription(a))::Tuple #todo PnmlExpr

            for v in vs # inscription that is not a ground term
                equal(placesort, v) || error("sorts not equal for variable $v and marking $placesort")
                #? for creating Ref need index into product sort/PnmlTuple
                bvs = Dict{REFID,Set{eltype(basis)}}() # For this arc
                # bind elements of the multiset to the variable when the multiplicities match.
                for el in keys(marking[pid(adj)])
                    # each element with enough multiplicity can be bound.
                    if multiplicity(marking[pid(adj)], el) >= length(filter(==(v), vs))
                        push!(bvs[v], el)
                    end
                end

                for k in keys(bvs)
                    bvalset[k] = haskey(bvalset, k) ? intersect(bvalset[k], bvs[k]) : bvs[k]
                end
            end
            # Empty binding value set means the transition is not enabled.
            isempty(vars) || !isempty(bvalset) || error("expected non-empty binding value set")
        end
        push!(bv_sets, bvalset)
    end
    return bv_sets
end

# function variable_subs(tr::Transition, marking)
#     #@error("implement me variable_subs($tr, $marking)")
#     return varsubs(tr)
# end

#^+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""
    enabled(::AbstractPetriNet, ::LVector) -> LVector

Return labelled vector of id=>boolean where `true` means transition `id` is enabled at current `marking`.
"""
function enabled(petrinet::AbstractPetriNet, marking)
    return enabled(pnmlnet(petrinet), marking) # Dispatch on net type.
end

# For each transition's input arcs, compare the inscription to the place marking.
function enabled(net::PnmlNet, marking)
    varsub = NamedTuple() # There are no varibles possible here.
    #! LVector((;[t => all(p -> marking[p] >= inscription(arc(net,p,t))(varsub), preset(net, t))
    #!         for t in transition_idset(net)]...))
    [all(p -> marking[p] >= inscription(arc(net,p,t))(varsub),
                        PNML.preset(net, t)) for t in transition_idset(net)]
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
Will not appear in input marking or output of fire!(incidence, enabled, marking).

===========================================================================#

function varsubs(net::PnmlNet, transition_id::REFID)
    varsubs(transition(net, transition_id))
end

function enabled(net::PnmlNet{<:AbstractHLCore}, marking)
    #!LVector((;enabledXXX(net, marking)...))
    # LVector((;[t => all(p -> marking[p] >= inscription(arc(net,p,t))(first(varsubs(transition(net,t)))), preset(net, t))
    #     for t in transition_idset(net)]...))
    enabledXXX(net, marking)::Vector{Bool} #todo refactor the XXX
end

# AlgebraicJulia wants LabelledPetriNet constructed with
# with Varargs pairs of transition_name=>((input_states)=>(output_states))
# example LabelledPetriNet([:S, :I, :R], :inf=>((:S,:I)=>(:I,:I)), :rec=>(:I=>:R))

"""
    fire!(incidence, enabled, marking) -> LVector

Return the marking after firing transition:   marking + incidence * enabled

`marking` LVector values added to product of `incidence'` matrix and firing vector `enabled`.
"""
function fire!(incidence, enabled, m₀) #TODO move "lvector tools" section
    #println("fire!")
    #@show typeof(incidence) enabled typeof(m₀)
    #@show permutedims(incidence) * enabled
    #! Multisets do not have negative multiplicities so al; HL Nets fail here!
    m₁ = muladd(permutedims(incidence), enabled, m₀) # need cardinality for PT_HLPNG marking vector
    LVector(namedtuple(symbols(m₀), m₁)) # old names, new values
end

function fire2(C, anet, mx)
    pntd = nettype(anet)
    if pntd <: PT_HLPNG
        PNML.fire!(C, enabled(anet, mx), mx)
    elseif pntd <: AbstractHLCore
        println("fire $(repr(pntd)) not implemented here, good luck")
        PNML.fire!(C, enabled(anet, mx), mx)
    else
        PNML.fire!(C, enabled(anet, mx), mx)
    end
end

"reachability_graph"
function reachability_graph(net)
    @error "rechability graph" net
end

#-----------------------------------------------------------------
# Show and Tell Section:
#-----------------------------------------------------------------
Base.summary(io::IO, pn::AbstractPetriNet) = print(io, summary(pn))
function Base.summary(pn::AbstractPetriNet)
    string(typeof(pn), " id ", pid(pn), ", ",
        length(places(pn)), " places, ",
        length(transitions(pn)), " transitions, ",
        length(arcs(pn)), " arcs")::String
end

function Base.show(io::IO, pn::AbstractPetriNet)
    println(io, summary(pn))
    println(io, "places")
    println(io, places(pn))
    println(io, "transitions")
    println(io, transitions(pn))
    println(io, "arcs")
    print(io, arcs(pn))
end

#-----------------------------------------------------------------
#-----------------------------------------------------------------

"""
Wrap a single pnml net. Presumes that the net does not need to be flattened
as all content is in first page.

$(TYPEDEF)
$(TYPEDFIELDS)

# Details

"""
struct HLPetriNet{PNTD} <: AbstractPetriNet{PNTD}
    net::PnmlNet{PNTD}
end
"Construct from string of valid pnml XML, using the first network in model."
HLPetriNet(str::AbstractString) = HLPetriNet(parse_str(str))
HLPetriNet(model::PnmlModel)    = HLPetriNet(first(nets(model)))

#=
# What are the characteristics of a SimpleNet?

This use-case is for explorations, might abuse the standard. The goal of PNML.jl
is to not constrain what can be parsed & represented in the
intermediate representation (IR). So many non-standard XML constructions are possible,
with the standars being a subset. It is the role of IR users to enforce semantics
upon the IR. SimpleNet takes liberties!

Assumptions about labels:
 place has numeric marking, default 0
 transition has numeric condition, default 0
 arc has source, target, numeric inscription value, default 0

# Non-simple Networks means what?

# SimpleNet

Created to be a end-to-end use case. And explore implementing something-that-works
while building upon and improving the IR. Does not try to conform to any standard.
Much of the complexity possible with pnml is ignored.

The first use is to recreate the lotka-volterra model from Petri.jl examples.
Find it in the examples folder. This is a stochastic net or reaction net.

Liberties are taken with pnml, remember that standards-checking is not a goal.
A less-simple consumer of the IR can impose standards-checking.

=#

"""
$(TYPEDEF)
$(TYPEDFIELDS)

**TODO: Rename SimpleNet to TBD**

SimpleNet is a concrete `AbstractPetriNet` wrapping a single `PnmlNet`.

Uses a flattened net to avoid the page level of the pnml hierarchy.

Note: A multi-page petri net can always be flattened by removing
referenceTransitions & referencePlaces, and merging pages into the first page.
"""
struct SimpleNet{PNTD} <: AbstractPetriNet{PNTD}
    id::Symbol # Redundant copy of the net's ID for dispatch.
    net::PnmlNet{PNTD}
end

SimpleNet(s::AbstractString) = SimpleNet(parse_str(s))
SimpleNet(node::XMLNode)     = SimpleNet(parse_pnml(node))
function SimpleNet(model::PnmlModel)
    ns = nets(model)
    fn = first(ns)
    SimpleNet(fn)
end
function SimpleNet(net::PnmlNet)
    flatten_pages!(net)
    SimpleNet(pid(net), net)
end

#-------------------------------------------------------------------------------
# Implement PNML Petri Net interface. See interface.jl for docstrings.
#-------------------------------------------------------------------------------
