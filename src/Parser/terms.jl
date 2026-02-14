"""
    TermJunk

`parse_term` returns a triple of: PnmlExpr, AbstractSortRef, NTuple{N,REFID}
"""
struct TermJunk{N, R <: AbstractSortRef}
    exp::Union{PnmlExpr,AbstractSortRef}
    ref::R
    vars::NTuple{N,REFID}
end

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
function parse_term(node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    tag = Symbol(EzXML.nodename(node))
    tag === :namedoperator && error("namedoperator is a declaration, not a term!")
    tjtuple = parse_term(Val(tag), node, pntd; vars, net)::TermJunk
    # tjtupel is (expression, sortref, vars) like all parse_term methods.
    # Collect varible REFIDs in `vars`. `length(vars) == 0` means is a ground term.
    # Ensure that there is a `toexpr` method. #! DEBUG only?
    if !isa(which(PNML.toexpr, (typeof(tjtuple.exp), NamedTuple, DeclDict)), Method)
        error("No `toexpr` method for expression in $(tjtuple)")
    end
    if tjtuple.exp isa Number
        @info "TermJunk expression is a Number $(tjtuple)"
    end
    return tjtuple
end

"""
    subterms(node, pntd; vars) -> Vector{PnmlExpr}, Tuple{REFID}

Unwrap each `<subterm>` and parse into a [`PnmlExpr`](@ref) term.
Collect expressions in a `Vector` and accumulate variable REFIDs in a `Tuple`.
"""
function subterms(node, pntd; vars, net::AbstractPnmlNet)
    sts = Vector{Any}()
    for subterm in EzXML.eachelement(node)
        if EzXML.nodename(subterm) == "subterm"
            stnode, tag = unwrap_subterm(subterm) # Used to dispatch on `Val(tag)`.
            tj = parse_term(Val(tag), stnode, pntd; vars, net)::TermJunk
            isnothing(tj) && throw(PNML.MalformedException("subterm is nothing"))
            vars = tj.vars
            push!(sts, tj.exp)
        else
            println("not a subterm ", EzXML.nodename(node))
            Base.show_backtrace(stdout, stacktrace())
        end
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
# function parse_operator_term(tag::Symbol, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet) #! ?User/Tested?
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
#                 vardecl = parse_variabledecl(vdecl, pntd; net)
#                 PNML.variabledecls(ctx.ddict)[pid(vardecl)] = vardecl
#                 push!(parms, vardecl)
#             end
#         elseif tag == "def"
#             # one expression, using parameter variables in parms
#             EzXML.firstelement(child)
#         else
#         check_nodename(child, "subterm")
#         subterm = EzXML.firstelement(child) # this is the unwrapped subterm

#         (t, s, vars) = parse_term(subterm, pntd; vars, net) # term and its user sort

#         # returns an AST #todo expand]
#         push!(interms, t) #! A PnmlTerm to later be toexpr'ed then eval'ed.
#         push!(insorts, s) #~ sort may be inferred from place, variable, operator output #! defer to eval time?
#     end
#     @assert length(interms) == length(insorts)
#     # for (t,s) in zip(interms,insorts) # Lots of output. Leave this here for debug, bring-up
#     #     @show t s
#     #     println()
#     # end
#     outsort = PNML.pnml_hl_outsort(tag; insorts, decldict(net)) #! some sorts need content

#     println("parse_operator_term returning $(repr(tag)) $(func)")
#     println("   interms ", interms)
#     println("   insorts ", insorts)
#     println("   outsort ", outsort)
#     println()
#     # maketerm(Expr, :call, [], nothing)
#     # :(func())
#     return (Operator(tag, func, interms, insorts, outsort), outsort, vars, net)
# end

#----------------------------------------------------------------------------------------
# `<variable refvariable="id5"/>`
function parse_term(::Val{:variable}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    check_nodename(node, "variable")
    # Expect only a reference to a VariableDeclaration. The 'primer' UML2 uses variableDecl.
    # Corrected to "refvariable" by Technical Corrigendum 1 to ISO/IEC 15909-2:2011.
    #^ ePNK uses inline variabledecl, variable in useroperator `<parameter>`, `<def>`.
    #^ Done inside `<declaration>`
    var_ex = VariableEx(Symbol(attribute(node, "refvariable")))
    usort = PNML.sortref(PNML.variabledecl(net, var_ex.refid))
    # vars will be the keys of a NamedTuple of substitutions &
    # the keys into the declaration dictionary of variable declarations.
    return TermJunk(var_ex, usort, tuple(vars..., var_ex.refid))
end

#----------------------------------------------------------------------------------------
# Has value "true"|"false" and is BoolSort.
function parse_term(::Val{:booleanconstant}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    bc = PNML.BooleanConstant(attribute(node, "value"))
    return TermJunk(PNML.BooleanEx(bc), UserSortRef(:bool), vars) #TODO make into literal
end

# Has a value that is a subsort of NumberSort (<:Number).
function parse_term(::Val{:numberconstant}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    value = attribute(node, "value")::String
    # Child is the sort of value attribute.
    child = EzXML.haselement(node) ? EzXML.firstelement(node) : nothing
    isnothing(child) &&
        throw(PNML.MalformedException("<numberconstant> missing sort element"))
    sorttag = Symbol(EzXML.nodename(child))
    sorttag in (:integer, :natural, :positive, :real) ||
        throw(PNML.MalformedException("sort not supported for :numberconstant: $sorttag"))

    sortref = NamedSortRef(sorttag)
    nv = PNML.number_value(eltype(to_sort(sortref, net)), value)
    # Bounds check not needed for IntegerSort, RealSort.
    if sorttag === :natural
        nv >= 0 || throw(ArgumentError("not a Natural Number: $nv"))
    elseif sorttag === :positive
        nv > 0 || throw(ArgumentError("not a Positive Number: $nv"))
    end
    nc = PNML.NumberEx(sortref, nv) #! expression
    return TermJunk(nc, sortref, vars)
end

# Dot is the high-level concept of an integer 1.
function parse_term(::Val{:dotconstant}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    return TermJunk(PNML.DotConstantEx(), NamedSortRef(:dot), vars)
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
function parse_term(::Val{:all}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(PNML.MalformedException("<all> operator missing sort argument"))
    # refsort is the basis of a multiset.
    refsort = parse_usersort(child, pntd; net)::AbstractSortRef
    @assert isa_variant(refsort, NamedSortRef)
    #! @assert isfinitesort(refsort) #^ Only expect finite sorts here.

    return TermJunk(PNML.Bag(refsort), refsort, vars) # :all
end

function parse_term(::Val{:empty}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    child = EzXML.firstelement(node) # Child is the one argument.
    isnothing(child) && throw(PNML.MalformedException("<empty> operator missing sort argument"))
    refsort = parse_usersort(child, pntd; net)::AbstractSortRef
    @assert isa_variant(refsort, NamedSortRef)
    #! ePNK uses <integer/>. Could be inlined productsort.
    x = first(PNML.sortelements(refsort, net)) # So Multiset can do eltype(basis) == typeof(x)
    # Can handle non-finite sets here.
    return TermJunk(PNML.Bag(refsort, x, 0), refsort, vars) # :empty
end

function parse_term(::Val{:add}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) >= 2
    return TermJunk(PNML.Add(sts), basis(first(sts))::AbstractSortRef, vars)
    # All are of same sort so we use the basis sort of first multiset.
end

function parse_term(::Val{:subtract}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Subtract(sts), basis(first(sts))::SorRef, vars)
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
function parse_term(::Val{:scalarproduct}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    stnode, tag = unwrap_subterm(EzXML.firstelement(node))
    tj1 = parse_term(Val(tag), stnode, pntd; vars, net)::TermJunk # scalar

    stnode, tag = unwrap_subterm(EzXML.nextelement(st))
    tj2 = parse_term(Val(tag), stnode, pntd; tj1.vars, net)::TermJunk # bag

    return TermJunk(PNML.ScalarProduct(tj1.exp, tj2.exp), basis(tj2.exp), tj2.vars)
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
function parse_term(::Val{:numberof}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    multiplicity = nothing # PnmlExpr
    instance = nothing # PnmlExpr
    isort = nothing
    for st in EzXML.eachelement(node)
        stnode, tag = unwrap_subterm(st)
        if tag == :numberconstant && isnothing(multiplicity)
            tj1 = parse_term(Val(tag), stnode, pntd; vars, net)::TermJunk
            multiplicity = tj1.exp
            vars = tj1.vars
            # RealSort as first numberconstant might confuse `Multiset.jl`.
            # Negative integers will cause problems. Don't do that either.
        else
            # If 2 numberconstants, first is `multiplicity`, this is `instance`.
            EzXML.nodename(stnode)
            tj2 = parse_term(stnode, pntd; vars, net)::TermJunk
            instance = tj2.exp # may be a bag
            isort = tj2.ref
            vars = tj2.vars
        end
    end
    isnothing(multiplicity) &&
        throw(ArgumentError("Missing numberof multiplicity subterm. Expected :numberconstant"))
    isnothing(instance) &&
        throw(ArgumentError("Missing numberof instance subterm. Expected variable, operator or constant."))

    #todo Note how the multiplicity PnmlExpr here is a constant. Evaluate it here?
    # Return of a sort is required because the sort may not be deducable from the expression,
    # Consider NaturalSort vs PositiveSort.
    # D()&& @show  isort instance multiplicity PNML.Bag(isort, instance, multiplicity)::PnmlExpr
    return TermJunk(PNML.Bag(isort, instance, multiplicity)::PnmlExpr, isort, vars) # :numberof
end

function parse_term(::Val{:cardinality}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    subterm = EzXML.firstelement(node) # single argument subterm
    stnode, _ = unwrap_subterm(subterm)
    isnothing(stnode) && throw(PNML.MalformedException("<cardinality> missing argument subterm"))
    (; exp, vars) = parse_term(stnode, pntd; vars, net)::TermJunk

    return TermJunk(PNML.Cardinality(exp)::PnmlExpr, NamedSortRef(:natural), vars)
end

# rhs multiset is contained in lhs multiset
function parse_term(::Val{:contains}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    @show sts # :contains sts[2] sts[1]
    @show pe = PNML.Contains(sts...) #! We have PnmlExpr elements at this point.
    #@show first(sts).refpartition Iterators.map(x->x.refpartition, sts)
    #@assert all(==(first(sts).refpartition), Iterators.map(x->x.refpartition, sts))
    return TermJunk(pe, NamedSortRef(:bool), vars)
end


#^#########################################################################
#^ Booleans
#^#########################################################################

function parse_term(::Val{:or}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    length(sts) >= 1 || @warn"or length wrong" sts # standard says 2, real world has 1
    return TermJunk(PNML.Or(sts), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:and}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    length(sts) >= 2 || @warn "and length wrong" sts
    return TermJunk(PNML.And(sts), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:not}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) >= 1 # OCL says 1, framework code wants >= 1
    return TermJunk(PNML.Not(sts), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:imply}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Imply(sts[1], sts[2]), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:equality}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Equality(sts[1], sts[2]), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:inequality}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Inequality(sts[1], sts[2]), NamedSortRef(:bool), vars)
end

#&#########################################################################
#& Cyclic Enumeration Operators
#&#########################################################################

function parse_term(::Val{:successor}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 1
    return TermJunk(PNML.Successor(sts[1]), NamedSortRef(:bool), vars) #! wrong sort
end

function parse_term(::Val{:predecessor}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 1
    return TermJunk(PNML.Predecessor(sts[1]), NamedSortRef(:bool), vars) #! wrong sort
end

#& FiniteIntRange Operators work on integrs so use that implementation for
#& LessThan LessThanOrEqual GreaterThan GreaterThanOrEqual

function parse_term(::Val{:addition}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Addition(sts[1], sts[2]), NamedSortRef(:bool), vars )#! wrong sort
end

function parse_term(::Val{:subtraction}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Subtraction(sts[1], sts[2]), NamedSortRef(:bool), vars )#! wrong sort
end

function parse_term(::Val{:mult}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Multiplication(sts[1], sts[2]), NamedSortRef(:bool), vars) #! wrong sort
end

function parse_term(::Val{:division}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Division(sts[1], sts[2]), NamedSortRef(:bool), vars) #! wrong sort
end

function parse_term(::Val{:greaterthan}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.GreaterThan(sts[1], sts[2]), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:lessthan}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.LessThan(sts[1], sts[2]), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:lessthanorequal}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.LessThanOrEqual(sts[1], sts[2]), NamedSortRef(:bool), vars)
end

function parse_term(::Val{:greaterthanorequal}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.GreaterThanOrEqual(sts[1], sts[2]), NamedSortRef(:bool),vars)
end

function parse_term(::Val{:modulo}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    return TermJunk(PNML.Modulo(sts[1], sts[2]), NamedSortRef(:bool), vars )#! wrong sort
end


##########################################################################

# """ #! feconstant always part of enumeration, in the declarations, are constants!
#     parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType) -> TBD
# # XML Example
# """
# function parse_term(::Val{:feconstant}, node::XMLNode, pntd::PnmlType)
#     @error "parse_term(::Val{:feconstant} not implemented"
# end

function parse_term(::Val{:unparsed}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    flush(stdout); @error "parse_term(::Val{:unparsed} not implemented"
end

function parse_term(::Val{:tuple}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    # Expect elements of tuple to be an operator or variable (a.k.a. term)
    @assert length(sts) > 0 # allow tuple of 1 item?
    expr_tup = PNML.PnmlTupleEx(sts)
    # When turned into expressions and evaluated, each tuple element will have a sort,
    # the combination of element sorts must have a matching product sort.

    # VariableEx can lookup sort.
    # UserOperatorEx (constant?) also has enclosing sort.
    # Both hold refid field.

    #! Needs to be returned from `sortof(term)` as `ProductSort(...)`.
    #! Part of expression evaluation -- dynamic behavior of a Petri net
    prodsort = ProductSort(tuple((expr_sortref.(sts, Ref(net)))...), net)
    #! prodsort = ProductSort(tuple(Iterators.map(refid, expr_sortref.(sts, net))), net)

    #D()&& @info "parse_term(::Val{:tuple}" sts expr_tup; #! debug

    # Look for an existing declaration for prodsort. Return a NamedSortRef to it in TermJunk.
    # Find matching sort
    sorttag = nothing
    for (id,ps) in pairs(productsorts(net))
        if PNML.Sorts.equalSorts(ps, prodsort, net)
            #@error "Found product sort $id while looking for $prodsort" productsorts(decldict(net))
            sorttag = id
        end
    end
    sortref = if isnothing(sorttag)
        sorttag = string("ProductSort_",
            join(Iterators.map(refid, expr_sortref.(sts, net)), "_")) |> Symbol

        # add to productsorts
        fill_sort_tag!(net, sorttag, prodsort)
        #@assert productsorts(net)[sorttag] == prodsort

        # make a user/named sort duo
        namedsorts(net)[sorttag] = NamedSort(sorttag, string(sorttag), prodsort, net)
        make_sortref(net, productsorts, prodsort, "product", sorttag, "") #! is above fill_sort_tag! redundant?
    else
        ProductSortRef(sorttag)
    end
    @assert isa_variant(sortref, ProductSortRef)
    return TermJunk(expr_tup, sortref, ())
end

# <structure>
#   <useroperator declaration="id4"/>
# </structure>
# See also `parse_namedoperator`
function parse_term(::Val{:useroperator}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    errmsg = "<useroperator> missing declaration refid"
    uo = PNML.UserOperatorEx(Symbol(attribute(node, "declaration", errmsg)))
    usort = PNML.sortref(PNML.operator(net, uo.refid))
    return TermJunk(uo, usort, vars)
end

function parse_term(::Val{:finiteintrangeconstant}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    valuestr = attribute(node, "value")::String
    value = tryparse(Int, valuestr)
    isnothing(value) && throw(ArgumentError("value '$valuestr' failed to parse as `Int`"))

    # Only element is the sort of `value`.
    child = EzXML.firstelement(node)
    isnothing(child) &&
        throw(PNML.MalformedException("<finiteintrangeconstant> missing sort element"))

    sorttag = Symbol(EzXML.nodename(child))
    sorttag == :finiteintrange ||
        throw(PNML.MalformedException("expected finiteintrange, found $sorttag"))

    # Note: The ISO 15909 Standard specifically allows (requires?) inline sorts here.
    #^ NB: inlining is used in ePNK test19
    usref = parse_sort(Val(:finiteintrange), child, pntd, nothing, ""; net)::AbstractSortRef

    # Differs from <tuple> in that here we have a sort definintion, while <tuple>
    # must deduce the sort by examining the product's sorts.
    fis = namedsort(net, refid(usref))::FiniteIntRangeSort
    Sorts.start(fis) <= value <= Sorts.stop(fis) ||
        throw(ArgumentError("finite integer value $value not in range $(ns)"))

    return TermJunk(NumberEx(usref, value), usref, vars)
end

#====================================================================================#

"""
    parse_partitionelementof(elements::Vector{PartitionElement}, node::XMLNode)

Parse `<partitionelement refpartition="id">`, add FEConstant refids to the element and append element to the vector.
"""
function parse_term(::Val{:partitionelementof}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    check_nodename(node, "partitionelementof")
    refpartition = Symbol(attribute(node, "refpartition"))
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 1
    peo = PNML.PartitionElementOf(first(sts), refpartition)
    return TermJunk(peo, PartitionSortRef(refpartition), vars)
end

"""
    `<gtp>` Partition element greater than.
"""
function parse_term(::Val{:gtp}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    sts, vars = subterms(node, pntd; vars, net)
    @assert length(sts) == 2
    #@show sts # PartitionElementOps
    pe = PNML.PartitionGreaterThan(sts...) #! We have PnmlExpr elements at this point.
    #@show first(sts).refpartition Iterators.map(x->x.refpartition, sts)
    @assert all(==(first(sts).refpartition), Iterators.map(x->x.refpartition, sts))
    return TermJunk(pe, PartitionSortRef(first(sts).refpartition), vars) #todo! when can we map to partition
end

#====================================================================================#
"""
    `<makelist>` Make a List
"""
function parse_term(::Val{:makelist}, node::XMLNode, pntd::PnmlType; vars, net::AbstractPnmlNet)
    D()&& @warn "parse_term(::Val{:makelist}"; flush(stdout); #! debug

    # One child will be a sort.
    # All other children will be subterms.

    sts = Vector{Any}()
    sortref = nothing
    for child in EzXML.eachelement(node)
        if EzXML.nodename(child) == "subterm"
            stnode, tag = unwrap_subterm(child) # Used to dispatch on `Val(tag)`.
            tj = parse_term(Val(tag), stnode, pntd; vars, net)::TermJunk
            isnothing(tj) && throw(PNML.MalformedException("subterm is nothing"))
            vars = tj.vars
            push!(sts, tj.exp)
        else
            sortref = parse_sort(child, pntd; net)
        end
    end

    if isnothing(sortref)
        # TODO deduce sort from first(sts)
    end
    #@show sortref
    #sts, vars = subterms(node, pntd; vars, net)
    #@show sts vars

    lex = PNML.ListEx(sortref, sts) #! We have PnmlExpr elements at this point.
    #@show first(sts).refpartition Iterators.map(x->x.refpartition, sts)
    #@assert all(==(first(sts).refpartition), Iterators.map(x->x.refpartition, sts))
    return TermJunk(lex, sortref, vars) #todo! when can we map to partition
end
