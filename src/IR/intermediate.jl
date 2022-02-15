include("types.jl")
include("graphics.jl")
include("common.jl")
include("markings.jl")
include("conditions.jl")
include("inscriptions.jl")
include("declarations.jl")

#-------------------
"""
Place node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Place <: PnmlNode
    id::Symbol
    marking::Maybe{Marking}
    type::Maybe{PnmlLabel}

    com::ObjectCommon
end

Place(pdict::PnmlDict) =
    Place(pdict[:id], pdict[:marking], pdict[:type], ObjectCommon(pdict))

    #-------------------
"""
Transition node of a Petri Net Markup Language graph.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Transition <: PnmlNode
    id::Symbol
    condition::Maybe{Condition}

    com::ObjectCommon
end

Transition(pdict::PnmlDict) =
    Transition(pdict[:id], pdict[:condition], ObjectCommon(pdict))

#-------------------
"""
Edge of a Petri Net Markup Language graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc <: PnmlObject
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::Maybe{Inscription} #TODO Abstract, could br a Union.
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

"""
$(TYPEDSIGNATURES)
"""
Arc(pdict::PnmlDict) =
    Arc(pdict[:id], pdict[:source], pdict[:target], pdict[:inscription], ObjectCommon(pdict))

"""
$(TYPEDSIGNATURES)
"""
Arc(a::Arc, src::Symbol, tgt::Symbol) = Arc(a.id, src, tgt, a.inscription, a.com)

#-------------------
"""
Reference Place node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefPlace <: PnmlNode
    id::Symbol
    ref::Symbol # Place or RefPlace
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

RefPlace(pdict::PnmlDict) = RefPlace(pdict[:id], pdict[:ref], ObjectCommon(pdict))

#-------------------
"""
Refrence Transition node of a Petri Net Markup Language graph. For connections between pages.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition <: PnmlNode
    id::Symbol
    ref::Symbol # Transition or RefTransition
    com::ObjectCommon
    #TODO Enforce constraints in constructor? (see ocl in Primer's UML)
end

"""
$(TYPEDSIGNATURES)
"""
RefTransition(pdict::PnmlDict) =
    RefTransition(pdict[:id], pdict[:ref], ObjectCommon(pdict))

###############################################################################
# Begin section dealing with the top level of a pnml model: nets, pages and
# labels at equivalent level of the model. 
###############################################################################
#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

Contain all places, transitions & arcs. Pages are for visual presentation.
There must be at least 1 Page for a valid pnml model.
"""
struct Page{T<:PnmlType} <: PnmlObject
    id::Symbol
    places::Vector{Place}
    refPlaces::Vector{RefPlace}
    transitions::Vector{Transition}
    refTransitions::Vector{RefTransition}
    arcs::Vector{Arc}
    declarations::Vector{Declaration}
    subpages::Maybe{Vector{Page}}
    com::ObjectCommon
    #xml::XMLNode
end

"""
$(TYPEDSIGNATURES)
"""
function Page(d::PnmlDict, pntd = PnmlCore())
    Page{typeof(pntd)}(
        d[:id],
        d[:places], d[:refP],
        d[:trans], d[:refT],
        d[:arcs],
        d[:declarations],
        d[:pages],
        ObjectCommon(d))
end

function Base.empty!(page::Page)
    empty!(page.places)
    empty!(page.refPlaces)
    empty!(page.transitions)
    empty!(page.refTransitions)
    empty!(page.arcs)
    empty!(page.declarations)
    !isnothing(page.subpages) && empty!(page.subpages)
    #TODO empty common
end

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

One Petri Net of a PNML model.
"""
struct PnmlNet{T<:PnmlType}
    id::Symbol
    type::T
    pages::Vector{Page}
    declarations::Vector{Declaration}

    com::ObjectCommon
    xml::XMLNode
end

"""
$(TYPEDSIGNATURES)
"""
function PnmlNet(d::PnmlDict, pntd::T, xml::XMLNode) where {T<:PnmlType}
    PnmlNet(d[:id], pntd, d[:pages], d[:declarations], ObjectCommon(d), xml)
end

pid(net::PnmlNet) = net.id
has_labels(net::PnmlNet) = has_labels(net.com)
has_xml(net::PnmlNet) = true
xmlnode(net::PnmlNet) = net.xml

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]

#-------------------
"""
$(TYPEDEF)
$(TYPEDFIELDS)

PNML model holds one or more Petri Nets and an ID Registry shared by al nets.
"""
struct PnmlModel
    nets::Vector{PnmlNet} #TODO Vector{PetriNet}
    reg::IDRegistry # Shared by all nets.
    xml::XMLNode
end

"""
$(TYPEDSIGNATURES)
"""
PnmlModel(net::PnmlNet) = PnmlModel([net])
PnmlModel(nets::Vector{PnmlNet}) = PnmlModel(nets, IDRegistry(), nothing)
PnmlModel(nets::Vector{PnmlNet}, reg::IDRegistry) = PnmlModel(nets, reg, nothing)

has_xml(model::PnmlModel) = true
xmlnode(model::PnmlModel) = model.xml

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a string ontaining XML.

$(METHODLIST)
"""
function parse_str(str::AbstractString)
    reg = IDRegistry()
    # Good place for debugging.  
    parse_pnml(root(EzXML.parsexml(str)); reg)
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a file containing XML.

$(METHODLIST)
"""
function parse_file(fname::AbstractString)
    reg = IDRegistry()
    parse_pnml(root(EzXML.readxml(fname)); reg)
end

"""
Return nets matching pntd `type` given as string or symbol.
See [`PnmlTypes.pntd_symbol`](@ref), [`PnmlTypes.pnmltype`](@ref).

---
"""
function find_nets end
find_nets(model, type::AbstractString) = find_nets(model, PnmlTypes.pntd_symbol(type))
find_nets(model, type::Symbol) = find_nets(model, PnmlTypes.pnmltype(type))
find_nets(model, type::T) where {T <: PnmlType} =
    filter(n->typeof(n.type) <: T, nets(model))


"""
$(TYPEDSIGNATURES)

Return `PnmlNet` with `id` or `nothing``.

$(METHODLIST)
"""
function find_net end

function find_net(model, id::Symbol)
    i = findfirst(nets(model)) do net
        pid(net) === id
    end
    isnothing(i) ? nothing : nets[i]
end

"""
$(TYPEDSIGNATURES)

Return first net contained by `doc`.

$(METHODLIST)
"""
first_net(model) = first(nets(model))

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.

$(METHODLIST)
"""
nets(model::PnmlModel) = model.nets

###############################################################################
#
###############################################################################
