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
    tools::Maybe{Vector{ToolInfo}} = nothing
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = string(strip(EzXML.nodecontent(child)))::String
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd, parse_context) # name label
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
    return Name(text, graphics, tools)
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------
"""
    parse_label_content(node::XMLNode, termparser, pntd; decldict) -> NamedTuple

Parse top-level label using a `termparser` callable applied to any `<structure>` element.
Also parses `<text>`, `<toolinfo>`, `graphics` and sort of term.

Top-level labels are marking, inscription, condition. Each having a `termparser`.

Returns vars, a tuple of PNML variable REFIDs. Used in the muti-sorted algebra of High-level nets.
"""
function parse_label_content(node::XMLNode, termparser::F, pntd::PnmlType; parse_context::ParseContext) where {F}
    text::Maybe{Union{String,SubString{String}}} = nothing
    term::Maybe{Any} = nothing
    graphics::Maybe{Graphics} = nothing
    tools::Maybe{Vector{ToolInfo}} = nothing
    tsort ::Maybe{AbstractSort}= nothing
    vars = () # Default value, will be replaced by termparer
    #@show nameof(typeof(termparser)) #! debug
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            text = parse_text(child, pntd)
        elseif tag == "structure"
            term, tsort, vars = termparser(child, pntd; parse_context) #collects variables
            # @show (term, tsort, vars) #! debug
            # @show typeof(term)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd, parse_context) # label content termparser
        else
            @warn("ignoring unexpected child of <$(EzXML.nodename(node))>: '$tag'", termparser, pntd)
        end
    end
    return (; text, term, sort=tsort, graphics, tools, vars)
end

"""
$(TYPEDSIGNATURES)

Non-high-level `PnmlType` initial marking parser. Most things are assumed to be Numbers.
"""
function parse_initialMarking(node::XMLNode, placetype::SortType, pntd::PnmlType; parse_context::ParseContext)
    nn = check_nodename(node, "initialMarking")
    # See if there is a <structure> attached to the label. This is non-standard.
    # Allows use of same mechanism used for high-level nets.
    l = parse_label_content(node, parse_structure, pntd; parse_context)::NamedTuple
    if !isnothing(l.term) # There was a <structure> tag. Used in the high-level meta-models.
        @warn "$nn <structure> element not used YET by non high-level net $pntd; found $(l.term)"
    end
    @assert isempty(l.vars) # markings are ground terms

    # Sorts are sets in Part 1 of the ISO specification that defines the semantics.
    # Very much mathy, so thinking of sorts as collections is natural.
    # Some of the sets are finite: boolean, enumerations, ranges.
    # Others include integers, natural, and positive numbers (we extend with floats/reals).
    # Some High-levl Petri nets, in particular Symmetric nets, are restricted to finite sets.
    # We support the possibility of full-fat High-level nets with
    # arbitrary sort and arbitrary operation definitions.

    # Part2 of the ISO specification that defines the syntax of the xml markup language
    # maps these sets to sorts (similar to Type). And adds things.
    # A MathML replacement for HL nets. (They abandoned Masortref(thML.)
    # Partitions, Lists,

    # Part 3 of the ISO specification is a math and semantics extension covering
    # modules, extensions, more net types. Not reflected in Part 2 as on August 2024.
    # The 2nd edition of Part 1 is contemperoranous with Part 3.
    # Part 2 add some of these features through the www.pnml.org Schema repository.

    # sortelements is needed to support the <all> operator that forms a multiset out of
    # one of each of the finite sorts elements. This leads to iteration. Thus eltype.

    # If there is no appropriate eltype method defined expect
    # `eltype(x) @ Base abstractarray.jl:241` to return Int64.
    # Base.eltype is for collections: what an iterator would return.

    # Parse <text> as a `Number` of appropriate type or use apropriate default.
    pt = eltype(sortref(placetype))
    mvt = eltype(PNML.marking_value_type(pntd))
    pt <: mvt || @error("initial marking value type of $pntd must be $mvt, found: $pt")
    value = isnothing(l.text) ? zero(pt) : PNML.number_value(pt, l.text)

    Marking(PNML.NumberEx(sortref(placetype), value), l.graphics, l.tools, parse_context.ddict)
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
    tools::Maybe{Vector{ToolInfo}} = nothing

    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "text"
            txt = string(strip(EzXML.nodecontent(child)))
            value = PNML.number_value(PNML.inscription_value_type(pntd), txt)
        elseif tag == "graphics"
            graphics = parse_graphics(child, pntd)
        elseif tag == "toolspecific"
            tools = add_toolinfo(tools, child, pntd, parse_context) # inscription label
        else
            @warn("ignoring unexpected child of <inscription>: '$tag'")
        end
    end

    # Treat missing value as if the <inscription> element was absent.
    if isnothing(value)
        value = one(PNML.inscription_value_type(pntd))
        CONFIG[].warn_on_fixup &&
            @warn("missing or unparsable <inscription> value '$txt' replaced with $value")
    end

    Inscription(PNML.NumberEx(PNML.Labels._sortref(parse_context.ddict, value), value), graphics, tools, parse_context.ddict)
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
    #@warn pntd l #! debug
    # Marking label content is expected to be a TermInterface expression.
    # All declarations are expected to have been processed before the first place.

    markterm = if isnothing(l.term)
        # Default is an empty multiset whose basis matches placetype.
        # arg 2 is used to deduce the sort.
        # ProductSorts need to use a tuple of values.
        PNML.Bag(PNML.sortref(placetype), def_sort_element(placetype), 0)
    else
        l.term
    end
    @assert isempty(l.vars) # markings are ground terms
    #! Expect a `PnmlExpr` @matchable, do the checks elsewhere TBD
    # equal(sortof(basis(markterm)), sortof(placetype)) ||
    #     @error(string("HL marking sort mismatch,",
    #         "\n\t sortof(basis(markterm)) = ", sortof(basis(markterm)),
    #         "\n\t sortof(placetype) = ", sortof(placetype)))
    HLMarking(l.text, markterm, l.graphics, l.tools, parse_context.ddict)
end

"""
    ParseMarkingTerm(placetype) -> Functor

Holds parameters for parsing when called as (f::T)(::XMLNode, ::PnmlType)
"""
struct ParseMarkingTerm
    placetype::UserSort
end

placetype(pmt::ParseMarkingTerm) = pmt.placetype

function (pmt::ParseMarkingTerm)(marknode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(marknode, "structure")
    if EzXML.haselement(marknode)
        #println("\n(pmt::ParseMarkingTerm) "); @show placetype(pmt)
        term = EzXML.firstelement(marknode) # ignore any others

        mark, sort, vars = parse_term(term, pntd; vars=(), parse_context) # ParseMarkingTerm
        !isempty(vars) && @error vars
        #@show typeof(mark), sort; flush(stdout)
        @assert mark isa PnmlExpr

        #! MARK will be a TERM, a symbolic expression using TermInterface, @matchable
        #! that, when evaluated, produces a PnmlMultiset object.

        #@assert sort == sortof(mark) # sortof multiset is the basis sort
        #@assert sortof(mark) != basis(mark)
        #@assert basis(mark) == sortof(basis(mark))

        # PnmlMultiset (datastructure) vs UserOperator/NamedOperator (term/expression)
        # Here we are parsing a term from XML to a ground term, which must be an operator.
        # Like with sorts, we have useroperator -> namedoperator -> operator.
        # NamedOperators will be joined by ArbitraryOperators for HLPNGs.
        # Operators include built-in operators, multiset operators, tuples
        # Multiset operators must be evaluated to become PnmlMultiset objects.
        # Markings are multisets (a.k.a. bags).
        #!isa(mark, PnmlMultiset) ||
        #!ismultisetoperator(tag(mark)) || error("mark is not a multiset operator: $mark))")

        # isa(sortof(mark), UserSort) ||
        #     error("sortof(mark) is a $(sortof(mark)), expected UserSort")
        # isa(mark, Union{PnmlMultiset,Operator}) ||
        #     error("mark is a $(nameof(typeof(mark))), expected PnmlMultiset or Operator")

        isa(placetype(pmt), UserSort) ||
            error("placetype is a $(nameof(typeof(placetype(pmt)))), expected UserSort")

        # if !equal(sortof(basis(mark)), sortof(placetype(pmt)))
        #     @show basis(mark) placetype(pmt) sortof(basis(mark)) sortof(placetype(pmt))
        #     throw(ArgumentError(string("parse marking term sort mismatch:",
        #         "\n\t sortof(basis(mark)) = ", sortof(basis(mark)),
        #         "\n\t sortof(sorttype) = ", sortof(placetype(pmt)))))
        # end
        return (mark, sort, vars) # TermInterface, UserSort
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
    l = parse_label_content(node, ParseInscriptionTerm(source, target, netdata), pntd; parse_context)
    HLInscription(l.text, l.term, l.graphics, l.tools, l.vars, parse_context.ddict)
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
    #println("\n(pmt::ParseInscriptionTerm) ", source(pit), " -> ", target(pit))

    isa(target(pit), Symbol) ||
        error("target is a $(nameof(typeof(target(pit)))), expected Symbol")
    isa(source(pit), Symbol) ||
        error("source is a $(nameof(typeof(target(pit)))), expected Symbol")

    # The core PNML specification allows arcs from place to place, and transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).

    # Find adjacent place's sorttype using `netdata`.
    adjacentplace = PNML.adjacent_place(netdata(pit), source(pit), target(pit))
    placesort = PNML.Labels._sortref(parse_context.ddict, adjacentplace)::UserSort
    vars = () #
    # Variable substitution for a transition affects postset arc inscription,
    # whose expression is used to determine the new marking.
    # Variable substitution covers all variables in a transition. Variables are from inscriptions.
    # A condition expression may use variables from an inscripion.
    if EzXML.haselement(inscnode)
        term = EzXML.firstelement(inscnode) # ignore any others
        inscript, _, vars = parse_term(term, pntd; vars, parse_context)
    else
        # Default to a multiset whose basis is placetype.
        inscript = def_insc(netdata(pit), source(pit), target(pit), parse_context.ddict)
        @warn("missing inscription term in <structure>, returning ", inscript)
    end
    #@show inscript placesort; flush(stdout) #! debug

    isa(inscript, PnmlExpr) ||
        error("inscription is a $(nameof(typeof(inscript))), expected PnmlExpr")

    #! inscript isa PnmlExpr, do these tests during/after firing/eval
    # isa(sortof(inscript), AbstractSort) ||
    #     error("sortof(inscript) is a $(nameof(sortof(inscript))), expected AbstractSort")
    # @assert sort == sortof(inscript) "error $sort != $(sortof(inscript))"

    #  equal(sortof(basis(inscript)), placesort) ||
    #     throw(ArgumentError(string("sort mismatch:",
    #         "\n\t sortof(basis(inscription)) ", sortof(basis(inscript)),
    #         "\n\t placesort ", placesort)))
    return (inscript, placesort, vars)
end

function PNML.adjacent_place(netdata, source::REFID, target::REFID)
    if haskey(PNML.placedict(netdata), source)
        @assert haskey(PNML.transitiondict(netdata), target) # Meta-model constraint.
        @inline PNML.placedict(netdata)[source]
    elseif haskey(PNML.placedict(netdata), target)
        @assert haskey(PNML.transitiondict(netdata), source) # Meta-model constraint.
        @inline PNML.placedict(netdata)[target]
    else
        error("inscription place not found, source = $source, target = $target")
    end
end


# default inscription with sort of adjacent place
function def_insc(netdata, source,::REFID, target::REFID, parse_context::ParseContext)
    # Core PNML specification allows arcs from place to place & transition to transition.
    # Here we support symmetric nets that restrict arcs and
    # assume exactly one is a place (and the other a transition).
    place = PNML.adjacent_place(netdata, source, target)
    placetype = place.sorttype
    el = def_sort_element(placetype)
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
function parse_condition(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) # Non-HL
    l = parse_label_content(node, parse_condition_term, pntd; parse_context) #! also return vars tuple
    #@show condlabel; flush(stdout) #! debug
    #@warn("parse_condition label = $(condlabel)")

    isnothing(l.term) && throw(PNML.MalformedException("missing condition term in $(repr(l))"))
    PNML.Labels.Condition(l.text, l.term, l.graphics, l.tools, l.vars, parse_context.ddict) #! term is expession
end

"""
    parse_condition_term(::XMLNode, ::PnmlType; decldict) -> PnmlExpr, UserSort

Used as a `termparser` by [`parse_label_content`](@ref) for `Condition` label of a `Transition`; will have a structure element containing a term.
"""
function parse_condition_term(cnode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(cnode, "structure")
    if EzXML.haselement(cnode)
        return parse_term(EzXML.firstelement(cnode), pntd; vars=(), parse_context) # expression, usersort, vars
    end
    throw(ArgumentError("missing condition term in <structure>"))
end

"""
$(TYPEDSIGNATURES)

Label that defines the "sort" of tokens held by the place and semantics of the marking.
NB: The "type" of a place from _many-sorted algebra_ is different from
the Petri Net "type" of a net or "pntd". Neither is directly a julia type.

Allow all pntd's places to have a <type> label.
Non-high-level are expecting a numeric sort: eltype(sort) <: Number.
"""
function parse_sorttype(node::XMLNode, pntd::PnmlType; parse_context::ParseContext) # place sorttype
    check_nodename(node, "type")
    l = parse_label_content(node, parse_sorttype_term, pntd; parse_context)
    @assert isempty(l.vars)
    # High-level nets are expected to have a sorttype term defined.

    SortType(l.text, l.term, l.graphics, l.tools, parse_context.ddict) # Basic label structure.
end

"""
    parse_sorttype_term(::XMLNode, ::PnmlType; decldict) -> Tuple

The PNML `<type>` of a `<place>` is a "sort" of the high-level many-sorted algebra.
Because we are sharing the HL implementation with the other meta-models,
we support it in all nets. The term here is a `UserSort` in all cases.

See [`parse_sorttype`](@ref) for the rest of the `AnnotationLabel` structure.
"""
function parse_sorttype_term(typenode::XMLNode, pntd::PnmlType; parse_context::ParseContext)
    check_nodename(typenode, "structure")
    EzXML.haselement(typenode) || throw(ArgumentError("missing <type> element in <structure>"))
    sortnode = EzXML.firstelement(typenode)::XMLNode # Expect only child element to be a sort.
    sorttype = parse_sort(sortnode, pntd; parse_context)::UserSort
    isa(sorttype, MultisetSort) && error("multiset sort not allowed for place <type>")
    return (sorttype, sortof(sorttype)::AbstractSort, ()) # Ground term has no variables.
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


#---------------------------------------------------------------------
#TODO Will unclaimed_node handle this?
"""
$(TYPEDSIGNATURES)

Should not often have a <label> tag, this will bark if one is found and return NamedTuple (tag,xml) to defer parsing the xml.
"""
function parse_label(node::XMLNode, ::PnmlType; parse_context::ParseContext) # In case there is a <label> found.
    @assert node !== nothing
    nn = check_nodename(node, "label")
    @warn "there is a label named 'label'"
    (; :tag => Symbol(nn), :xml => node) # Always add xml because this is unexpected.
end
