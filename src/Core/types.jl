# Core types and methods are documented in interfaces.jl.

"""
Alias for Union{`T`, `Nothing`}.
"""
const Maybe{T} = Union{T, Nothing}

"""
Alias for Symbol that refers to something with an ID Symbol.
"""
const REFID = Symbol

#--------------------------------------------------------------------------------------
"""
$(TYPEDEF)

Objects of a Petri Net Graph are pages, arcs, nodes.
"""
abstract type AbstractPnmlObject end

# function Base.getproperty(o::AbstractPnmlObject, prop_name::Symbol)
#     prop_name === :id   && return getfield(o, :id)::Symbol
#     prop_name === :pntd && return getfield(o, :pntd)::PnmlType #! abstract
#     prop_name === :namelabel && return getfield(o, :namelabel)::Maybe{Name}

#     return getfield(o, prop_name)
# end

pid(o::AbstractPnmlObject)        = o.id

#
# When a thing may be nothing, any collection is expected to be non-empty.
# Strings may be empty. Don't blame us when someone else objects.
#
has_name(o::AbstractPnmlObject)   = hasproperty(o, :namelabel) && !isnothing(getfield(o, :namelabel))
name(o::AbstractPnmlObject)       = has_name(o) ? text(o.namelabel) : ""
name(::Nothing) = ""

# labels and tools are vectors: isnothing vs isempty
has_labels(o::AbstractPnmlObject) = hasproperty(o, :labels) && !isnothing(o.labels)
labels(o::AbstractPnmlObject)     = o.labels

has_tools(o::AbstractPnmlObject) = hasproperty(o, :tools) && !isnothing(o.tools)
tools(o::AbstractPnmlObject)     = hasproperty(o, :tools) ? o.tools : nothing

has_graphics(o::AbstractPnmlObject) = hasproperty(o, :graphics) && !isnothing(o.graphics)
graphics(o::AbstractPnmlObject)     = o.graphics

# Jet once needed a hint about `o`.
function has_label(o::AbstractPnmlObject, tag::Union{Symbol, String, SubString{String}})
    (isnothing(o) && error("o is nothing")) ||
        (has_labels(o) && has_label(labels(o), tag))
end

function get_label(o::AbstractPnmlObject, tag::Union{Symbol, String, SubString{String}})
    (isnothing(o) && error("o is nothing")) ||
        (has_labels(o) && get_label(labels(o), tag))
end

"""
    labelof(x, sym::Symbol) -> Maybe{PnmlLabel}

`x` is anyting that supports has_label/get_label,
`tag` is the tag of the xml label element.
"""
function labelof(x, tag::Union{Symbol, String, SubString{String}})
    if has_labels(x)
        l = labels(x)
        return has_label(l, tag) ? @inbounds(get_label(l, tag))::PnmlLabel : nothing
    end
    return nothing
end

#--------------------------------------------
"""
$(TYPEDEF)
Petri Net Graph nodes are [`Place`](@ref), [`Transition`](@ref).
They are the source or target of an [`Arc`](@ref)
"""
abstract type AbstractPnmlNode{PNTD} <: AbstractPnmlObject end

"""
$(TYPEDEF)
For common behavior shared by [`RefPlace`](@ref), [`RefTransition`](@ref)
used to connect [`Page`](@ref) together.
"""
abstract type ReferenceNode <: AbstractPnmlObject end

function Base.getproperty(rn::ReferenceNode, name::Symbol)
    name === :ref && return getfield(rn, :ref)::Symbol
    return getfield(rn, name)
end

refid(r::ReferenceNode) = r.ref

#--------------------------------------------
# """
# $(TYPEDEF)
# Tool specific information objects can be attached to nodes and labels,
# [`AbstractPnmlObject`](@ref)s and [`AbstractLabel`](@ref)s subtypes.
# """
# abstract type AbstractPnmlTool end #TODO see ToolInfo

#=      XMLDict notes

mutable struct XMLDictElement <: AbstractDict{Union{String,Symbol},Any}

DictType is used for xml_dict's dict_type argument.


r = dict_type()
attribute a:  r[Symbol(nodename(a))] = nodecontent(a) #! Symbol key, String value (SubString?)

# The empty-string key holds a vector of sub-elements.
# This is necessary when grouping sub-elements would alter ordering...

for c in eachnode(x)
    if iselement(c)
        n = nodename(c) #! String, SubString as key
        v = xml_dict(c, dict_type; strip_text=strip_text)
        if haskey(r, "")
            push!(r[""], dict_type(n => v)) #! Vector of dicts and strings as value
        elseif haskey(r, n)
            a = isa(r[n], Array) ? r[n] : Any[r[n]] #! turn scalar into vector
            push!(a, v)
            r[n] = a #! Vector value
        else
            r[n] = v #! dict value
        end
    elseif is_text(c) && haskey(r, "")
        push!(r[""], nodecontent(c)) #! String value
    end
end
# Collapse leaf-node vectors containing only text...
if haskey(r, "")
    v = r[""]
    if length(v) == 1 && isa(v[1], AbstractString)
        if strip_text
            v[1] = strip(v[1])
        end
        r[""] = v[1]

        # If "r" contains no other keys, collapse the "" key...
        if length(r) == 1
            r = r[""]
        end
    end

end
values: DictType, String, SubString, Vector{Union{DictType, String, SubString}}
=#


"Dictionary passed to `XMLDict.xml_dict` as `dict_type`. See `unparsed_tag`."
const DictType = LittleDict{Union{Symbol,String}, Any #= XDVT =#}

"XMLDict Value Type is value or Vector of values from `XMLDict.xml_dict`."
const XDVT = Union{DictType, String, SubString, Vector{Union{DictType,String,SubString}}}

tag(d::DictType) = first(keys(d)) # String or Symbol

"""
$(TYPEDSIGNATURES)
Find first :text and return its :content as string.
"""
function text_content end

function text_content(vx::Vector{Any})
    isempty(vx) && throw(ArgumentError("empty `Vector` not expected"))
    text_content(first(vx))
end

function text_content(d::DictType)
    x = get(d, "text", nothing)
    isnothing(x) && throw(ArgumentError("missing <text> element in $(d)"))
    return x
end
text_content(s::Union{String,SubString{String}}) = s

"""
XMLDict uses symbols as keys. Value returned is a string.
"""
function _attribute(vx::DictType, key::Symbol)
    x = get(vx, key, nothing)
    isnothing(x) && throw(ArgumentError("missing $key value"))
    isa(x, AbstractString) ||
        throw(ArgumentError("expected AbstractString got $(typeof(vx[key]))"))
    return x
 end




#--------------------------------------------
# Terms & Sorts
#--------------------------------------------
"""
$(TYPEDEF)
Terms are part of the multi-sorted algebra that is part of a High-Level Petri Net.

An abstract type in the pnml XML specification, concrete `Term`s are variables and operators
found within the <structure> element of a label.

Notably, a `Term` is not a PnmlLabel (or a PNML Label).

# References
See also [`Declaration`](@ref), [`Labels.SortType`](@ref), [`AbstractDeclaration`](@ref).

[Term_(logic)](https://en.wikipedia.org/wiki/Term_(logic)):
> A first-order term is recursively constructed from constant symbols, variables and function symbols.

> Besides in logic, terms play important roles in universal algebra, and rewriting systems.

> more convenient to think of a term as a tree.

> A term that doesn't contain any variables is called a ground term

> When the domain of discourse contains elements of basically different kinds,
> it is useful to split the set of all terms accordingly.
> To this end, a sort (sometimes also called type) is assigned to each variable and each constant symbol,
> and a declaration...of domain sorts and range sort to each function symbol....

[Type_theory](https://en.wikipedia.org/wiki/Type_theory)
> term in logic is recursively defined as a constant symbol, variable, or a function application, where a term is applied to another term

> if t is a term of type σ → τ, and s is a term of type σ, then the application of t to s, often written (t s), has type τ.

[Lambda terms](https://en.wikipedia.org/wiki/Lambda_calculus#Lambda_terms):
> The term redex, short for reducible expression, refers to subterms that can be reduced by one of the reduction rules.

See [Metatheory](https://github.com/JuliaSymbolics/Metatheory.jl)
and [SymbolicUtils](https://github.com/JuliaSymbolics/SymbolicUtils.jl)

"""
abstract type AbstractTerm end

"""
$(TYPEDEF)
Variables are part of the high-level pnml many-sorted algebra.
"""
abstract type AbstractVariable <: AbstractTerm end

"""
$(TYPEDEF)
Operators are part of the high-level pnml many-sorted algebra.

> ...can be a built-in constant or a built-in operator, a multiset operator which among others
> can construct a multiset from an enumeration of its elements, or a tuple operator.
> Each operator has a sequence of sorts as its input sorts, and exactly one output sort,
> which defines its signature.

See [`NamedOperator`](@ref) and [`ArbitraryOperator`](@ref).
"""
abstract type AbstractOperator <: AbstractTerm end

# Expect each operator instance to have fields:
# - definition of expression (PNML Term) that evaluates to an instance of an output sort.
# - ordered sequence of zero or more input sorts #todo vector or tuple?
# - one output sort
# and support methods to:
# - compare operator signatures for equality using sort eqality
# - output sort type to test against place sort type (and others)
#
# Note that a zero input operator is a constant.

#---------------------------------------------------------------------------
# Collect the Singleton to Type translations here.
# The part that needs to know Type details is defined elsewhere. :)
#---------------------------------------------------------------------------

pnmlnet_type(pntd::PnmlType)       = pnmlnet_type(typeof(pntd))
page_type(pntd::PnmlType)          = page_type(typeof(pntd))

place_type(pntd::PnmlType)         = place_type(typeof(pntd))
transition_type(pntd::PnmlType)    = transition_type(typeof(pntd))
arc_type(pntd::PnmlType)           = arc_type(typeof(pntd))
refplace_type(pntd::PnmlType)      = refplace_type(typeof(pntd))
reftransition_type(pntd::PnmlType) = reftransition_type(typeof(pntd))

marking_type(pntd::PnmlType)       = marking_type(typeof(pntd))
marking_value_type(pntd::PnmlType) = marking_value_type(typeof(pntd))

condition_type(pntd::PnmlType)       = condition_type(typeof(pntd))
condition_value_type(pntd::PnmlType) = condition_value_type(typeof(pntd))

inscription_type(pntd::PnmlType)       = inscription_type(typeof(pntd))
inscription_value_type(pntd::PnmlType) = inscription_value_type(typeof(pntd))

coordinate_type(pntd::PnmlType)       = coordinate_type(typeof(pntd))
coordinate_value_type(pntd::PnmlType) = coordinate_value_type(typeof(pntd))

#---------------------------------------------------------------------------
# Extend by allowing a transition to be labeled with a floating point rate.
#---------------------------------------------------------------------------
"""
    rate_value_type(::PnmlType) -> Number
    rate_value_type(::Type{<:PnmlType}) -> Number

Return rate value type based on net type.
"""
function rate_value_type end

rate_value_type(pntd::PnmlType) = rate_value_type(typeof(pntd))
rate_value_type(::Type{<:PnmlType}) = Float64

####################################################################
# """
#     SubstitutionDict = OrderderDict{REFID, Multiset}

# Variable ID used to access marking value. One for each variable of a transition.

# A higher level will produce candidate consistent substitution dictionaries,
# filtering them by one or more guards. `Condition` callable object guards are part of
# selecting enabled transition => subsitution dictionary firing pairs.
# The firing rule selects one of the firing pairs, using the substitution dictionary to
# construct postset marking updates.
# """
# const SubstitutionDict = OrderedDict{REFID, Multiset}
