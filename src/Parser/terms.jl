
# See `TermInterface.jl`, `Metatheory.jl`
"""
    parse_term(node::XMLNode, ::PnmlType; ddict) -> (PnmlExpr, sort, vars)
    parse_term(::Val{:tag}, node::XMLNode, ::PnmlType; ddict) -> (PnmlExpr, sort, vars)

`node` is a child of a `<structure>`, `<subterm>` or `<def>` element
with a `nodename` of `tag`.

All terms have a sort, #TODO ... document this XXX

Will be using `TermInterface.jl` to build an expression tree (AST) that can contain:
operators, constants (as 0-arity operators), and variables.

AST expressions are evaluated for:
    - place initial marking vector,
    - enabling rule and
    - firing rule
where condition and inscription expressions may contain non-ground terms (using variables).
"""
function parse_term(node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    tag = Symbol(EzXML.nodename(node))
    #printstyled("parse_term tag = $tag \n"; color=:bold); flush(stdout) #! debug
    ttup = if tag === :namedoperator
        error("namedoperator is a declarationnot a term!")
        #parse_operator_term(tag, node, pntd; vars, parse_context) # build expression
    else
        # Non-ground terms have arguments (variables that are bound to a marking vector value).
        # Collect varible REFIDs if found. length(vars) == 0 means is a ground term.
        parse_term(Val(tag), node, pntd; vars, parse_context)
    end
    # ttup is a tuple(expression, sort, vars) like all parse_term methods.
    # Ensure that there is a `toexpr` method. #! DEBUG only?
    @assert which(PNML.toexpr, (typeof(ttup[1]), NamedTuple, DeclDict)) isa Method
    return ttup
end

"""
    subterms(node, pntd; vars) -> Vector{PnmlExpr}

Unwrap each `<subterm>` and parse into a [`PnmlExpr`](@ref) term.
Collect expressions in a `Vector` and variable REFIDs in a `Tuple`.
"""
function subterms(node, pntd; vars, parse_context::ParseContext)
    sts = Vector{Any}()
    for subterm in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(subterm)
        st, _, vars = parse_term(Val(tag), stnode, pntd; vars, parse_context)
        isnothing(st) && throw(PNML.MalformedException("subterm is nothing"))
        push!(sts, st)
    end
    return sts, vars
end
#=
    ePNK-master/pnml-examples/org.pnml.tools.epnk.examples_1.2.0/hlpng/technical

            <namedoperator id="id3" name="sum">
              <parameter>
                <variabledecl id="id4" name="x">
                  <integer/>
                </variabledecl>
                <variabledecl id="id5" name="y">
                  <integer/>
                </variabledecl>
              </parameter>
              <def>
                <addition>
                  <subterm>
                    <variable refvariable="id4"/>
                  </subterm>
                  <subterm>
                    <variable refvariable="id5"/>
                  </subterm>
                </addition>
              </def>
            </namedoperator>

            <namedoperator id="id6" name="g">
              <parameter/>
              <def>
                <numberconstant value="1">
                  <positive/>
                </numberconstant>
              </def>
            </namedoperator>
=#

# """
# $(TYPEDSIGNATURES)

# SEE parse_namedoperator

# Build an [`Operator`](@ref) Functor from the XML tree at `node`.
# NB: NamedOperator is an AbstracrDeclaration, Operator is AbstractTerm.
# """
# function parse_operator_term(tag::Symbol, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext) #! ?User/Tested?
#     printstyled("parse_operator_term: $(repr(tag))\n"; color=:green); #! debug
#     check_nodename(node, "namedoperator")

#     #func = PNML.pnml_hl_operator(tag) #TODO! #! should be TermInterface to be to_expr'ed
#     # maketerm() constructs
#     # - Expr
#     # - object with toexpr() that will make a Expr
#     #   PnmlExpr that has a vector f arguments
#     parms = VariableDecl[]
#     insorts = UserSort[] # warapped REFID of sort declaration

#     # <parameter> 0 or more variable declaration
#     # <def> expression using parameters
#     # Extract the input term and sort from each <subterm>
#     for child in EzXML.eachelement(node)
#         tag = EzXML.nodename(child)
#         if tag == "parameter"
#             for vdecl in EzXML.eachelement(child)
#                 # zero or more variable declarations
#                 vardecl = parse_variabledecl(vdecl, pntd; parse_context)
#                 PNML.variabledecls(ctx.ddict)[pid(vardecl)] = vardecl
#                 push!(parms, vardecl)
#             end
#         elseif tag == "def"
#             # one expression, using parameter variables in parms
#             EzXML.firstelement(child)
#         else
#         check_nodename(child, "subterm")
#         subterm = EzXML.firstelement(child) # this is the unwrapped subterm

#         (t, s, vars) = parse_term(subterm, pntd; vars, parse_context) # term and its user sort

#         # returns an AST #todo expand]
#         push!(interms, t) #! A PnmlTerm to later be toexpr'ed then eval'ed.
#         push!(insorts, s) #~ sort may be inferred from place, variable, operator output #! defer to eval time?
#     end
#     @assert length(interms) == length(insorts)
#     # for (t,s) in zip(interms,insorts) # Lots of output. Leave this here for debug, bring-up
#     #     @show t s
#     #     println()
#     # end
#     outsort = PNML.pnml_hl_outsort(tag; insorts, parse_context.ddict) #! some sorts need content

#     println("parse_operator_term returning $(repr(tag)) $(func)")
#     println("   interms ", interms)
#     println("   insorts ", insorts)
#     println("   outsort ", outsort)
#     println()
#     # maketerm(Expr, :call, [], nothing)
#     # :(func())
#     return (Operator(tag, func, interms, insorts, outsort), outsort, vars, parse_context.ddict)
# end

#----------------------------------------------------------------------------------------
# `<variable refvariable="id5"/>`
function parse_term(::Val{:variable}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    check_nodename(node, "variable")
    # Expect only a reference to a VariableDeclaration. The 'primer' UML2 uses variableDecl.
    # Corrected to "refvariable" by Technical Corrigendum 1 to ISO/IEC 15909-2:2011.
    #^ ePNK uses inline variabledecl, variable  in useroperator `<parameter>`, `<def>`.
    #! Done inside `<declaration>`
    var_ex = VariableEx(Symbol(attribute(node, "refvariable")))
    usort = PNML.sortref(PNML.variable(parse_context.ddict, var_ex.refid))
    # vars will be the keys of a NamedTuple of substitutions &
    # the keys into the declaration dictionary of variable declarations.
    return (var_ex, usort, tuple(vars..., var_ex.refid))
end

#----------------------------------------------------------------------------------------
# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    bc = PNML.BooleanConstant(attribute(node, "value"), parse_context.ddict)
    return (PNML.BooleanEx(bc), usersorts(parse_context.ddict)[:bool], vars) #TODO make into literal
end

# Has a value that is a subsort of NumberSort (<:Number).
function parse_term(::Val{:numberconstant}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    value = attribute(node, "value")::String
    # Child is the sort of value attribute.
    child = EzXML.haselement(node) ? EzXML.firstelement(node) : nothing
    isnothing(child) &&
        throw(PNML.MalformedException("<numberconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    sort = if sorttag in (:integer, :natural, :positive, :real) #  We allow non-standard real.
        usersorts(parse_context.ddict)[sorttag]
    else
        throw(PNML.MalformedException("sort not supported for :numberconstant: $sorttag"))
    end

    nv = PNML.number_value(eltype(sort), value)
    # Bounds check not needed for IntegerSort, RealSort.
    if sort isa NaturalSort
        nv >= 0 || throw(ArgumentError("not a Natural Number: $nv"))
    elseif sort isa PositiveSort
        nv > 0 || throw(ArgumentError("not a Positive Number: $nv"))
    end
    nc = PNML.NumberEx(sort, nv) #! expression
    return (nc, sort, vars)
end

# Dot is the high-level concept of an integer 1.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    return (PNML.DotConstant(parse_context.ddict), usersorts(parse_context.ddict)[:dot], vars)
end


#~##############################
#~ Multiset Operator terms
#~##############################

# XML Examples
# `<all><usersort declaration="N1"/></all>`
# `<empty><usersort declaration="N1"/></empty>`
# `<all>` operator creates a [`Bag`](@ref) that contains exactly one of each element a sort.
# `<empty` is its dual: an empty `Bag` where each element of a sort has multiplicity of zero.
#
# Both are literal/ground terms and can be used for intialMarking expressions.
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(PNML.MalformedException("<all> operator missing sort argument"))
    basis = parse_usersort(child, pntd; parse_context)::UserSort # Can there be anything else?
    #! @assert isfinitesort(basis) #^ Only expect finite sorts here.
    return PNML.Bag(basis), basis, vars
end

function parse_term(::Val{:empty}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(PNML.MalformedException("<empty> operator missing sort argument"))
    basis = parse_usersort(child, pntd; parse_context)::UserSort # Can there be anything else?
    x = first(PNML.sortelements(basis)) # So Multiset can do eltype(basis) == typeof(x)
    # Can handle non-finite sets here.
    return PNML.Bag(basis, x, 0), basis, vars
end

function parse_term(::Val{:add}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) >= 2
    return PNML.Add(sts), basis(first(sts))::UserSort, vars
    # All are of same sort so we use the basis sort of first multiset.
end

function parse_term(::Val{:subtract}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Subtract(sts), basis(first(sts))::UserSort, vars
end

#! ePNK-pnml-examples/release-0.9.0/MS-Bool-Int-technical-example.pnml
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
function parse_term(::Val{:scalarproduct}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    scalar = nothing
    bag = nothing # Bag

    st = EzXML.firstelement(node)
    stnode, tag = unwrap_subterm(st)
    scalar, _, vars = parse_term(Val(tag), stnode, pntd; vars, parse_context)
    #@assert scalar isa Integer expression # Real as scalar might confuse `Multiset.jl`.

    st = EzXML.nextelement(st)
    stnode, tag = unwrap_subterm(st)
    bag, _, vars = parse_term(Val(tag), stnode, pntd; vars, parse_context)
    # isa(bag, Bag) &&
    #     throw(ArgumentError("<scalarproduct> operates on Bag<:PnmlExpr, found $(nameof(typeof(bag)))"))
    # end

    # isnothing(scalar) && throw(ArgumentError("Missing scalarproduct scalar subterm."))
    # isnothing(bag) && throw(ArgumentError("Missing scalarproduct multiset subterm."))
    return PNML.ScalarProduct(scalar, bag)::PnmlExpr, basis(bag)::UserSort, vars
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
function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    multiplicity = nothing
    instance = nothing
    isort = nothing
    for st in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(st)
        #@show tag
        if tag == :numberconstant && isnothing(multiplicity)
            multiplicity, _, vars = parse_term(Val(tag), stnode, pntd; vars, parse_context)
            # RealSort as first numberconstant might confuse `Multiset.jl`.
            # Negative integers will cause problems. Don't do that either.
        else
            # If 2 numberconstants, first is `multiplicity`, this is `instance`.
            instance, isort, vars = parse_term(stnode, pntd; vars, parse_context)
            isa(instance, MultisetSort) &&
                throw(ArgumentError("numberof's basis cannot be MultisetSort"))
        end
    end
    isnothing(multiplicity) &&
        throw(ArgumentError("Missing numberof multiplicity subterm. Expected :numberconstant"))
    isnothing(instance) &&
        throw(ArgumentError("Missing numberof instance subterm. Expected variable, operator or constant."))

    #todo Note how the multiplicity PnmlExpr here is a constant. Evaluate it here?
    # Return of a sort is required because the sort may not be deducable from the expression,
    # Consider NaturalSort vs PositiveSort.
    return PNML.Bag(isort, instance, multiplicity)::PnmlExpr, isort, vars
end

function parse_term(::Val{:cardinality}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    subterm = EzXML.firstelement(node) # single argument subterm
    stnode, _ = unwrap_subterm(subterm)
    isnothing(stnode) && throw(PNML.MalformedException("<cardinality> missing argument subterm"))
    expr, _, vars = parse_term(stnode, pntd; vars, parse_context)

    return PNML.Cardinality(expr)::PnmlExpr, usersorts(parse_context.ddict)[:natural], vars
end

#^#########################################################################
#^ Booleans
#^#########################################################################

function parse_term(::Val{:or}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) >= 2
    return PNML.Or(sts), usersorts(parse_context.ddict)[:bool], vars
end

function parse_term(::Val{:and}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) >= 2
    return PNML.And(sts), usersorts(parse_context.ddict)[:bool], vars
end

function parse_term(::Val{:not}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @show sts
    @assert length(sts) >= 1 # OCL says 1, framework code wants >= 1
    return PNML.Not(sts), usersorts(parse_context.ddict)[:bool], vars
end

function parse_term(::Val{:imply}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Imply(sts[1], sts[2]), usersorts(parse_context.ddict)[:bool], vars
end

function parse_term(::Val{:equality}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    #@assert equalS(sts[1], sts[2]) #! sts is expressions, check after eval'ed.
    return PNML.Equality(sts[1], sts[2]), usersorts(parse_context.ddict)[:bool], vars
end

function parse_term(::Val{:inequality}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    #@assert equal(sts[1], sts[2]) #! sts is expressions, check after eval'ed.
    return PNML.Inequality(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars
end

#&#########################################################################
#& Cyclic Enumeration Operators
#&#########################################################################

function parse_term(::Val{:successor}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 1
    return PNML.Successor(sts[1]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end

function parse_term(::Val{:predecessor}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 1
    return PNML.Predecessor(sts[1]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end

#& FiniteIntRange Operators work on integrs so use that implementation for
#& LessThan LessThanOrEqual GreaterThan GreaterThanOrEqual

function parse_term(::Val{:addition}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Addition(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end

function parse_term(::Val{:subtraction}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Subtraction(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end

function parse_term(::Val{:mult}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Multiplication(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end

function parse_term(::Val{:division}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Division(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end

function parse_term(::Val{:greaterthan}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.GreaterThan(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars
end

function parse_term(::Val{:lessthan}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.LessThan(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars
end

function parse_term(::Val{:lessthanorequal}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.LessThanOrEqual(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars
end

function parse_term(::Val{:greaterthanorequal}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.GreaterThanOrEqual(sts[1], sts[2]), usersort(parse_context.ddict, :bool),vars
end

function parse_term(::Val{:modulo}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    return PNML.Modulo(sts[1], sts[2]), usersort(parse_context.ddict, :bool), vars #! wrong sort
end


##########################################################################

# """ #! feconstant always part of enumeration, in the declarations, are constants!
#     parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType) -> TBD
# # XML Example
# """
# function parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType)
#     @error "parse_term(::Val{:feconstant} not implemented"
# end

function parse_term(::Val{:unparsed}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    flush(stdout); @error "parse_term(::Val{:unparsed} not implemented"
end

function parse_term(::Val{:tuple}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    #@warn "parse_term(::Val{:tuple}"; flush(stdout); #! debug
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) >= 2
    tup = PNML.PnmlTupleEx(sts)
    # When turned into expressions and evaluated, each tuple element will have a sort,
    # the combination of element sorts must have a matching product sort.

    # VariableEx can lookup sort.
    # UserOperatorEx (constant?) also has enclosng sort.
    # Both hold refid field.

    psorts = tuple((deduce_sort.(sts; parse_context.ddict))...)
    for us in PNML.usersorts(parse_context.ddict)
        if Sorts.isproductsort(us.second) && Sorts.sorts(sortof(us.second)) == psorts
            # println("$psorts => ", us.first) #! debug
            return tup, PNML.usersort(parse_context.ddict, us.first), vars
        end
    end
    error("Did not find productsort sort for $tup")
end

"Return sort REFID."
function deduce_sort(s; ddict)
    if s isa PNML.VariableEx
        PNML.refid(PNML.variable(ddict, s.refid))
    elseif s isa PNML.UserOperatorEx
        PNML.refid(PNML.feconstant(ddict, s.refid))
    else
        error("only expected Union{VariableEx,UserOperatorEx} found $s")
    end
end

# <structure>
#   <useroperator declaration="id4"/>
# </structure>
# See also `parse_namedoperator`
function parse_term(::Val{:useroperator}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    uo = PNML.UserOperatorEx(Symbol(attribute(node, "declaration", "<useroperator> missing declaration refid")))
    usort = PNML.sortref(PNML.operator(parse_context.ddict, uo.refid))
    return (uo, usort, vars)
end

function parse_term(::Val{:finiteintrangeconstant}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    valuestr = attribute(node, "value")::String
    child = EzXML.firstelement(node) # Child is the sort of value
    isnothing(child) && throw(PNML.MalformedException("<finiteintrangeconstant> missing sort element"))
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

        sort = Sorts.FiniteIntRangeSort(startval, stopval)

        # Note: The specification specifically

        # if !any(nsort -> equal(sort, sortdefinition(nsort)), values(PNML.namedsorts()))
        #   create namedsort, usersort with ID derived from tag, start, stop.
        # else
        #   use the ID of the first matching sort.

        ustag = nothing
        for (refid, nsort) in pairs(PNML.namedsorts()) # look for first equal Sorts
            if equal(sort, sortdefinition(nsort))
                # @show refid nsort
                ustag = refid
                break
            end
        end
        # Create a deduplicated sortdefinition in scoped value
        if isnothing(ustag)
            ustag = Symbol(sorttag,"_",startstr,"_",stopstr)
            println("fill_sort_tag ",  repr(ustag), ", ", sort)
            PNML.fill_sort_tag!(parse_context, ustag, "FIRConst"*"_"*startstr*"_"*stopstr, sort)
            #fis = usersort(ustag)
        end
        return (value, usersort(parse_context.ddict, ustag), vars) #! toexpr is identity for numbers
    end
    throw(PNML.MalformedException("<finiteintrangeconstant> <finiteintrange> sort expected, found $sorttag"))
end

#====================================================================================#

"""
    parse_partitionelementof(elements::Vector{PartitionElement}, node::XMLNode)

Parse `<partitionelement refpartition="id">`, add FEConstant refids to the element and append element to the vector.
"""
function parse_term(::Val{:partitionelementof}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    check_nodename(node, "partitionelementof")
    refpartition = Symbol(attribute(node, "refpartition"))
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 1
    peo = PNML.PartitionElementOf(first(sts), refpartition)
    return peo, usersort(parse_context.ddict, refpartition), vars # UserSort duos used for all sort declarations.
end

"""
    `<gtp>` Partition element greater than.
"""
function parse_term(::Val{:gtp}, node::XMLNode, pntd::PnmlType; vars, parse_context::ParseContext)
    @warn "parse_term(::Val{:gtp}"; flush(stdout); #! debug
    sts, vars = subterms(node, pntd; vars, parse_context)
    @assert length(sts) == 2
    #@show sts # PartitionElementOps
    pe = PNML.PartitionGreaterThan(sts...) #! We have PnmlExpr elements at this point.
    #@show first(sts).refpartition Iterators.map(x->x.refpartition, sts)
    @assert all(==(first(sts).refpartition), Iterators.map(x->x.refpartition, sts))
    return pe, usersort(parse_context.ddict, first(sts).refpartition), vars #todo! when can we map to partition
end
