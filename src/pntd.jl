# Kinds of Petri Nets: PNTD URI mapped to PnmlType singleton.

"""
$(TYPEDEF)

Abstract root of a dispatch type based on Petri Net Type Definition (pntd).

Each Petri Net Markup Language (PNML) network element will have a single pntd URI
as a required 'type' XML attribute. That URI should refer to a RelaxNG schema defining
the syntax and semantics of the XML model.

Selected abbreviations, URIs that do not resolve to a valid schema file, are also allowed.

Refer to [`pntd`](@ref) and [`pnmltype`](@ref) for how to get from the URI to a singleton.
"""
abstract type PnmlType end

"""
$(TYPEDEF)

Most minimal Petri Net type that is the foundation of all pntd.
"""
abstract type AbstractPnmlCore <: PnmlType end
"""
$(TYPEDEF)

Base of High Level Petri Net pntds.
"""
abstract type AbstractHLCore <: AbstractPnmlCore end


"""
$(TYPEDEF)

PnmlCore is the most minimal concrete Petri Net.
"""
struct PnmlCore <: AbstractPnmlCore end

"""
$(TYPEDEF)

Place-Transition Petri Nets add small extensions to core.
"""
struct PTNet <: AbstractPnmlCore end

"""
$(TYPEDEF)

High-Level Petri Nets add large extensions to core, can be used for generic high-leve nets.
"""
struct HLCore <: AbstractHLCore end

"""
$(TYPEDEF)

Place-Transition High-Level Petri Net Graph
"""
struct PT_HLPNG <: AbstractHLCore end

"""
$(TYPEDEF)

Symmetric Petri Net
"""
struct SymmetricNet <: AbstractHLCore end

"""
$(TYPEDEF)

Stochastic Petri Net
"""
struct StochasticNet <: AbstractHLCore end

"""
$(TYPEDEF)

Timed Petri Net
"""
struct TimedNet <: AbstractHLCore end

"""
$(TYPEDEF)

Open Petri Net
"""
struct OpenNet <: AbstractHLCore end

"""
$(TYPEDEF)

HLNet is the most intricate High-Level Petri Net schema
"""
struct HLNet <: AbstractHLCore end



"""
$(TYPEDEF)

Map from Petri Net Type Definition (pntd) URI to Symbol.

There is a companion map [`pnmltype_map`](@ref) that takes the symbol to a type object.

The URI is a string and may be the full URL of a pntd schema,
just the schema file name, or a placeholder for a future schema.

# Examples

The 'pntd symbol' should match the name used in the URI with inconvinient characters
removed or replaced. For example, '-' is replaced by '_'.
"""
const default_pntd_map = Dict{AbstractString,Symbol}(
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

The keys are the supported kinds of Petri Nets.

Provides a place to abstract relationship of pntd name and implementation type.
Allows multiple strings to map to the same parser implementation.
Is a point at which different parser implmentations may be introduced.

# Examples
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
$(TYPEDSIGNATURES)

Add or replace mapping from symbol `s` to nettype dispatch singleton `t`.
"""
add_nettype!(d::AbstractDict, s::Symbol, t::T) where {T<:PnmlType} = d[s] = t #TODO test this


"""
$(TYPEDSIGNATURES)

Map string `s` to a pntd symbol using [`default_pntd_map`](@ref).
Any unknown `s` is mapped to `:pnmlcore`.
Returned symbol is suitable for [`pnmltype`](@ref) to use to index into [`pnmltype_map`](@ref).

# Examples

```jldoctest
julia> using PNML #hide
```
"""
pntd(s::AbstractString) = haskey(default_pntd_map,s) ? default_pntd_map[s] : :pnmlcore

"""
$(TYPEDSIGNATURES)

Map either a text string or a symbol to a dispatch type singlton.

While that string may be a URI for a pntd, we treat it as a simple string without parsing.
The [`pnmltype_map`](@ref) and [`default_pntd_map`](@ref) are both assumed to be correct here.

Unknown or empty `uri` will map to symbol `:pnmlcore` as part of the logic.
Unknown `symbol` returns `nothing`.
"""
function pnmltype end
pnmltype(t::T; kw...) where {T<:PnmlType} = t
pnmltype(uri::AbstractString; kw...) = pnmltype(pntd(uri); kw...)
pnmltype(d::PnmlDict; kw...) = pnmltype(d[:type]; kw...)

function pnmltype(s::Symbol; pnmltype_map=pnmltype_map, kw...)
    if haskey(pnmltype_map, s)
        return pnmltype_map[s]
    else
        @debug "Unknown PNTD symbol $s"
        return nothing
    end
end
