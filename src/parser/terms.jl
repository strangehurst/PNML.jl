
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
    if isoperator(tag)#! 2024-10-17 everything except a UserOperator
        return parse_term(Val(tag), node, pntd) #^ MUST be same type as parse_operator_term.
    else # arity > 0, build & return an Operator Functor that has a vector of inputs.
        @assert tag === :useroperator
        return parse_operator_term(tag, node, pntd)
    end
     #! Return something that can do toexpr(term)
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

    # maketerm() constructs
    # - Expr
    # - object with toexpr() that will make a Expr
    #   PnmlExpr that has a vector f arguments
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
    @warn "parse_term :variable"
    var = VariableEx(Symbol(attribute(node, "refvariable")))
    usort = sortref(variable(var.refid))
    return (var, usort) #! toexpr(var) is expression for Variable with this UserSort
end

# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType)
    bc = BooleanConstant(attribute(node, "value"))
    return (bc, sortof(bc)) #TODO XXX toexpr(::BooleanConstant)
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
        throw(MalformedException("sort not supported for :numberconstant: $sorttag"))
    end

    nv = number_value(eltype(sort), value)
    # Bounds check not needed for IntegerSort, RealSort.
    if sort isa NaturalSort
        nv >= 0 || throw(ArgumentError("not a Natural Number: $nv"))
    elseif sort isa PositiveSort
        nv > 0 || throw(ArgumentError("not a Positive Number: $nv"))
    end
    nc = NumberConstant(nv, sort) #! TermInterface rewrite to maketerm
    return (nc, sort) #TODO XXX maketerm, toexpr -> ::Number literal/constant
end

# Dot is the high-level concept of an integer, use 1 as the value.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType)
    return (DotConstant(), usersort(:dot)) #TODO XXX maketerm, toexpr -> ::DotConstant or 1
end

#~
#~ Multiset Operator terms
#~

# <all><usersort declaration="N1"/></all>
"""
    parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType) -> Bag

 `<all>` operator creates a [`Bag`](@ref) that contains exactly one of each element a sort.
 Is a literal/ground term and can be used for intialMarking expressions.

# XML Example
    `<all><usersort declaration="N1"/></all>`
"""
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(MalformedException("<all> operator missing sort argument"))
    basis = parse_usersort(child, pntd)::UserSort # Can there be anything else?
    #! @assert isfinitesort(basis) #^ Only expect finite sorts here.
    return Bag(basis), basis #! toexpr(::Bag) makes expression that calls pnmlmultiset(basis)
end

"""
    parse_term(::Val{:empty}, node::XMLNode, pntd::PnmlType) -> Bag

# XML Examples
    `<empty><usersort declaration="N1"/></empty>`
    `<empty>/integer></empty>`
"""
function parse_term(::Val{:empty}, node::XMLNode, pntd::PnmlType)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(MalformedException("<empty> operator missing sort argument"))
    basis = parse_usersort(child, pntd)::UserSort # Can there be anything else?
    x = first(sortelements(basis)) # So Multiset can do eltype(basis) == typeof(x)
    # Can handle non-finite sets here.
    return Bag(basis, x, 0), basis #! toexpr(::Bag) makes expression that calls pnmlmultiset(basis, x, 0)
end

"""
    parse_term(::Val{:add}, node::XMLNode, pntd::PnmlType) -> Add

Add multiset expressions.
# XML Example
"""
function parse_term(::Val{:add}, node::XMLNode, pntd::PnmlType)
    bags = Vector{Bag}()
    for subterm in EzXML.eachelement(node) # arguments are Bags
        stnode, tag = unwrap_subterm(subterm)
        bag, _ = parse_term(Val(tag), stnode, pntd)
        isnothing(bag) && throw(MalformedException("<add> operator argument missing"))
        #@show tag bag
        push!(bags, bag)
    end
    return Add(bags), basis(first(bags)) #! toexpr(::Add) makes expression that calls pnmlmultiset(basis, sum_of_Multiset)
end

"""
    parse_term(::Val{:subtract}, node::XMLNode, pntd::PnmlType) -> Subtract
# XML Example
"""
function parse_term(::Val{:subtract}, node::XMLNode, pntd::PnmlType)
    bags = Vector{Bag}()
    for subterm in EzXML.eachelement(node) # arguments are Bags
        stnode, tag = unwrap_subterm(subterm)
        bag, _ = parse_term(Val(tag), stnode, pntd)::Bag
        isnothing(bag) && throw(MalformedException("<add> operator argument missing"))
        push!(bags, bag)
    end
    @assert length(bags) == 2
    return Subtract(bags), basis(first(bags)) #! toexpr(::Subtract) makes expression that calls pnmlmultiset(basis, difference_of_Multiset)
end

"""
    parse_term(::Val{:scalarproduct}, node::XMLNode, pntd::PnmlType) -> ScalarProduct

# XML Example

The only example found:
```
<scalarproduct>
    <subterm>
        <cardinality>
            <subterm>
                <variable refvariable="id4"/>
            </subterm>
        </cardinality>
    </subterm>
    <subterm>
        <variable refvariable="id4"/>
    </subterm>
</scalarproduct>
```
The first subterm is an expression that evaluates to a natural number.

The second subterm is an expression that evaluates to a PnmlMultiset.

Notably, this differs from `:numberof` by both arguments being variables, NOT ground terms.
As well as the 2nd being a multiset rather than a sort.
"""
function parse_term(::Val{:scalarproduct}, node::XMLNode, pntd::PnmlType)
    scalar = nothing # integer expression
    bag = nothing # Bag
    #! The ISO Standard does not give a name for the scalar term.
    #! ePNK-pnml-examples/release-0.9.0/MS-Bool-Int-technical-example.pnml
    #! is the only example, uses non-ground expressions, so we will too.

    st = EzXML.firstelement(node)
    stnode, tag = unwrap_subterm(st) #
    scalar, _ = parse_term(Val(tag), stnode, pntd) #! PnmlExpr, UserSort
    #@assert scalar isa Integer # RealSort as scalar might confuse `Multiset.jl`.

    # this is a multiset/bag #! EXPRESSION, VARIABLE evaluating to one
    st = EzXML.nextelement(st)
    stnode, tag = unwrap_subterm(st)
    bag, _ = parse_term(Val(tag), stnode, pntd)  #! Bag <: PnmlExpr, UserSort
    # isa(bag, Bag) &&
    #     throw(ArgumentError("<scalarproduct> operates on Bag<:PnmlExpr, found $(nameof(typeof(bag)))"))
    # end

    # isnothing(scalar) && throw(ArgumentError("Missing scalarproduct scalar subterm."))
    # isnothing(bag) && throw(ArgumentError("Missing scalarproduct multiset subterm."))
    return ScalarProduct(scalar, bag), basis(bag) #! PnmlExpr, UserSort
end


# NamedSort declaration gives a name (and ID) to built-in sorts (and multisets, product sorts).
# Someday, ArbitrarySort declarations will also be supported.
# Note PartitionSort is a declaration like NamedSort and ArbitrarySort and (IS SUPPORTED. Where?)
# Partitions have name and ID, give structure to an enumeration.
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
"""
    parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType) -> Bag
# XML Example
    ```
    <numberof>
        <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
        <subterm><dotconstant/></subterm>
    </numberof>
    ```
"""
function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType)
    multiplicity = nothing
    instance = nothing
    isort = nothing
    for st in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(st) #
        if tag == :numberconstant && isnothing(multiplicity)
            multiplicity, _ = parse_term(Val(tag), stnode, pntd) #! PnmlExpr, UserSort
            # RealSort as first numberconstant might confuse `Multiset.jl`.
            # Negative integers will cause problems. Don't do that either.
        else
            # If 2 numberconstants, first is `multiplicity`, this is `instance`.
            instance, isort = parse_term(stnode, pntd) #!  PnmlExpr, UserSort
            @show instance isort
            isa(instance, MultisetSort) &&
                throw(ArgumentError("numberof's output basis cannot be MultisetSort"))
        end
    end
    isnothing(multiplicity) &&
        throw(ArgumentError("Missing numberof multiplicity subterm. Expected :numberconstant"))
    isnothing(instance) &&
        throw(ArgumentError("Missing numberof instance subterm. Expected variable, operator or constant."))

    # Note how we evaluate the multiplicity PnmlExpr here as it is a constant.
    # Return of a sort is required because the sort may not be deducable from the expression,
    # Consider NaturalSort vs PositiveSort.
    return Bag(isort, instance, multiplicity()), isort #!  PnmlExpr, UserSort
end

"""
    parse_term(::Val{:cardinality}, node::XMLNode, pntd::PnmlType) -> Natural
# XML Example
"""
function parse_term(::Val{:cardinality}, node::XMLNode, pntd::PnmlType)
    subterm = EzXML.firstelement(node) # single argument subterm
    stnode, _ = unwrap_subterm(subterm)
    isnothing(stnode) && throw(MalformedException("<cardinality> missing argument subterm"))
    expr, _ = parse_term(stnode, pntd) # PnmlExpr that eval(toexp) to a PnmlMultiset, includes variable.

    return Cardinality(expr), usersort(:natural) #!  PnmlExpr, UserSort toexpr(::Cardinality) >= 0
end

"""
    parse_term(::Val{:cardinality}, node::XMLNode, pntd::PnmlType) -> Natural
# XML Example
"""
function parse_term(::Val{:or}, node::XMLNode, pntd::PnmlType)
    sts = Vector{Any}()
    for subterm in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(subterm)
        @show st, _ = parse_term(Val(tag), stnode, pntd)
        isnothing(st) && throw(MalformedException("<or> operator argument missing"))
        push!(sts, st)
    end
    @show sts
    @assert length(sts) == 2
    return Or(sts[1], sts[2]), usersort(:bool)
end

#^#########################################################################
"""
    parse_term(::Val{:equality}, node::XMLNode, pntd::PnmlType) -> Natural
# XML Example
"""
function parse_term(::Val{:equality}, node::XMLNode, pntd::PnmlType)
    sts = Vector{Any}()
    for subterm in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(subterm)
        println("parse_term :equality arg ", repr(tag))
        @show st, _ = parse_term(Val(tag), stnode, pntd)
        isnothing(st) && throw(MalformedException("<equality> operator argument missing"))
        push!(sts, st)
    end
    @show sts
    @assert length(sts) == 2
    #@assert equalSorts(sts[1], sts[2]) #! sts is expressions, check after eval'ed.
    return Equality(sts[1], sts[2]), usersort(:bool)
end

"""
    parse_term(::Val{:inequality}, node::XMLNode, pntd::PnmlType) -> Natural
# XML Example
"""
function parse_term(::Val{:inequality}, node::XMLNode, pntd::PnmlType)
    sts = Vector{Any}()
    for subterm in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(subterm)
        println("parse_term :inequality arg ", repr(tag))
        @show st, _ = parse_term(Val(tag), stnode, pntd)
        isnothing(st) && throw(MalformedException("<inequality> operator argument missing"))
        push!(sts, st)
    end
    @show sts
    @assert length(sts) == 2
    @assert equalSorts(sts[1], sts[2])
    return Inequality(sts[1], sts[2]), usersort(:bool)
end

# """
#     parse_term(::Val{:}, node::XMLNode, pntd::PnmlType) -> Natural
# # XML Example
# """
# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType)
#     sts = Vector{Any}()
#     for subterm in EzXML.eachelement(node)
#         stnode, tag = unwrap_subterm(subterm)
#         @show st, _ = parse_term(Val(tag), stnode, pntd)
#         isnothing(st) && throw(MalformedException("<> operator argument missing"))
#         push!(sts, st)
#     end
#     @show sts
#     @assert length(sts) == 2
#     return (sts[1], sts[2]), usersort(:bool)
# end

# """
#     parse_term(::Val{:}, node::XMLNode, pntd::PnmlType) -> Natural
# # XML Example
# """
# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType)
#     sts = Vector{Any}()
#     for subterm in EzXML.eachelement(node)
#         stnode, tag = unwrap_subterm(subterm)
#         @show st, _ = parse_term(Val(tag), stnode, pntd)
#         isnothing(st) && throw(MalformedException("<> operator argument missing"))
#         push!(sts, st)
#     end
#     @show sts
#     @assert length(sts) == 2
#     return (sts[1], sts[2]), usersort(:bool)
# end

##########################################################################

# """ #! feconstant always part of enumeration, in the declarations, are constants!
#     parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType) -> TBD
# # XML Example
# """
# function parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType)
#     @error "parse_term(::Val{:feconstant} not implemented"
# end

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
    uo = UserOperator(Symbol(attribute(node, "declaration", "<useroperator> missing declaration refid")))
    @warn "returning $uo"
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

        ustag = nothing
        for (refid, nsort) in pairs(namedsorts()) # look for first equalSorts
            if equalSorts(sort, sortdefinition(nsort))
                @show refid nsort
                ustag = refid
                break
            end
        end
        #if !any(nsort->equalSorts(sort, sortdefinition(nsort)), values(namedsorts()))
        # Create a deduplicated sortdefinition
        if isnothing(ustag)
            ustag = Symbol(sorttag,"_",startstr,"_",stopstr)
            println("fill_sort_tag ",  repr(ustag), ", ", sort)
            fill_sort_tag(ustag, "FIRConst"*"_"*startstr*"_"*stopstr, sort)
            #fis = usersort(ustag)
        end
        #@show typeof(fis) # DECLDICT[]
        return (value, usersort(ustag)) #! toexpr is identity for numbers
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
    @warn "partition $(repr(id)) $nameval" #~ debug
    psort::Maybe{UserSort} = nothing
    elements = PartitionElement[] # References into psort that form a equivalance class.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # The sort that partitionelements reference into.
            psort = parse_usersort(child, pntd)::UserSort #? sortof isa EnumerationSort
        elseif tag === "partitionelement" # Each holds REFIDs to sort elements segment of the enumeration.
            parse_partitionelement!(elements, child)
        else
            throw(MalformedException(string("partition child element unknown: $tag, ",
                                "allowed are usersort, partitionelement")))
        end
    end
    isnothing(psort) &&
        throw(ArgumentError("<partition id=$id, name=$nameval> <usersort> element missing"))

    # One or more partitionelements.
    isempty(elements) &&
        error("partitions must have at least one partition element, found none: ",
                "id = ", repr(id), ", name = ", repr(nameval), ", sort = ", repr(psort))

    #~verify_partition(sort, elements)

    return PartitionSort(id, nameval, psort.declaration, elements)
end

"""
    parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode)

Parse `<partitionelement>`, add FEconstant refids to the element and append element to the vector.
"""
function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode)
    check_nodename(node, "partitionelement")
    id = register_idof!(idregistry[], node)
    nameval = attribute(node, "name")
    terms = REFID[] # ordered collection of IDREF, usually useroperators (as constants)
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag === "useroperator"
            # PartitionElements refer to the FEConstants of the referenced finite sort.
            # UserOperator holds an IDREF to a FEConstant operator.
            refid = Symbol(attribute(child, "declaration"))
            PNML.has_feconstant(PNML.DECLDICT[], refid) ||
                error("refid $refid not found in feconstants") #! move to verify?
            push!(terms, refid)
        else
            throw(MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$id, name=$nameval> has no terms"))

    push!(elements, PartitionElement(id, nameval, terms))
    return nothing
end
