
# See `TermInterface.jl`, `Metatheory.jl`
"""
$(TYPEDSIGNATURES)

There will be no XML node <term>. Instead it is the interpertation of the child of some
<structure>, <subterm> or <def> elements. The Relax NG Schema does contain "Term".
Terms kinds are Variable and Operator.

All terms have a sort, #TODO
Will be using `TermInterface.jl` to build an expression tree (AST) that can contain:
operators, constants (as 0-airity operators), and variables.

AST are evaluated for place initialMarking (ground terms only) and transition firing
where conditions and inscription expressions may contain non-ground terms (using variables).

# TIDBITS

Is this a useful pattern for handling ASTs:
    p isa MP.SomeType && MP.isconstant(p) && return convert(Number, p)

"""
function parse_term(node::XMLNode, pntd::PnmlType)
    tag = Symbol(EzXML.nodename(node))
    printstyled("parse_term tag = $tag \n"; color=:bold)
    if tag in  [:variable, # TODO more?
                :booleanconstant,
                :numberconstant,
                :dotconstant,
                :all, # multiset operator, a ground term
                :numberof, # multiset operator, may hold variables
                # :feconstant,
                # :unparsed,
                :useroperator,
                #:usersort,
                :finiteintrangeconstant]
        # 0-arity terms (Or trivial to reduce to such) are leaf nodes of ast.
        # Use term rewriting to turn them into literals.
        #! These must follow the Operator interface. See operators.jl.
        #^ MUST return same type as parse_operator_term.
        # Which also are TermInterface.jl.
        return parse_term(Val(tag), node, pntd) #! XXX REMOVE SORT (AbstractTerm, Sort)
        #! return (Operator(tag, func, [], [], outsort), outsort) #!
    else # arity > 0, build & return an Operator Functor that has a vector of inputs.
        return parse_operator_term(tag, node, pntd) #! XXX REMOVE SORT (Operator, Sort)
    end
    #! XXX do parse_term, parse_operator_term have same type XXX
end

"""
$(TYPEDSIGNATURES)

Build an [`Operator`](@ref) Functor from the XML tree at `node`.

"""
function parse_operator_term(tag::Symbol, node::XMLNode, pntd::PnmlType)
    printstyled("parse_operator_term: $(repr(tag))\n"; color=:green);

    isoperator(tag) || @error "tag $tag is not an operator"

    func = pnml_hl_operator(tag) #TODO! #! should be TermInterface to be to_expr'ed

    interms = Any[] #Union{AbstractVariable, AbstractOperator}[] #TODO tuple?
    insorts = UserSort[] # REFID of sort declaration

    # Extract the input term and sort from each <subterm>
    for child in EzXML.eachelement(node)
        check_nodename(child, "subterm")
        subterm = EzXML.firstelement(child) # this is the unwrapped subterm

        (t, s) = parse_term(subterm, pntd) # term and its user sort

        # returns an AST
        push!(interms, t) #! should be TermInterface to be to_expr'ed
        push!(insorts, s) #~ sort may be inferred from place, variable, operator output
    end
    @assert length(interms) == length(insorts)
    # for (t,s) in zip(interms,insorts) # Lots of output. Leave this here for debug, bring-up
    #     @show t s
    #     println()
    # end
    outsort = pnml_hl_outsort(tag; insorts) #! some sorts need content

    println("parse_operator_term returning $(repr(tag)) $(func)")
    println("   interms ", interms)
    println("   insorts ", insorts)
    println("   outsort ", outsort)
    println()
    # maketerm(Expr, :call, [], nothing)
    # :(func())
    return (Operator(tag, func, interms, insorts, outsort), outsort)
end

#----------------------------------------------------------------------------------------
# Expect only an attribute referencing the declaration.
function parse_term(::Val{:variable}, node::XMLNode, pntd::PnmlType)
    var = Variable(Symbol(attribute(node, "refvariable")))
    return (var, sortof(var)) #! does DeclDict lookup #TODO XXX toexpr(::Variable)
end

# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType)
    bc = BooleanConstant(attribute(node, "value"))
    return (bc, sortof(bc)) #TODO XXX toexpr(::BooleanConstant)
    #! maketerm(Expr, :call, [], nothing)
    #return (Operator(tag, func, interms, insorts, outsort, nothing), outsort)
end

# Has a value that is a subsort of NumberSort (<:Number).
function parse_term(::Val{:numberconstant}, node::XMLNode, pntd::PnmlType)
    value = attribute(node, "value")::String
    child = EzXML.firstelement(node) # Child is the sort of value attribute.
    isnothing(child) && throw(MalformedException("<numberconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    sort = if sorttag in (:integer, :natural, :positive, :real) #  We allow non-standard real.
        usersort(sorttag) #! parse_sort(Val(sorttag), child, pntd) # Built-in, expect to exist!
    else
        throw(MalformedException("$tag sort not supported for :numberconstant: $sorttag"))
    end

    nv = number_value(eltype(sort), value)
    if sort isa NaturalSort
        nv >= 0 || throw(ArgumentError("not a Natural Number: $nv"))
    elseif sort isa PositiveSort
        nv > 0 || throw(ArgumentError("not a Positive Number: $nv"))
    end
    # IntegerSort, RealSort do not need bounds checks.
    nc = NumberConstant(nv, sort) #! TermInterface rewrite
    return (nc, sortof(nc)) # return object with a toexpr() method
end
#! parse_term() not type stable
#! `sortof` returns the sort object itself, `usersort` wraps a REFID.
#!

# Dot is the high-level concept of an integer, use 1 as the value.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType)
    return (DotConstant(), usersort(:dot)) #TODO XXX toexpr(::DotConstant)
end

# <structure>
#     <tuple>
#         <subterm><all><usersort declaration="N1"/></all></subterm>
#         <subterm><all><usersort declaration="N2"/></all></subterm>
#     </tuple>
# </structure>
"""
    parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType) -> PnmlMultiset

 `All` operator creates a multiset that contains exactly one of each element of its basis finite set/sort.
 Is a literal/ground term and used for intialMarking expressions.
"""
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType)
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("$tag missing content element"))

    us = parse_usersort(child, pntd)::UserSort # Can there be anything else?
    #^ Only expect finite sorts here. #! assert isfinitesort(b)
    b = sortof(us)
    #!all = pnmlmultiset(b) #! TermInterface expression LIKE Bag, PnmlMultiset is a data structure
    #!return (all, b)
    return maketerm(Type{Bag}, b, nothing, nothing, nothing), b #! toexpr(::Bag) calls pnmlmultiset(b)
end


    #@show us b e typeof(e)
    # dot: dotconstant
    # bool: true, false #todo tuple of BooleanConstants
    # finite int range: start:1:stop
    # enumeration: sequence of objects

    # Eventually the Metatheory rewrite engine, SymbolicUtils will expand the this.
    #~ What lie do we tell now?
    #
    # NamedSort declaration gives a name (and ID) to built-in sorts (and multisets,
    # product sorts). Someday, ArbitrarySort declarations will also be supported.
    # Note PartitionSort is a declaration like NamedSort and ArbitrarySort and IS SUPPORTED.
    #
    # Think of _sort_ as a finite set (example finite range of integers, enumeration)
    # and/or datatype (as in `DataType`, the mechanism implementing the concept of type).
    # Finite set is a SymmetricNet restriction (for mathematical reasons).
    # Unrestricted HLPNGs allow at least integers.


# Return multiset containing multiplicity of elements of its basis sort.
# <text>3`dot</text>
# <structure>
#     <numberof>
#         <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
#         <subterm><dotconstant/></subterm>
#     </numberof>
# </structure>

#multiset in which the element occurs exactly in the given number and no other elements in it.
# context NumberOf inv:
#   self.input->size() = 2 and
#   self.input->forAll{c, d | c.oclIsTypeOf(Integers::Natural) and d.oclIsKindOf(Terms::Sort)} and
#   self.output.oclIsKindOf(Terms::MultisetSort)

# c TypeOF sort of multiplicity
# d KindOf (instance of this sort)

#! This MUST return an expression. OR TermInterface with toexpr().
#! ALL `parse_term` will be TermInterface fed to term rewrite then toexpr().
# operator: numberof
# output: Expression for term rewrite into `pnmlmultiset`. #! TermInterface.maketerm
# 2 inputs: multiplicity, term evaluating to an element of basis sort
# Use rewrite rule to dynamically evaluate output to materialize a PnmlMultiset.
function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType)
    multiplicity = nothing
    instance = nothing
    isort = nothing
    #!multiplicity::Maybe{NumberConstant} = nothing
    #!instance::Maybe{AbstractTerm} = nothing
    for (i,subterm) in enumerate(EzXML.eachelement(node))
        check_nodename(subterm, "subterm")
        stnode = first(EzXML.elements(subterm))
        tag = Symbol(EzXML.nodename(stnode))
        if tag == :numberconstant && isnothing(multiplicity)
            multiplicity, _ = parse_term(Val(tag), stnode, pntd)
            # RealSort as first numberconstant might confuse `Multiset.jl`.
        else
            # If 2 numberconstants, first is `multiplicity`, this is `instance`.
            instance, isort = parse_term(stnode, pntd) #
            @show instance isort sortof(instance)
            # should it be sortof?
            isa(instance, MultisetSort) && throw(ArgumentError("numberof's output sort cannot be MultisetSort"))
            #~ Many other things that could be here: operators, as in TermInterface expressions, rewrite rules
        end
    end
    isnothing(multiplicity) && throw(ArgumentError("Missing numberof multiplicity subterm, expected :numberconstannt"))
    isnothing(instance) && throw(ArgumentError("Missing numberof instance subterm. Expected oprtator or constant, et al."))

    @show multiplicity multiplicity() #instance sortof(instance) #! term rewite _evaluate
    @show term = maketerm(Expr, :call, [:pnmlmultiset, isort, instance, multiplicity()], nothing)
    #return (term, isort) # `instance` should be a TermInterface term that has a toexpr() method.
    return (pnmlmultiset(isort, instance, multiplicity()), isort) # <numberof> instance not always ground term!
    maketerm()
#~ maketerm(::Type{Bag}, basis, x, multi, metadata)
end

function parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType)
    @error "parse_term(::Val{:feconstant} not implemented"
end

function parse_term(::Val{:unparsed}, node::XMLNode, pntd::PnmlType)
    @error "parse_term(::Val{:unparsed} not implemented"
end

function parse_term(::Val{:tuple}, node::XMLNode, pntd::PnmlType)
    @error "parse_term(::Val{:tuple} not implemented"
end

# <structure>
#   <useroperator declaration="id4"/>
# </structure>
function parse_term(::Val{:useroperator}, node::XMLNode, pntd::PnmlType)
    uo = UserOperator(Symbol(attribute(node, "declaration", "<useroperator> missing declaration")))
    #@warn "returning $uo"
    return (uo, sortof(uo))
end

function parse_term(::Val{:finiteintrangeconstant}, node::XMLNode, pntd::PnmlType)
    valuestr = attribute(node, "value")::String
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(MalformedException("<finiteintrangeconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    if sorttag == :finiteintrange
        startstr = attribute(child, "start")
        startval = tryparse(Int, startstr)
        isnothing(startval) &&
            throw(ArgumentError("start attribute value '$startstr' failed to parse as `Int`"))

        stopstr = attribute(child, "end") # XML Schema uses 'end', we use 'stop'.
        stopval = tryparse(Int, stopstr)
        isnothing(stopval) &&
            throw(ArgumentError("stop attribute value '$stopstr' failed to parse as `Int`"))

        value = tryparse(Int, valuestr)
        isnothing(value) &&
            throw(ArgumentError("value '$valuestr' failed to parse as `Int`"))

        if !(startval <= value && value <= stopval)
            throw(ArgumentError("$value not in range $(startval):$(stopval)"))
        end

        sort = FiniteIntRangeSort(startval, stopval)

        fis = nothing
        for (refid,nsort) in pairs(namedsorts()) # look for first equalSorts
            if equalSorts(sort, sortdefinition(nsort))
                @show refid nsort
                @show fis = usersort(refid)
                break
            end
        end
        if isnothing(fis) # Create a deduplicated sortdefinition
            ustag = Symbol(sorttag,"_",startstr,"_",stopstr)
            @show sort
            fill_sort_tag(ustag, "FIRConst"*"_"*startstr*"_"*stopstr, sort)
            fis = usersort(ustag)
        end
        @show typeof(fis) DECLDICT[]
        return (FiniteIntRangeConstant(value, fis), usersort(:integer)) #! TermInterface
    end
    throw(MalformedException("<finiteintrangeconstant> <finiteintrange> sort expected, found $sorttag"))
end

#====================================================================================#
#! partition is a sort declaration! not a sort.
#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_sort(::Val{:partition}, node::XMLNode, pntd::PnmlType)
    id = register_idof!(idregistry[], node)
    nameval = attribute(node, "name")
    @warn "partition $(repr(id)) $nameval"
    psort::Maybe{UserSort} = nothing
    elements = PartitionElement[] # References into sort that form a equivalance class.
    # First harvest the sort,
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # This is the sort that partitionelements reference.
            psort = parse_usersort(child, pntd)::UserSort
            # This wraps a REFID, actual declaration may be later?
        elseif tag === "partitionelement"
            parse_partitionelement!(elements, child)
        else
            throw(MalformedException(string("partition child element unknown: $tag, ",
                                "allowed are usersort, partitionelement")))
        end
    end
    isnothing(sort) &&
        throw(ArgumentError("<partition id=$id, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(id), ", name = ", repr(nameval), ", sort = ", repr(psort))

    #~verify_partition(sort, elements)

    return PartitionSort(id, nameval, psort.declaration, elements)
end

function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode)
    check_nodename(node, "partitionelement")
    id = register_idof!(idregistry[], node)
    nameval = attribute(node, "name")
    terms = Symbol[] # ordered collection of IDREF, usually useroperators (as constants)
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            # PartitionElements refer to the FEConstants of the referenced finite sort.
            # Useroperator holds an IDREF to a FEConstant operator.
            decl = attribute(child, "declaration")
            refid = Symbol(decl)
            PNML.has_feconstant(PNML.DECLDICT[], refid) ||
                error("re
                fid $refid not found in feconstants") #! move to verify?
            push!(terms, refid)
        else
            throw(MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$id, name=$nameval> has no terms"))

    push!(elements, PartitionElement(id, nameval, terms))
    return nothing
end
