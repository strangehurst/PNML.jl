"""
Petri Net Type Definition (pntd) URI mapped to PnmlType subtype singleton.


# Imports
$(DocStringExtensions.IMPORTS)

# Exports
$(DocStringExtensions.EXPORTS)
"""
module PnmlTypeDefs

#using PNML
using DocStringExtensions

# Abstract Types
export PnmlType,
       AbstractPnmlCore,
       AbstractHLCore,
       AbstractContinuousNet

# Singletons (concrete types)
export PnmlCore, PTNet,
       HLCore, PT_HLPNG, SymmetricNet, HLPNG,
       StochasticNet, TimedNet, OpenNet,
       ContinuousNet

# Functions
export pnmltype, pntd_symbol

"""
$(TYPEDEF)

Abstract root of a dispatch type based on Petri Net Type Definition (pntd).

Each Petri Net Markup Language (PNML) network element will have a single pntd URI
as a required 'type' XML attribute. That URI should refer to a RelaxNG schema defining
the syntax and semantics of the XML model.

Selected abbreviations, URIs that do not resolve to a valid schema file, are also allowed.

Refer to [`pntd_symbol`](@ref) and [`pnmltype`](@ref) for how to get from the URI to a singleton.
"""
abstract type PnmlType end

"""
$(TYPEDEF)
Base of token/integer-based Petri Net pntds.

See [`PnmlCore`](@ref), [`PTNet`](@ref) and others.
"""
abstract type AbstractPnmlCore <: PnmlType end

"""
$(TYPEDEF)
The most minimal concrete Petri Net.

Used to implement and test the core PNML support.
Covers the complete graph infrastructure including labels attached to nodes and arcs.
"""
struct PnmlCore <: AbstractPnmlCore end

"""
$(TYPEDEF)
Place-Transition Petri Nets add small extensions to core PNML.
Integer-valued initialMarking and inscription.

The grammer file is ptnet.pnml so we name it PTNet.
Note that 'PT' is often the prefix for XML tags specialized for this net type.
"""
struct PTNet <: AbstractPnmlCore end

"""
$(TYPEDEF)
Base of High Level Petri Net pntds which add large extensions to PNML core.
hlinitialMarking, hlinscription, and defined label structures.

See [`HLCore`](@ref), [`SymmetricNet`](@ref), [`PT_HLPNG`](@ref) and others.
"""
abstract type AbstractHLCore <: PnmlType end

"""
$(TYPEDEF)
`HLCore` can be used for generic high-level nets.
We try to implement and test all function at `PnmlCore` level, but
expect to find use for a concrete type at this level for testing high-level extensions.
"""
struct HLCore <: AbstractHLCore end

"""

$(TYPEDEF)
High-Level Petri Net Graphs (HLPNGs) are the most intricate High-Level Petri Net schema.
It extends [`SymmetricNet`](@ref), including with
   - declarations for sorts and functions (ArbitraryDeclarations)
   - sorts for Integer, String, and List
"""
struct HLPNG <: AbstractHLCore end

"""
$(TYPEDEF)
Place-Transition Net in HLCore notation.
"""
struct PT_HLPNG <: AbstractHLCore end

"""
$(TYPEDEF)
Symmetric Petri Net is the best-worked use case in the `primer`
and ISO specification part 2.
"""
struct SymmetricNet <: AbstractHLCore end

"""
$(TYPEDEF)
Uses floating point numbers for markings, inscriptions.
Most of the functionality is shared with [`AbstractPnmlCore`](@ref).
This seperates the
"""
abstract type AbstractContinuousNet <: PnmlType end

"""
$(TYPEDEF)
TODO: Continuous Petri Net
Concrete type.
"""
struct ContinuousNet <: AbstractContinuousNet end

"""
TODO: Open Petri Net

$(TYPEDEF)
"""
struct OpenNet <: AbstractContinuousNet end

"""
TODO: Stochastic Petri Net

$(TYPEDEF)
"""
struct StochasticNet <: AbstractHLCore end

"""
TODO: Timed Petri Net

$(TYPEDEF)
"""
struct TimedNet <: AbstractHLCore end

#----------------------------------------------------------------------------------------

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
const default_pntd_map = Dict{String, Symbol}("http://www.pnml.org/version-2009/grammar/ptnet" => :ptnet,
                                              "http://www.pnml.org/version-2009/grammar/highlevelnet" => :hlnet,
                                              "http://www.pnml.org/version-2009/grammar/pnmlcoremodel" => :pnmlcore,
                                              "http://www.pnml.org/version-2009/grammar/pnmlcore" => :pnmlcore,
                                              "http://www.pnml.org/version-2009/grammar/pt-hlpng" => :pt_hlpng,
                                              "http://www.pnml.org/version-2009/grammar/symmetricnet" => :symmetric,
                                              "pnmlcore" => :pnmlcore,
                                              "ptnet" => :ptnet,
                                              "hlnet" => :hlnet,
                                              "hlcore" => :hlcore,
                                              "pt-hlpng" => :pt_hlpng,
                                              "pt_hlpng" => :pt_hlpng,
                                              "symmetric" => :symmetric,
                                              "symmetricnet" => :symmetric,
                                              # extensions
                                              "stochastic" => :stochastic,
                                              "timed" => :timednet,
                                              "nonstandard" => :pnmlcore,
                                              "open" => :pnmlcore,
                                              "continuous" => :continuous)

"""
$(TYPEDEF)

The key Symbols are the supported kinds of Petri Nets.
"""
const pnmltype_map = IdDict{Symbol, PnmlType}(:pnmlcore => PnmlCore(),
                                            :hlcore => HLCore(),
                                            :ptnet => PTNet(),
                                            :hlnet => HLPNG(),
                                            :pt_hlpng => PT_HLPNG(),
                                            :symmetric => SymmetricNet(),
                                            :stochastic => StochasticNet(),
                                            :timednet => TimedNet(),
                                            :continuous => ContinuousNet())

"""
$(TYPEDSIGNATURES)

Add or replace mapping from symbol `s` to nettype dispatch singleton `t`.
"""
add_nettype!(dict::AbstractDict, s::Symbol, pntd::PnmlType) = dict[s] = pntd #! test this

"""
$(TYPEDSIGNATURES)

Map string `s` to a pntd symbol using [`default_pntd_map`](@ref).
Any unknown `s` is mapped to `:pnmlcore`.
Returned symbol is suitable for [`pnmltype`](@ref) to use to index into [`pnmltype_map`](@ref).

# Examples

```jldoctest; setup=:(using PNML)
julia> PnmlTypeDefs.pntd_symbol("foo")
:pnmlcore
```
"""
pntd_symbol(s::String) = get(default_pntd_map::Dict{String, Symbol}, s, :pnmlcore)

"""
    pnmltype(pntd::T; kw...)
    pnmltype(uri::AbstractString; kw...)
    function pnmltype(s::Symbol; pnmltype_map=pnmltype_map, kw...)

Map either a text string or a symbol to a dispatch type singlton.

While that string may be a URI for a pntd, we treat it as a simple string without parsing.
The [`PnmlTypeDefs.pnmltype_map`](@ref) and [`PnmlTypeDefs.default_pntd_map`](@ref) are both assumed to be correct here.

Unknown or empty `uri` will map to symbol `:pnmlcore`.
Unknown `symbol` throws a `DomainError` exception.

# Examples

```jldoctest; setup=:(using PNML; using PNML.PnmlTypeDefs: pnmltype, pntd_symbol)
julia> pnmltype(PnmlCore())
PnmlCore()

julia> pnmltype("nonstandard")
PnmlCore()

julia> pnmltype(:symmetric)
SymmetricNet()
```
"""
function pnmltype end
pnmltype(pntd::PnmlType; kw...) = pntd
pnmltype(uri::AbstractString; kw...) = pnmltype(pntd_symbol(uri))
function pnmltype(s::Symbol)
    typemap = pnmltype_map::IdDict{Symbol, PnmlType}
    !haskey(typemap, s) && throw(DomainError("Unknown PNTD symbol $s"))
    @inbounds typemap[s]
end

end # module PnmlTypeDefs
