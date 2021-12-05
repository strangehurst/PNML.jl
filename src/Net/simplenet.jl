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
Find it in the examples folder. This is a stochastic Petri Net.

Liberties are taken with pnml, remember that standards-checking is not a goal.
A less-simple consumer of the IR can impose standards-checking.

=#

"""
$(TYPEDEF)

$(TYPEDFIELDS)
**TODO: Rename SimpleNet to TBD** 
SimpleNet wraps the `place`, `transition` & `arc` collections of a single page of one net.

Omits the page level of the pnml-defined hierarchy by collapsing down to one page.
A multi-page net can be collpsed by removing referenceTransitions & referencePlaces,
and merging pages into the first page. Only selected fields are merged.
"""
struct SimpleNet{PNTD} <: PetriNet{PNTD}
    "Same as the XML attribute of the same name."
    id::Symbol

    p1::PnmlDict
end

SimpleNet(str::AbstractString) = SimpleNet(PNML.Document(str))
SimpleNet(doc::PNML.Document)  = SimpleNet(first_net(doc))
function SimpleNet(net::PnmlDict)
    netcopy = deepcopy(net)
    flatten_pages!(netcopy)
    SimpleNet{typeof(pnmltype(netcopy))}(pid(netcopy), netcopy[:pages][1])
end

pid(s::SimpleNet) = s.id

function Base.show(io::IO, s::SimpleNet{P}) where {P}
    println(io, "PNML.SimpleNet{$P}(")
    println(io, "id=", pid(s), ", ",
            length(places(s)), " places, ",
            length(transitions(s)), " transitions, ",
            length(arcs(s)), " arcs")
    println(io, pid(s), " places")
    pprintln(io, places(s))
    println(io, pid(s), " transitions")
    pprintln(io, transitions(s))
    println(io, pid(s), " arcs")
    pprintln(io, arcs(s))
    print(io, ")")
end


"""
$(TYPEDSIGNATURES)
"""
places(s::SimpleNet) = s.p1[:places]

"""
$(TYPEDSIGNATURES)
"""
transitions(s::SimpleNet) = s.p1[:trans]

"""
$(TYPEDSIGNATURES)
"""
arcs(s::SimpleNet) = s.p1[:arcs]
"""
$(TYPEDSIGNATURES)
"""
refplaces(s::SimpleNet) = s.p1[:refP]

"""
$(TYPEDSIGNATURES)
"""
reftransitions(s::SimpleNet) = s.p1[:refT]


#---------------------------------------------
# For Stochastic Nets, a transition is not labeled with a boolean condition,
# but with a  floating point rate
#---------------------------------------------


"""
$(TYPEDSIGNATURES)

Return a labelled vector of rate values for net `s`. Key is transition id.
"""
function rates end
rates(s::N) where {T<:PnmlType, N<:PetriNet{T}} = rates(s, transition_ids(s))

function rates(s::N, v::Vector{Symbol}) where {T<:PnmlType, N<:PetriNet{T}}
    LVector( (; [t=>rate(s,t) for t in v]...))
end

"""
$(TYPEDSIGNATURES)

Return rate value of `transition`.
"""
function rate end
function rate(transition)::Number
    r = get_label(transition,:rate)
    
    if (!isnothing(r) && !isnothing(r[:text]) && !isnothing(r[:text][:content]))
        rate = number_value(r[:text][:content])
        isnothing(rate) ? 0.0 : rate
    else
        0.0
    end
end

function rate(s::N, t::Symbol) where {T<:PnmlType, N<:PetriNet{T}}
    rate(transition(s,t))
end

