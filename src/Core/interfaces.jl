# Declare & Document interface functions of PNML.jl
# Any method defined in this file should operate on `Any`.

"""
    pid(x) -> Symbol

Return pnml id symbol of `x`. An id's value is unique in the XML model of PNML.
[`REFID`](@ref) is used for refrences to pnml ids.
"""
function pid end

"""
    tag(x) -> Symbol

Return tag symbol. Multiple objects may hold the same tag value.
Often used to refer to an XML tag.
"""
function tag end


"""
    refid(x) -> REFID

Return reference id symbol. Multiple objects may hold the same refid value.
"""
function refid end

"""
    has_name(x) -> Bool

Return true if there is a name.
Some declarations (inside a label) have a name.
Nodes (nets, pages, places, transitions, arcs) may optionally have a name (as a label).
"""
function has_name end

"""
    name(x) -> String

Return name String. Default to empty string.
"""
function name end

#-------------------------------------------------------
# LABELS #TODO move to module
#-------------------------------------------------------

"""
    has_labels(x) -> Bool

Does x have any labels.
"""
function has_labels end

"""
    labels(x) -> Iterateable
    labels(x, tag::Union{Symbol, String, SubString{String}) -> Iterateable

Return iterator of labels attached to `x`.
"""
function labels end

"""
    has_label(x, tag::Union{Symbol, String, SubString{String}) -> Bool

Does `x` have any label with a matching `tag`.
"""
function has_label end

"""
    get_label(x, tag::Symbol) -> PnmlLabel

Return first label of `x` with a matching `tagvalue`.
"""
function get_label end

function toolinfos end

#--------------------------------------------
#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return the [`PnmlType`](@ref) subtype representing the flavor (or pntd) of this kind of
Petri Net Graph.

See also [`pnmltype`](@ref PnmlTypes.pnmltype)
"""
function nettype end

"""
    pages(net::PnmlLabel|page::Page) -> iterator

Return iterator of pages directly owned by that object.

See [`allpages`](@ref) for an iterator over all pages in the PNML network model.
When there is only one `page` in the `net`, or all pages are owned by the 'net' itself,
'allpages' and 'pages` behave the same.

Maintains order (insertion order).
"""
function pages end

"""
    netdata(x) -> PnmlNetData

Access PnmlNet-level data structure.
"""
function netdata end


#--------------------------------------------
# PLACES & MARKINGS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)

Return iterator of all places.
"""
function places end

"""
$(TYPEDSIGNATURES)

Return iterator of all place IDs.
"""
function place_idset end

"""
$(TYPEDSIGNATURES)

Return `true` if there is any place with `id`?
"""
function has_place end

"""
$(TYPEDSIGNATURES)

Return the place with `id`.
"""
function place end

"""
$(TYPEDSIGNATURES)

Return the initial marking of a place.
"""
function initial_marking end

#--------------------------------------------
# TRANSITIONS & CONDITIONS
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return iterator of all transitions.
"""
function transitions end

"""
$(TYPEDSIGNATURES)

Is there a transition with `id`?
"""
function has_transition end

"""
$(TYPEDSIGNATURES)
"""
function transition end

"""
$(TYPEDSIGNATURES)
"""
function transition_idset end

"""
    inscriptions(net::PnmlNet) -> Iterator

Iterate over REFID => inscription(arc) pairs of `net`. This is the same order as `arcs`.
"""
function inscriptions end

"""
    conditions(net::PnmlNet) -> Iterator

Iterate over REFID => condition(transaction) pairs of `net`. This is the same order as `transactions`.
"""
function conditions end

"""
    rates(net::PnmlNet) -> [id(transition) => rate_value(transition)]

Return a vector of transition_id=>rate_value.

We allow all PNML nets to be stochastic Petri nets. See [`rate_value`](@ref).
"""
function rates end

"""
$(TYPEDSIGNATURES)

Return condition's value of `transition`.
"""
function condition end

#--------------------------------------------
# ARCS & INSCRIPTIONS
#--------------------------------------------
"""
    arcs(n::PnmlNet) -> iterator
    arcs(p::AbstractPetriNet) -> iterator

Return iterator over arc ids.
"""
function arcs end
"""
$(TYPEDSIGNATURES)+

Return `true` if any `arc` has `id`.
"""
function has_arc end

"""
$(TYPEDSIGNATURES)
Return arc with `id` if found, otherwise `nothing`.
"""
function arc end

"""
$(TYPEDSIGNATURES)

Return iterator over arc ids.
"""
function arc_idset end

"""
$(TYPEDSIGNATURES)
Return arcs that have a source or target of transition `id`.

See also [`src_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function all_arcs end

"""
$(TYPEDSIGNATURES)

Return arcs that have a source of transition `id`.

See also [`all_arcs`](@ref), [`tgt_arcs`](@ref).
"""
function src_arcs end

"""
$(TYPEDSIGNATURES)

Return arcs that have a target of transition `id`.

See also [`all_arcs`](@ref), [`src_arcs`](@ref).
"""
function tgt_arcs end

"""
$(TYPEDSIGNATURES)
Return incription value of `arc`.
"""
function inscription end

#--------------------------------------------
# REFERENCES
#--------------------------------------------
"""
$(TYPEDSIGNATURES)
Return vector of all reference places.
"""
function refplaces end

"""
$(TYPEDSIGNATURES)
Return vector of all reference transitions.
"""
function reftransitions end

"""
$(TYPEDSIGNATURES)
"""
function has_refplace end

"""
$(TYPEDSIGNATURES)
"""
function has_reftransition end

"""
    refplace_idset(x) -> OrderedSet{Symbol} #TODO iterator?

Return reference place pnml ids.
"""
function refplace_idset end

"""
    reftransition_idset(x) -> OrderedSet{Symbol} #TODO iterator?

Return reference transition pnml ids.
"""
function reftransition_idset end

"""
$(TYPEDSIGNATURES)
Return reference place matching `id`.
"""
function refplace end

"""
$(TYPEDSIGNATURES)
Return reference transition matching `id`.
"""
function reftransition end

"""
    value(x)
Return value of x. Can be a wrapped value or a derived value.
May return an Expr that returns the value when eval'ed.
"""
function value end

"""
    term(x)
Return 'PnmlExpr` term of x.
"""
function term end

"""
    coordinate_type(x) -> Type(Coordinate)
"""
function coordinate_type end

"""
    sortof(x) -> AbstractSort

Return the sort of an object or type.

Often implemented as `sortdefinition(namedsort(ddict, sortref(x)))`
or other call of `sortdefinition`. Default implementation is `identity`.

We provide a sort for some Julia types: `Integer`, `Int64`, `Float64`. Used for `PTNet`.
"""
function sortof end

"""
    sortref(x) -> SortRef

Return a REFID wrapped in a [`SortRef`](@ref).

Things that have a sortref include:
Place, Arc, Inscription, Marking,
MultisetSort,  SortType,
NumberConstant, Int64, Integer, Float64,
FEConstant, FiniteIntRangeConstant, DotConstant, BooleanConstant,
PnmlMultiset, Operator, Variable,
"""
function sortref end


@data SortRefx begin
    UserSortRef(Symbol)
    NamedSortRef(Symbol)
    PartitionSortRef(Symbol)
    ProductSortRef(Symbol)
    MultisetSortRef(Symbol)
    ArbitrarySortRef(Symbol)
end

# function ref_to_sort(sr::SortRefx, ddict)
#     @match sr begin
#        UserSortRef(ref) => usersorts(ddict)[ref]
#        NamedSortRef(ref) => namedsorts(ddict)[ref]
#        PartitionSortRef(ref) => productsorts(ddict)[ref]
#        ProductSortRef(ref) => partition(ddict)[ref]
#        MultisetSortRef(ref) => multisetsorts(ddict)[ref]
#        ArbitrarySortRef(ref) => arbitrarysorts(ddict)[ref]
#        _ => error("not expected: $sr") #!eltype(to_sort(s; ddict))
#     end
# end

"""
    sortdefinition(::SortDeclaration) -> Sort

Return concrete sort attached to a sort declaration object.

Dictionaries in a network-level [`DeclDict`](@ref) hold, among other things,
`NamedSort`, `ArbitrarySort` and `PartitionSort` declarations.
These declarations add an ID and name to a concrete sort,
with the ID symbol used as the dictionary key.

# Examples
    sortdefinition(namedsort(decldict, refid))
    sortdefinition(partitionsort(decldict, refid))
"""
function sortdefinition end

"""
    basis(x, ddict) -> SortRef

Return SortRef referencing a NamedSort, ArbitrarySort or PartitionSort declaration.
`MultisetSort`, `Multiset`, `List` have a `basis`.  Default `basis` is `sortof`
Place marking & sorttype, arc inscriptions have a `basis`.
"""
function basis end


"""
    sortelements(x) -> Iterator

Return iterator over elements of the sort of x.
"""
function sortelements end


"""
    adjacent_place(net::PnmlNet, arc::Arc) -> Place
    adjacent_place(netdata::PnmlNetData, source,::Symbol target::Symbol) -> Place

Adjacent place of an arc is either the `source` or `target`.
"""
function adjacent_place end
# Note that this behavior is suitable to many Petri nets.
# But the PNML core does not have this limit; it is imposed by meta-models.
#todo Remove limitation of requiring arcs to be between place and transition.
#todo Use traits?

"""
    decldict(x) -> DeclDict

`PnmlNet`,`Page` and `Declaration` labels have bindings to the net-level `DeclDict`.
"""
function decldict end

"""
"Version of tool for this tool specific information element and its parser."
"""
function version end

"Fill and return a `ParserContext` object."
function parser_context end

function fill_sort_tag! end

"""
    input_matrix(petrinet::AbstractPetriNet) -> Matrix{value_type(Inscription, ::PnmlType))}
    input_matrix(petrinet::PnmlNet) -> Matrix{value_type(Inscription, ::PnmlType)}

Create and return a matrix ntransitions x nplaces.
"""
function input_matrix end

"""
    output_matrix(petrinet::AbstractPetriNet) -> Matrix{value_type(Inscription, ::PnmlType)}
    output_matrix(petrinet::PnmlNet) -> Matrix{value_type(Inscription, ::PnmlType)}

Create and return a matrix ntransitions x nplaces.
"""
function output_matrix end
