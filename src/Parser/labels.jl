"""
$(TYPEDSIGNATURES)

Return the stripped string of `<text>` node's content.
"""
function parse_text(node::XMLNode, _::PnmlType)
    check_nodename(node, "text")
    return string(strip(EzXML.nodecontent(node)))::String
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) label holding `<text>` value.
With optional `<toolspecific>` & `<graphics>` information.
"""
function parse_name(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "name")
    text::Maybe{String} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = string(strip(EzXML.nodecontent(child)))::String
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context) # name label
        else
            @warn "ignoring unexpected child of <name>: '$tag'"
        end
    end

    # There are pnml files that break the rules & do not have a text element here.
    # Attempt to harvest content of <name> element instead of the child <text> element.
    if isnothing(text)
        emsg = "<name> missing <text> element."
        if CONFIG[].text_element_optional
            text = string(strip(EzXML.nodecontent(node)))::String
            @warn string(emsg, "Using content = '", text, "'")::String
        else
            throw(ArgumentError(emsg))
        end
    end

    # Since names are for humans and do not need to be unique we will allow empty strings.
    # When the "lint" methods are implemented, they can complain.
    return Name(text, graphics, toolspecinfos)
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------
"""
    parse_label_content(node::XMLNode, termparser, pntd; decldict) -> NamedTuple

Parse top-level label  `node` using a `termparser` callable applied to any `<structure>` element.
Also parses `<text>`, `<toolinfo>`, `graphics` and sort of term.

Top-level labels are attached to nodes, such as: marking, inscription, condition.
Each having a `termparser`.

Returns vars, a tuple of PNML variable REFIDs.
Used in the muti-sorted algebra of High-level nets.
"""
function parse_label_content(node::XMLNode, termparser::F, pntd::PnmlType; parse_context::ParseContext) where {F}
    text::Maybe{Union{String,SubString{String}}} = nothing
    exp::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing
    ref ::Maybe{SortRef}= nothing
    vars = () # will be replaced by termparer
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd)
        elseif tag == "structure"
            (; exp, ref, vars) = termparser(child, pntd; parse_context) #collects variables
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context) # label content termparser
        else
            @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'", termparser, pntd)
        end
    end
    return (; text, exp, sort=ref, graphics, toolspecinfos, vars)
end


############################################################################
# Marking
############################################################################

# Sorts are sets in Part 1 of the ISO 15909 standard that defines the semantics.
# Very much mathy, so thinking of sorts as collections is natural.
# Some of the sets are finite: boolean, enumerations, ranges.
# Others include integers, natural, and positive numbers (Also floats/reals).
# Some High-levl Petri nets, in particular Symmetric nets, are restricted to finite sets.
# We support the possibility of full-fat High-level nets with
# arbitrary sort and arbitrary operation definitions.

# Part 2 of the standard that defines the syntax of the xml markup language
# maps these sets to sorts (similar to Type). And adds things.
# Partitions, Lists,

# Part 3 of the standard is a math and semantics extension covering
# modules, extensions, more net types. Not reflected in Part 2 as on August 2024.
# The 2nd edition of Part 1 is contemperoranous with Part 3.
# Part 2 add some of these features through the www.pnml.org Schema repository.

# `sortelements` is needed to support the <all> operator that forms a multiset out of
# one of each of the finite sorts elements. This leads to iteration. Thus eltype.

# If there is no appropriate eltype method defined expect
# `eltype(x) @ Base abstractarray.jl:241` to return Int64.

# Base.eltype is for collections: what an iterator would return.

# Parse <text> as a `Number` of appropriate type or use apropriate default.

"""
$(TYPEDSIGNATURES)

Non-high-level `PnmlType` initial marking parser. Most things are assumed to be Numbers.
"""
function parse_initialMarking(node::XMLNode, placetype::SortType, pntd::PnmlType; parse_context::ParseContext)
    nn = check_nodename(node, "initialMarking")
    # See if there is a <structure> attached to the label. This is non-standard.
    # Allows use of same mechanism used for high-level nets.
    l = parse_label_content(node, parse_structure, pntd; parse_context)::NamedTuple
    if !isnothing(l.exp) # There was a <structure> tag. Used in the high-level meta-models.
        @warn "$nn <structure> element not used YET by non high-level net $pntd; found $(l.exp)"
    end
    @assert isempty(l.vars) # markings are ground terms

    pt = eltype(sortref(placetype), parse_context.ddict)
    mvt = eltype(PNML.value_type(Marking, typeof(pntd)))
    pt <: mvt || @error("initial marking value type of $pntd must be $mvt, found: $pt")
    value = isnothing(l.text) ? zero(pt) : PNML.number_value(pt, l.text)
    # We ate the text to make the expression.
    Marking(PNML.NumberEx(sortref(placetype), value), nothing, l.graphics, l.toolspecinfos, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)
Ignore the source & target IDREF symbols.
"""
function parse_inscription(node::XMLNode, source::Symbol, target::Symbol, pntd::PnmlType; parse_context::ParseContext)
    @assert !(pntd isa AbstractHLCore)
    check_nodename(node, "inscription")
    txt = nothing
    value = nothing
    graphics::Maybe{Graphics} = nothing
    toolspecinfos::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            txt = string(strip(EzXML.nodecontent(child)))
            value = PNML.number_value(PNML.value_type(inscription_type(pntd), typeof(pntd)), txt)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            toolspecinfos = add_toolinfo(toolspecinfos, child, pntd, parse_context) # inscription label
        else
            @warn("ignoring unexpected child of <inscription>: '$tag'")
        end
    end

    # Treat missing value as if the <inscription> element was absent.
    if isnothing(value)
        value = one(PNML.value_type(inscription_type(pntd), typeof(pntd)))
        CONFIG[].warn_on_fixup &&
            @warn("missing or unparsable <inscription> value '$txt' replaced with $value")
    end

    Inscription(PNML.NumberEx(PNML.Labels._sortref(parse_context.ddict, value), value), graphics, toolspecinfos, parse_context.ddict)
end

"""
$(TYPEDSIGNATURES)

High-level initial marking labels are expected to have a <structure> child containing a ground term.
Sort of marking term must be the same as `placetype`, the places SortType.
Will be a `UserSort` that holds the ID of a sort declaration.

NB: Used by PTNets that assume placetype is DotSort().
"""
function parse_hlinitialMarking(node::XMLNode, placetype::SortType, pntd::AbstractHLCore; parse_context::ParseContext)
    check_nodename(node, "hlinitialMarking")
    l = parse_label_content(node, ParseMarkingTerm(PNML.sortref(placetype)), pntd; parse_context)::NamedTuple

    markterm = if isnothing(l.exp)
        # Default is an empty multiset whose basis matches placetype.
        # arg 2 is used to deduce the sort.
        # ProductSorts need to use a tuple of values.
        PNML.Bag(PNML.sortref(placetype), def_sort_element(placetype; parse_context.ddict), 0)
    else
        l.exp
    end
    @assert isempty(l.vars) # markings are ground terms
    Marking(markterm, l.text, l.graphics, l.toolspecinfos, parse_context.ddict)
end

"""
    ParseMarkingTerm(placetype) -> Functor

Holds parameters for parsing when called as (f::T)(::XMLNode, ::PnmlType)
"""
struct ParseMarkingTerm
    placetype::SortRef
end

placetype(pmt::ParseMarkingTerm) = pmt.placetype

function (pmt::ParseMarkingTerm)(marknode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(marknode, "structure")
    if EzXML.haselement(marknode)
        term = EzXML.firstelement(marknode) # ignore any others

        tj = parse_term(term, pntd; vars=(), parse_context) # ParseMarkingTerm
        isempty(tj.vars) || error("unexpected variables in $tj")

        #! MARK will be a TERM, a symbolic expression using TermInterface, @matchable
        #! that, when evaluated, produces a PnmlMultiset object.

        # PnmlMultiset (datastrstructureucture) vs UserOperator/NamedOperator (term/expression)
        # Here we are parsing a term from XML to a ground term, which must be an operator.
        # Like with sorts, we have useroperator -> namedoperator -> operator.
        # NamedOperators will be joined by ArbitraryOperators for HLPNGs.
        # Operators include built-in operators, multiset operators, tuples
        # Multiset operators must be evaluated to become PnmlMultiset objects.
        # Markings are multisets (a.k.a. bags).

        isa(placetype(pmt), UserSortRef) ||
            error("placetype expected to be UserSortRef, found $(placetype(pmt))")

        return tj
    end
    throw(ArgumentError("missing marking term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

hlinscriptions are expressions.
"""
function parse_hlinscription(node::XMLNode, source::Symbol, target::Symbol,
                             pntd::AbstractHLCore; netdata::PnmlNetData, parse_context::ParseContext)
    check_nodename(node, "hlinscription")
    l = parse_label_content(node, ParseInscriptionTerm(source, target, netdata), pntd; parse_context)::NamedTuple
    HLInscription(l.text, l.exp, l.graphics, l.toolspecinfos, l.vars, parse_context.ddict)
end

"""
    ParseInscriptionTerm(placetype) -> Functor

Holds parameters for parsing inscription.
The sort of the inscription must match the place sorttype.
Input arcs (source is a transition) and output arcs (source is a place)
called as (pit::ParseInscriptionTerm)(::XMLNode, ::PnmlType)
"""
struct ParseInscriptionTerm
    source::Symbol
    target::Symbol
    netdata::PnmlNetData
end

source(pit::ParseInscriptionTerm) = pit.source
target(pit::ParseInscriptionTerm) = pit.target
netdata(pit::ParseInscriptionTerm) = pit.netdata

function (pit::ParseInscriptionTerm)(inscnode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(inscnode, "structure")

    isa(target(pit), Symbol) ||
        error("target is a $(nameof(typeof(target(pit)))), expected Symbol")
    isa(source(pit), Symbol) ||
        error("source is a $(nameof(typeof(target(pit)))), expected Symbol")

    # The core PNML standard allows arcs from place to place, and transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).

    # Find adjacent place's sorttype using `netdata`.
    adjacentplace = PNML.adjacent_place(netdata(pit), source(pit), target(pit))
    placesort = PNML.Labels._sortref(parse_context.ddict, adjacentplace)::SortRef

    # Variable substitution for a transition affects postset arc inscription,
    # whose expression is used to determine the new marking.
    # Variable substitution covers all variables in a transition. Variables are from inscriptions.
    # A condition expression may use variables from an inscripion.
    tj = if EzXML.haselement(inscnode)
        parse_term(EzXML.firstelement(inscnode), pntd; vars=(), parse_context)
    else
        # Default to a multiset whose basis is placetype.
        inscript = def_insc(netdata(pit), source(pit), target(pit), parse_context.ddict)
        @warn("missing inscription term in <structure>, returning ", inscript)
        TermJunk(inscript, placesort, ())
    end

    isa(tj.exp, PnmlExpr) ||
        error("inscription is a $(nameof(typeof(inscript))), expected PnmlExpr")
    tj.ref == placesort ||
        error("inscription term sort mismatch: $(tj.sortref) != $placesort")

    return tj
end

function PNML.adjacent_place(netdata::PnmlNetData, source::REFID, target::REFID)
    # Meta-model constraint for Petri nets is that arcs must be between place and transition.
    #
    if haskey(PNML.placedict(netdata), source)
        haskey(PNML.transitiondict(netdata), target) ||
            error("adjacent source plece $source does not have transition target $target")
        @inline PNML.placedict(netdata)[source]
    elseif haskey(PNML.placedict(netdata), target)
        haskey(PNML.transitiondict(netdata), source) ||
             error("adjacent target place $target does not have transition source $source")
        @inline PNML.placedict(netdata)[target]
   else
        error("adjacent place not found for source = $source, target = $target")
    end
end


# default inscription with sort of adjacent place
function def_insc(netdata, source,::REFID, target::REFID, parse_context::ParseContext)
    # Core PNML standard allows arcs from place to place & transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).
    place = PNML.adjacent_place(netdata, source, target)
    placetype = place.sorttype
    el = def_sort_element(placetype; parse_context.ddict)
    inscr = PNML.pnmlmultiset(PNML.sortref(placetype), el, 1; parse_context.ddict)
    #@show inscr
    return inscr
end

"""
    parse_condition(::XMLNode, ::PnmlType; decldict) -> Condition

Label of transition node. Used in the enabling function.

# Details

ISO/IEC 15909-1:2019(E) Concept 15 (symmetric net) introduces
Φ(transition), a guard or filter function, that is and'ed into the enabling function.
15909-2 maps this to `<condition>` expressions.

Later concepts add filter functions that are also and'ed into the enabling function.
- Concept 28 (prioritized Petri net enabling rule)
- Concept 31 (time Petri net enabling rule)

We support PTNets having `<condition>` with same syntax as High-level nets.
Condition has `<text>` and `<structure>` elements, with all meaning in the `<structure>`
that holds an expression evaluating to a boolean value.

One field of a Condition holds a boolean expression, `BoolExpr`.
Another field holds information on variables in the expression.
"""
function parse_condition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    l = parse_label_content(node, parse_condition_term, pntd; parse_context)::NamedTuple
    isnothing(l.exp) && throw(PNML.MalformedException("missing condition term in $(repr(l))"))
    PNML.Labels.Condition(l.text, l.exp, l.graphics, l.toolspecinfos, l.vars, parse_context.ddict)
end

"""
    parse_condition_term(::XMLNode, ::PnmlType; decldict) -> PnmlExpr, SortRef, Tuple

Used as `termparser` by [`parse_label_content`](@ref) for `Condition` label of a `Transition`;
will have a structure element containing a term.
"""
function parse_condition_term(cnode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        return parse_term(EzXML.firstelement(cnode), pntd; vars=(), parse_context)
    end
    throw(ArgumentError("missing condition term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

Annotation Label that defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd". Neither is directly a julia type. Nor a pnml sort.

We allow all pntd's places to have a <type> label.
Non-high-level net places are expecting a numeric sort: eltype(sort) <: Number.
"""
function parse_sorttype(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "type")
    l = parse_label_content(node, parse_sorttype_term, pntd; parse_context)::NamedTuple
    @assert isempty(l.vars) # No variables as sort is not a term.
    # High-level nets are expected to have a sorttype defined.
    # Possibly sorttype inferred from initial marking value.

    SortType(l.text, l.exp, l.graphics, l.toolspecinfos, parse_context.ddict) # Basic label structure.
end

"""
    parse_sorttype_term(::XMLNode, ::PnmlType; decldict) -> PnmlExpr, SortRef, Tuple

The PNML `<type>` of a `<place>` is a "sort" of the high-level many-sorted algebra.
Because we are sharing the HL implementation with the other meta-models,
we support it in all nets.

The term here is a concrete sort, usually `UserSort`Ref.
It is possible to have an inlined concrete sort that is anonymous.
We place all these concrete sorts in the parse_context.ddict and pass around a SortRef.

See [`parse_sorttype`](@ref) for the rest of the `AnnotationLabel` structure.
"""
function parse_sorttype_term(typenode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || throw(ArgumentError("missing <type> element in <structure>"))
    sortnode = EzXML.firstelement(typenode)::XMLNode # Expect only child element to be a sort.
    sorttype = parse_sort(sortnode, pntd; parse_context)::SortRef
    isa(sorttype, MultisetSortRef) && error("multiset sort not allowed for place <type>")
    # We use TermJunk because it is convenient. #! Does it work?
    return TermJunk(sorttype, sorttype, ()) # Not a term; has no variables.
end

"""
$(TYPEDSIGNATURES)

Return [`PNML.Labels.Structure`](@ref) holding an XML <structure>.
Should be inside of an PNML label.
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(node, "structure")
    @warn "parse_structure is not a well defined thing, $pntd"
    Structure(unparsed_tag(node)..., parse_context.ddict) #TODO anyelement
end


#! 2025-06-04 removed parse_label
