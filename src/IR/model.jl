"""
$(TYPEDEF)
$(TYPEDFIELDS)

One or more Petri Nets and an ID Registry shared by all nets.
"""
struct PnmlModel
    nets::Vector{PnmlNet}
    namespace::String
    reg::IDRegistry # Shared by all nets.
    xml::XMLNode
end

"""
$(TYPEDSIGNATURES)
"""
PnmlModel(net::PnmlNet) = PnmlModel([net])
PnmlModel(nets::Vector{PnmlNet}) = PnmlModel(nets, pnml_ns, IDRegistry(), nothing)
PnmlModel(nets::Vector{PnmlNet}, ns, reg::IDRegistry) = PnmlModel(nets, ns, reg, nothing)

has_xml(model::PnmlModel) = true
xmlnode(model::PnmlModel) = model.xml
namespace(model::PnmlModel) = model.namespace

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a string containing XML.
"""
function parse_str(str::AbstractString)
    reg = IDRegistry()
    # Good place for debugging.  
    parse_pnml(root(EzXML.parsexml(str)); reg)
end

"""
$(TYPEDSIGNATURES)

Build a PnmlModel from a file containing XML.
"""
function parse_file(fname::AbstractString)
    reg = IDRegistry()
    parse_pnml(root(EzXML.readxml(fname)); reg)
end

"""
$(TYPEDSIGNATURES)
Return nets matching pntd `type` given as string or symbol.
See [`PnmlTypes.pntd_symbol`](@ref), [`PnmlTypes.pnmltype`](@ref).
"""
function find_nets end
find_nets(model, type::AbstractString) = find_nets(model, PnmlTypes.pntd_symbol(type))
find_nets(model, type::Symbol) = find_nets(model, PnmlTypes.pnmltype(type))
find_nets(model, type::PNTD) where {PNTD <: PnmlType} =
    filter(n->typeof(n.type) <: PNTD, nets(model))

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing``.
"""
function find_net end

function find_net(model, id::Symbol)
    i = findfirst(net->pid(net) === id, nets(model))
    isnothing(i) ? nothing : nets[i]
end

"""
$(TYPEDSIGNATURES)

Return first net contained by `doc`.
"""
first_net(model) = first(nets(model))

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.
"""
nets(model::PnmlModel) = model.nets
