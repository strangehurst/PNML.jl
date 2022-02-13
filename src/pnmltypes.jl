"""
Kinds of Petri Nets: PNTD URI mapped to PnmlType singleton.

# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PnmlTypes
using DocStringExtensions

export PnmlType, 
    PnmlCore, PTNet,
    AbstractHLCore, HLCore, HLNet, StochasticNet,
    SymmetricNet, TimedNet, OpenNet, PT_HLPNG 


"""
Abstract root of a dispatch type based on Petri Net Type Definition (pntd).

Each Petri Net Markup Language (PNML) network element will have a single pntd URI
as a required 'type' XML attribute. That URI should refer to a RelaxNG schema defining
the syntax and semantics of the XML model.

Selected abbreviations, URIs that do not resolve to a valid schema file, are also allowed.

Refer to [`pntd_symbol`](@ref) and
[`pnmltype`](@ref) for how to get from the URI to a singleton.

$(TYPEDEF)
"""
abstract type PnmlType end

"""
Base of High Level Petri Net pntds.

$(TYPEDEF)
"""
abstract type AbstractHLCore <: PnmlType end

"""
PnmlCore is the most minimal concrete Petri Net.

$(TYPEDEF)
"""
struct PnmlCore <: PnmlType end

"""
Place-Transition Petri Nets add small extensions to core.

$(TYPEDEF)
"""
struct PTNet <: PnmlType end

"""
High-Level Petri Nets add large extensions to core, can be used for generic high-level nets.

$(TYPEDEF)
"""
struct HLCore <: AbstractHLCore end

"""
Place-Transition High-Level Petri Net Graph

$(TYPEDEF)
"""
struct PT_HLPNG <: AbstractHLCore end

"""
Symmetric Petri Net

$(TYPEDEF)
"""
struct SymmetricNet <: AbstractHLCore end

"""
Stochastic Petri Net

$(TYPEDEF)
"""
struct StochasticNet <: AbstractHLCore end

"""
Timed Petri Net

$(TYPEDEF)
"""
struct TimedNet <: AbstractHLCore end

"""
Open Petri Net

$(TYPEDEF)
"""
struct OpenNet <: AbstractHLCore end

"""
HLNet is the most intricate High-Level Petri Net schema

$(TYPEDEF)
"""
struct HLNet <: AbstractHLCore end



"""
$(TYPEDEF)

Map from Petri Net Type Definition (pntd) URI to Symbol.
Allows multiple strings to map to the same pntd.

There is a companion map [`pnmltype_map`](@ref) that takes the symbol to a type object.

The URI is a string and may be the full URL of a pntd schema,
just the schema file name, or a placeholder for a future schema.


# Examples

The 'pntd symbol' should match the name used in the URI with inconvinient characters
removed or replaced. For example, '-' is replaced by '_'.
"""
const default_pntd_map = Dict{AbstractString, Symbol}(
    "http://www.pnml.org/version-2009/grammar/ptnet" => :ptnet,
    "http://www.pnml.org/version-2009/grammar/highlevelnet" => :hlnet,
    "http://www.pnml.org/version-2009/grammar/pnmlcoremodel" => :pnmlcore,
    "http://www.pnml.org/version-2009/grammar/pnmlcore" => :pnmlcore,
    "http://www.pnml.org/version-2009/grammar/pt-hlpng" => :pt_hlpng,
    "http://www.pnml.org/version-2009/grammar/symmetricnet" => :symmetric,
    "pnmlcore"   => :pnmlcore,
    "ptnet"      => :ptnet,
    "hlcore"     => :hlcore,
    "pt-hlpng"   => :pt_hlpng,
    "pt_hlpng"   => :pt_hlpng,
    "symmetric"  => :symmetric,
    "symmetricnet" => :symmetric,
    "stochastic"   => :stochastic,
    "timed"        => :timednet,
    "nonstandard"  => :pnmlcore,
    "open"         => :pnmlcore
    )

"""
$(TYPEDEF)

The key Symbols are the supported kinds of Petri Nets.
"""
const pnmltype_map = Dict{Symbol, PnmlType}(
    :pnmlcore   => PnmlCore(),
    :hlcore     => HLCore(),
    :ptnet      => PTNet(),
    :hlnet      => HLNet(),
    :pt_hlpng   => PT_HLPNG(),
    :symmetric  => SymmetricNet(),
    :stochastic => StochasticNet(),
    :timednet   => TimedNet(),
    )

"""
Add or replace mapping from symbol `s` to nettype dispatch singleton `t`.

$(TYPEDSIGNATURES)
"""
add_nettype!(dict::AbstractDict, s::Symbol, pntd::T) where {T<:PnmlType} =
    dict[s] = pntd #TODO test this


"""
Map string `s` to a pntd symbol using [`default_pntd_map`](@ref).
Any unknown `s` is mapped to `:pnmlcore`.
Returned symbol is suitable for [`pnmltype`](@ref) to use to index into [`pnmltype_map`](@ref).

$(TYPEDSIGNATURES)

# Examples

```jldoctest
julia> using PNML: PnmlTypes.pntd_symbol

julia> pntd_symbol("foo")
:pnmlcore
```
"""
pntd_symbol(s::AbstractString) = get(default_pntd_map, s, :pnmlcore)

"""
Map either a text string or a symbol to a dispatch type singlton.

While that string may be a URI for a pntd, we treat it as a simple string without parsing.
The [`PnmlTypes.pnmltype_map`](@ref) and [`PnmlTypes.default_pntd_map`](@ref) are both assumed to be correct here.

Unknown or empty `uri` will map to symbol `:pnmlcore` as part of the logic.
Unknown `symbol` returns `nothing`.

# Examples

```jldoctest
julia> using PNML, PNML.PnmlTypes

julia> PnmlTypes.pnmltype("nonstandard")
PnmlCore()
```
---
$(TYPEDSIGNATURES)

$(METHODLIST)
"""
function pnmltype end
pnmltype(pntd::T; kw...) where {T<:PnmlType} = pntd
pnmltype(uri::AbstractString; kw...) = pnmltype(pntd_symbol(uri); kw...)
function pnmltype(s::Symbol; pnmltype_map=pnmltype_map, kw...)
    if haskey(pnmltype_map, s)
        return pnmltype_map[s]
    else
        @warn "Unknown PNTD symbol $s"
        return nothing
    end
end
end # module PnmlTypes
