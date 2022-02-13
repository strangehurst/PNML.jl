include("types.jl")
include("graphics.jl")
include("common.jl")
include("markings.jl")
include("conditions.jl")
include("inscriptions.jl")
include("declarations.jl")

#-------------------
"""
PNML Place node.

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
PNML Transition node.

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
PNML RefPlace node.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefPlace <: PnmlNode
    id::Symbol
    ref::Symbol
    com::ObjectCommon
end

RefPlace(pdict::PnmlDict) = RefPlace(pdict[:id], pdict[:ref], ObjectCommon(pdict))

#-------------------
"""
PNML RefTransition node.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct RefTransition <: PnmlNode
    id::Symbol
    ref::Symbol
    com::ObjectCommon
end

RefTransition(pdict::PnmlDict) =
    RefTransition(pdict[:id], pdict[:ref], ObjectCommon(pdict))

#-------------------
"""
Edge of graph that connects place and transition.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
mutable struct Arc <: PnmlObject
    id::Symbol
    source::Symbol
    target::Symbol
    inscription::Maybe{Inscription} #TODO Abstract, could br a Union.
    com::ObjectCommon
end

Arc(pdict::PnmlDict) =
    Arc(pdict[:id], pdict[:source], pdict[:target], pdict[:inscription], ObjectCommon(pdict))

Arc(a::Arc, src::Symbol, tgt::Symbol) = Arc(a.id, src, tgt, a.inscription, a.com)

###############################################################################
# Begin section dealing with the top level of a pnml model: nets, pages and
# labels at equivalent level of the model. 
###############################################################################
#-------------------
"""
Contain all places, transitions & arcs. They are for visual presentation.
There must be at least 1 Page for a valid pnml model.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct Page{PNTD<:PnmlType} <: PnmlObject
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
Each net in a PNML model has an independent type.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlNet{PNTD<:PnmlType}
    id::Symbol
    type::PNTD
    pages::Vector{Page}
    declarations::Vector{Declaration}

    com::ObjectCommon
    xml::XMLNode
end

function PnmlNet(d::PnmlDict, xml::XMLNode)
    PnmlNet(d[:id], d[:type], d[:pages], d[:declarations], ObjectCommon(d), xml)
end

pid(net::PnmlNet) = net.id
has_labels(net::PnmlNet) = has_labels(net.com)
has_xml(net::PnmlNet) = true
xmlnode(net::PnmlNet) = net.xml

"Usually the only interesting page."
firstpage(net::PnmlNet) = net.pages[1]

#-------------------
"""
A PNML model can have multiple net elements.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PnmlModel
    nets::Vector{PnmlNet} #TODO Vector{PetriNet}
    reg::IDRegistry # Shared by all nets.
    xml::XMLNode
end
PnmlModel(net::PnmlNet) = PnmlModel([net])
PnmlModel(nets::Vector{PnmlNet}) = PnmlModel(nets, IDRegistry(), nothing)
PnmlModel(nets::Vector{PnmlNet}, reg::IDRegistry) = PnmlModel(nets, reg, nothing)

has_xml(model::PnmlModel) = true
xmlnode(model::PnmlModel) = model.xml

"""
Build a PnmlModel from a string ontaining XML.

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
function parse_str(str::AbstractString)
    reg = IDRegistry()
    parse_pnml(root(EzXML.parsexml(str)); reg)
end

"""
Build a PnmlModel from a file containing XML.

$(TYPEDSIGNATURES)
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
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function find_nets end
find_nets(model, type::AbstractString) = find_nets(model, PnmlTypes.pntd_symbol(type))
find_nets(model, type::Symbol) = find_nets(model, PnmlTypes.pnmltype(type))
find_nets(model, type::T) where {T <: PnmlType} =
    filter(n->typeof(n.type) <: T, nets(model))


"""
Return `PnmlNet` with `id` or `nothing``.
"""
function find_net end

function find_net(model, id::Symbol)
    i = findfirst(nets(model)) do net
        pid(net) === id
    end
    isnothing(i) ? nothing : nets[i]
end

"""
Return first net contained by `doc`.

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
first_net(model) = first(nets(model))

"""
Return all `nets` of `model`.

$(TYPEDSIGNATURES)
$(METHODLIST)
"""
nets(model::PnmlModel) = model.nets

###############################################################################
#
###############################################################################
