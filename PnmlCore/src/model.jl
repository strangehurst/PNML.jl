"""
$(TYPEDEF)
$(TYPEDFIELDS)

One or more Petri Nets and an ID Registry shared by all nets.
"""
struct PnmlModel
    nets::Vector{PnmlNet} #! Yes it is abstract.
    namespace::String
    reg::PnmlIDRegistry # Shared by all nets.
    xml::XMLNode #! NOT USED?
end

"""
$(TYPEDSIGNATURES)
"""

PnmlModel(net::PnmlNet) = PnmlModel([net])
PnmlModel(nets::Vector{PnmlNet}) = PnmlModel(nets, pnml_ns, PnmlIDRegistry(), nothing)
PnmlModel(nets::Vector{PnmlNet}, ns, reg::PnmlIDRegistry) = PnmlModel(nets, ns, reg, nothing)

"""
$(TYPEDSIGNATURES)

Return all `nets` of `model`.
"""
nets(model::PnmlModel) = model.nets
namespace(model::PnmlModel) = model.namespace
idregistry(model::PnmlModel) = model.reg
xmlnode(model::PnmlModel) = model.xml


"""
$(TYPEDSIGNATURES)
Return nets matching pntd `type` given as string, symbol or pnmltype singleton.
See [`PnmlTypeDefs.pntd_symbol`](@ref), [`PnmlTypeDefs.pnmltype`](@ref).
"""
function find_nets end
find_nets(model, type::AbstractString) = find_nets(model, pntd_symbol(type))
find_nets(model, type::Symbol) = find_nets(model, pnmltype(type))
find_nets(model, pntd::PnmlType) = filter(n -> isa(n.type, typeof(pntd)), nets(model))
#find_nets(model, pntd::PnmlType) = filter(Fix2(isa, typeof(pntd)), nets(model))

"""
$(TYPEDSIGNATURES)

Return `PnmlNet` having `id` or `nothing``.
"""
function find_net end

function find_net(model, id::Symbol)
    getfirst(Fix2(haspid, id), nets(model))
end

"""
$(TYPEDSIGNATURES)

Return first net contained by `doc`.
"""
first_net(model) = first(nets(model))
