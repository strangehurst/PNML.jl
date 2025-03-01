
# See `TermInterface.jl`, `Metatheory.jl`
"""
    parse_term(::XMLNode, ::PnmlType) -> (PnmlExpr, sort, vars)
    parse_term(::Val{:tag}::XMLNode, ::PnmlType) -> (PnmlExpr, sort, vars)

There will be no XML node `<term>`. Instead it is the interpertation of the child of a
`<structure>`, `<subterm>` or `<def>` element with a `nodename` of `tag`.

The Relax NG Schema does contain concept of an abstact "Term".
Concrete term kinds are `Variable` and `Operator`.

All terms have a sort, #TODO

Will be using `TermInterface.jl` to build an expression tree (AST) that can contain:
operators, constants (as 0-airity operators), and variables.

AST are evaluated for place initialMarking (ground terms only) and transition firing
where conditions and inscription expressions may contain non-ground terms (using variables).
"""
function parse_term(node::XMLNode, pntd::PnmlType; vars)
    tag = Symbol(EzXML.nodename(node))
    #printstyled("parse_term tag = $tag \n"; color=:bold); flush(stdout) #! debug
    ttup = if tag === :namedoperator
        # build & return an Operator Expression that has a vector of inputs.
        parse_operator_term(tag, node, pntd; vars)
    else
        #& Non-ground terms have arguments (variables that are bound to a marking value).
        #& Collect REFIDs
        parse_term(Val(tag), node, pntd; vars)
    end
    # ttup is a tuple(expression||literal, sort, vars)
    #!debug !isempty(ttup[3]) && @error ttup # parse_term returns `vars` in 3rd.
    return ttup
    #! Return something that can do toexpr(term)
    #! XXX do parse_term, parse_operator_term have same type XXX
    #! YES, if they are PnmlExpr! What if they are literals?
end

"""
    subterms(node, pntd; vars) -> Vector{PnmlExpr}

Unwrap each `<subterm>` and parse into a [`PnmlExpr`](@ref) term.
Collect variable REFIDs in `vars`.
"""
function subterms(node, pntd; vars)
    sts = Vector{Any}()
    for subterm in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(subterm)
        st, _, vars = parse_term(Val(tag), stnode, pntd; vars)
        isnothing(st) && throw(MalformedException("subterm is nothing"))
        push!(sts, st) #TODO vars?
    end
    #@show sts vars #! debug
    return sts, vars
end

"""
$(TYPEDSIGNATURES)

Build an [`Operator`](@ref) Functor from the XML tree at `node`.
"""
function parse_operator_term(tag::Symbol, node::XMLNode, pntd::PnmlType; vars)
    #printstyled("parse_operator_term: $(repr(tag))\n"; color=:green); #! debug
    @assert tag === :namedoperator
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

        (t, s, vars) = parse_term(subterm, pntd; vars) # term and its user sort

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
    return (Operator(tag, func, interms, insorts, outsort), outsort, vars)
end

#----------------------------------------------------------------------------------------
function parse_term(::Val{:variable}, node::XMLNode, pntd::PnmlType; vars)
    check_nodename(node, "variable")
    # References a VariableDeclaration. The 'primer' UML2 uses variableDecl.
    # Corrected to refvariable by Technical Corrigendum 1 to ISO/IEC 15909-2:2011.
    # Expect only an attribute referencing the declaration.
    var = VariableEx(Symbol(attribute(node, "refvariable"))) #! add SubstitutionDict
    usort = sortref(variable(var.refid))
    #@warn "parsed variable" var usort #! debug
    #! 2024-11-30 jdh add tuple of variable REFIDs. Empty tuple for ground terms.
    # vars are the keys of a NamedTuple
    return (var, usort, tuple(vars..., var.refid)) # expression for Variable with this UserSort
end

#----------------------------------------------------------------------------------------
# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType; vars)
    bc = BooleanConstant(attribute(node, "value"))
    return (BooleanEx(bc), usersort(:bool), vars) #TODO make into literal
end

# Has a value that is a subsort of NumberSort (<:Number).
function parse_term(::Val{:numberconstant}, node::XMLNode, pntd::PnmlType; vars)
    value = attribute(node, "value")::String
    child = EzXML.firstelement(node) # Child is the sort of value attribute.
    isnothing(child) && throw(MalformedException("<numberconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    sort = if sorttag in (:integer, :natural, :positive, :real) #  We allow non-standard real.
        usersort(sorttag)
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
    nc = NumberEx(sort, nv) #! expression
    return (nc, sort, vars)
end

# Dot is the high-level concept of an integer, use 1 as the value.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType; vars)
    return (DotConstant(), usersort(:dot), vars) #TODO XXX maketerm, toexpr -> ::DotConstant or 1
end


#~##############################
#~ Multiset Operator terms
#~##############################

# XML Examples
# <all><usersort declaration="N1"/></all>
# `<all>` operator creates a [`Bag`](@ref) that contains exactly one of each element a sort.
# Is a literal/ground term and can be used for intialMarking expressions.
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType; vars)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(MalformedException("<all> operator missing sort argument"))
    basis = parse_usersort(child, pntd)::UserSort # Can there be anything else?
    #! @assert isfinitesort(basis) #^ Only expect finite sorts here.
    return Bag(basis), basis, vars # expression that calls pnmlmultiset(basis)
end

# XML Examples
#    `<empty><usersort declaration="N1"/></empty>`
#    `<empty>/integer></empty>`
function parse_term(::Val{:empty}, node::XMLNode, pntd::PnmlType; vars)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(MalformedException("<empty> operator missing sort argument"))
    basis = parse_usersort(child, pntd)::UserSort # Can there be anything else?
    x = first(sortelements(basis)) # So Multiset can do eltype(basis) == typeof(x)
    # Can handle non-finite sets here.
    return Bag(basis, x, 0), basis, vars # expression that calls pnmlmultiset(basis, x, 0)
end

function parse_term(::Val{:add}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) >= 2
    return Add(sts), basis(first(sts)), vars # expression that calls pnmlmultiset(basis, sum_of_Multiset)
end

function parse_term(::Val{:subtract}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Subtract(sts), basis(first(sts)), vars #! toexpr(::Subtract) makes expression that calls pnmlmultiset(basis, difference_of_Multiset)
end

# The only example found:
# ```
# <scalarproduct>
#     <subterm>
#         <cardinality>
#             <subterm>
#                 <variable refvariable="id4"/>
#             </subterm>
#         </cardinality>
#     </subterm>
#     <subterm>
#         <variable refvariable="id4"/>
#     </subterm>
# </scalarproduct>
# ```
# The first subterm is an expression that evaluates to a natural number.
# The second subterm is an expression that evaluates to a PnmlMultiset.
#
# Notably, this differs from `:numberof` by both arguments being variables, NOT ground terms.
# As well as the 2nd being a multiset rather than a sort.
function parse_term(::Val{:scalarproduct}, node::XMLNode, pntd::PnmlType; vars)
    scalar = nothing # integer expression
    bag = nothing # Bag
    #! The ISO Standard does not give a name for the scalar term.
    #! ePNK-pnml-examples/release-0.9.0/MS-Bool-Int-technical-example.pnml
    #! is the only example, uses non-ground expressions, so we will too.

    st = EzXML.firstelement(node)
    stnode, tag = unwrap_subterm(st) #
    scalar, _, vars = parse_term(Val(tag), stnode, pntd; vars) #! PnmlExpr, UserSort
    #@assert scalar isa Integer # RealSort as scalar might confuse `Multiset.jl`.

    # this is a multiset/bag #! EXPRESSION, VARIABLE evaluating to one
    st = EzXML.nextelement(st)
    stnode, tag = unwrap_subterm(st)
    bag, _, vars = parse_term(Val(tag), stnode, pntd; vars)  #! Bag <: PnmlExpr, UserSort
    # isa(bag, Bag) &&
    #     throw(ArgumentError("<scalarproduct> operates on Bag<:PnmlExpr, found $(nameof(typeof(bag)))"))
    # end

    # isnothing(scalar) && throw(ArgumentError("Missing scalarproduct scalar subterm."))
    # isnothing(bag) && throw(ArgumentError("Missing scalarproduct multiset subterm."))
    return ScalarProduct(scalar, bag), basis(bag), vars #! PnmlExpr, UserSort, vars
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
# # XML Example
#     <numberof>
#         <subterm><numberconstant value="3"><positive/></numberconstant></subterm>
#         <subterm><dotconstant/></subterm>
#     </numberof>
function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType; vars)
    multiplicity = nothing
    instance = nothing
    isort = nothing
    for st in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(st)
        #@show tag
        if tag == :numberconstant && isnothing(multiplicity)
            multiplicity, _, vars = parse_term(Val(tag), stnode, pntd; vars) #! PnmlExpr, UserSort
            # RealSort as first numberconstant might confuse `Multiset.jl`.
            # Negative integers will cause problems. Don't do that either.
        else
            # If 2 numberconstants, first is `multiplicity`, this is `instance`.
            instance, isort, vars = parse_term(stnode, pntd; vars) #!  PnmlExpr, UserSort
            # @show instance isort
            isa(instance, MultisetSort) &&
                throw(ArgumentError("numberof's basis cannot be MultisetSort"))
        end
    end
    isnothing(multiplicity) &&
        throw(ArgumentError("Missing numberof multiplicity subterm. Expected :numberconstant"))
    isnothing(instance) &&
        throw(ArgumentError("Missing numberof instance subterm. Expected variable, operator or constant."))

    # Note how we evaluate the multiplicity PnmlExpr here as it is a constant.
    # Return of a sort is required because the sort may not be deducable from the expression,
    # Consider NaturalSort vs PositiveSort.
    return Bag(isort, instance, multiplicity), isort, vars #!  PnmlExpr, UserSort
end

function parse_term(::Val{:cardinality}, node::XMLNode, pntd::PnmlType; vars)
    subterm = EzXML.firstelement(node) # single argument subterm
    stnode, _ = unwrap_subterm(subterm)
    isnothing(stnode) && throw(MalformedException("<cardinality> missing argument subterm"))
    expr, _, vars = parse_term(stnode, pntd; vars) # PnmlExpr that eval(toexp) to a PnmlMultiset, includes variable.

    return Cardinality(expr), usersort(:natural), vars #!  PnmlExpr, UserSort toexpr(::Cardinality) >= 0
end

#^#########################################################################
#^ Booleans
#^#########################################################################

function parse_term(::Val{:or}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Or(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:and}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return And(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:not}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Not(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:imply}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Imply(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:equality}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    #@assert equalSorts(sts[1], sts[2]) #! sts is expressions, check after eval'ed.
    return Equality(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:inequality}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    #@assert equalSorts(sts[1], sts[2]) #! sts is expressions, check after eval'ed.
    return Inequality(sts[1], sts[2]), usersort(:bool), vars
end

#&#########################################################################
#& Cyclic Enumeration Operators
#&#########################################################################

function parse_term(::Val{:successor}, node::XMLNode, pntd::PnmlType); vars
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 1
    return Successor(sts[1]), usersort(:bool), vars
end

function parse_term(::Val{:predecessor}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 1
    return Predecessor(sts[1]), usersort(:bool), vars
end

#& FiniteIntRange Operators work on integrs in spec So use that implementation for
#& LessThan LessThanOrEqual GreaterThan GreaterThanOrEqual

function parse_term(::Val{:addition}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Addition(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:subtraction}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Subtraction(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:multiplication}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Multiplication(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:division}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Division(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:greaterthan}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return GreaterThan(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:lessthan}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return LessThan(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:lessthanorequal}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return LessThanOrEqual(sts[1], sts[2]), usersort(:bool), vars
end

function parse_term(::Val{:greaterthanorequal}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return GreaterThanOrEqual(sts[1], sts[2]), usersort(:bool),vars
end

function parse_term(::Val{:modulo}, node::XMLNode, pntd::PnmlType; vars)
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    return Modulo(sts[1], sts[2]), usersort(:bool), vars
end


# function parse_term(::Val{:}, node::XMLNode, pntd::PnmlType)
#     sts = subterms(node, pntd)
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

function parse_term(::Val{:unparsed}, node::XMLNode, pntd::PnmlType; vars)
    flush(stdout); @error "parse_term(::Val{:unparsed} not implemented"
end

function parse_term(::Val{:tuple}, node::XMLNode, pntd::PnmlType; vars)
    #@warn "parse_term(::Val{:tuple}"; flush(stdout); #! debug
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) >= 2
    tup = PnmlTupleEx(sts)
    # When turned into expressions and evaluated, each tuple element will have a sort,
    # the combination of element sorts must have a matching product sort.

    #!@show DECLDICT[]op.args
    # VariableEx can lookup sort.
    # UserOperatorEx (constant?) also has enclosng sort.
    # Both hold refid field.

    psorts = tuple((deduce_sort.(sts))...)
    for us in usersorts()
        if isproductsort(us.second) && sorts(sortof(us.second)) == psorts
            println("$psorts => ", us.first) #! debug
            return tup, usersort(us.first), vars
        end
    end
    error("Did not find productsort sort for $tup")
end

"Return sort REFID."
function deduce_sort(s)
    if s isa VariableEx
        refid(variable(s.refid))
    elseif s isa UserOperatorEx
        refid(feconstant(s.refid))
    else
        error("only expected Union{VariableEx,UserOperatorEx} found $s")
    end
end

# <structure>
#   <useroperator declaration="id4"/>
# </structure>
function parse_term(::Val{:useroperator}, node::XMLNode, pntd::PnmlType; vars)
    uo = UserOperatorEx(Symbol(attribute(node, "declaration", "<useroperator> missing declaration refid")))
    usort = sortref(PNML.operator(uo.refid))
    return (uo, usort, vars)
end

function parse_term(::Val{:finiteintrangeconstant}, node::XMLNode, pntd::PnmlType; vars)
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

        # Note: The specification specifically

        # if !any(nsort->equalSorts(sort, sortdefinition(nsort)), values(namedsorts()))
        #   create namedsort, usersort with ID derived from tag, start, stop.
        # else
        #   use the ID of the first matching sort.

        ustag = nothing
        for (refid, nsort) in pairs(namedsorts()) # look for first equalSorts
            if equalSorts(sort, sortdefinition(nsort))
                # @show refid nsort
                ustag = refid
                break
            end
        end
        # Create a deduplicated sortdefinition in scoped value
        if isnothing(ustag)
            ustag = Symbol(sorttag,"_",startstr,"_",stopstr)
            println("fill_sort_tag ",  repr(ustag), ", ", sort)
            fill_sort_tag(ustag, "FIRConst"*"_"*startstr*"_"*stopstr, sort)
            #fis = usersort(ustag)
        end
        return (value, usersort(ustag), vars) #! toexpr is identity for numbers
    end
    throw(MalformedException("<finiteintrangeconstant> <finiteintrange> sort expected, found $sorttag"))
end

#====================================================================================#
#! partition is a sort declaration! not a sort.
#=
Partition # id, name, usersort, partitionelement[]
=#
function parse_partition(node::XMLNode, pntd::PnmlType,)
    id = register_idof!(idregistry[], node)
    nameval = attribute(node, "name")
    #@warn "partition $(repr(id)) $nameval"; flush(stdout);  #! debug
    psort::Maybe{UserSort} = nothing
    elements = PartitionElement[] # References into psort that form a equivalance class.
    for child in EzXML.eachelement(node)
        tag = EzXML.nodename(child)
        if tag == "usersort" # The sort that partitionelements reference into.
            #TODO pass REFID?
            psort = parse_usersort(child, pntd)::UserSort #? sortof isa EnumerationSort
        elseif tag === "partitionelement" # Each holds REFIDs to sort elements of the enumeration.
            parse_partitionelement!(elements, child, id) # pass REFID to partition
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
function parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode, rid::REFID)
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
            PNML.has_feconstant(refid) ||
                error("refid $refid not found in feconstants") #! move to verify?
            push!(terms, refid)
        else
            throw(MalformedException("partitionelement child element unknown: $tag"))
        end
    end
    isempty(terms) && throw(ArgumentError("<partitionelement id=$id, name=$nameval> has no terms"))

    push!(elements, PartitionElement(id, nameval, terms, rid)) # rid is REFID to enclosing partition
    return nothing
end

"""
    parse_partitionelement!(elements::Vector{PartitionElement}, node::XMLNode)

Parse `<partitionelement>`, add FEconstant refids to the element and append element to the vector.
"""
function parse_term(::Val{:partitionelementof}, node::XMLNode, pntd::PnmlType; vars)
    check_nodename(node, "partitionelementof")
    refpartition = Symbol(attribute(node, "refpartition"))
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 1
    @show peo = PartitionElementOf(first(sts), refpartition) #! PnmlExpr
    #@show DECLDICT[]; flush(stdout; #! debug)
    return peo, usersort(refpartition), vars # UserSort duos used for all sort declarations.
end

"""
    `<gtp>` Partition element greater than.
"""
function parse_term(::Val{:gtp}, node::XMLNode, pntd::PnmlType; vars)
    @warn "parse_term(::Val{:gtp}"; flush(stdout); #! debug
    sts, vars = subterms(node, pntd; vars)
    @assert length(sts) == 2
    #@show sts # PartitionElementOps
    pe = PartitionGreaterThan(sts...) #! We have PnmlExpr elements at this point.
    #@show first(sts).refpartition Iterators.map(x->x.refpartition, sts)
    @assert all(==(first(sts).refpartition), Iterators.map(x->x.refpartition, sts))
    return pe, usersort(first(sts).refpartition), vars #todo! when can we map to partition
end
