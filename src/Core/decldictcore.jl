"""
    struct DeclDict

$(DocStringExtensions.TYPEDFIELDS)

Collection of dictionaries holding various kinds of PNML declarations.
Each keyed by REFID symbols.
"""
@kwdef struct DeclDict
    """
        Holds [`VariableDeclaration`](@ref).
        A [`Variable`](@ref) is used to locate the declaration's name and sort.
    """
    variabledecls::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # Built-in sorts live in named sorts. A sort declaration.
    namedsorts::Dict{Symbol, Any}     = Dict{Symbol, Any}()
    arbitrarysorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    partitionsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    multisetsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    productsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # OperatorDecls
    # namedoperators are also used to access built-in operators.
    namedoperators::Dict{Symbol, Any}     = Dict{Symbol, Any}()
    arbitraryoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol, Any}       = Dict{Symbol, Any}()
    # FEConstants are 0-ary OperatorDeclarations.
    feconstants::Dict{Symbol, Any}        = Dict{Symbol, Any}()

    # Use an REFID symbol as a network-level "global" to reference
    # SortDeclaration or OperatorDeclaration.
    #! 2025-07-14 moving to SortRefImpl to wrap a REFID and retain type information.
    #! 2025-09-27 moving to Moshi ADT.
    #! 2025-10-12 Remove UserSort. Use NamedSortRef where proper, UserSortRef when needed.

    useroperators::Dict{Symbol, Any} = Dict{Symbol, Any}() # Advanced users define ops?
end

# Explicit propeties allows ignoring metadata.
__dd_fields(dd) = Iterators.map(Fix1(getproperty, dd), (:namedsorts, :arbitrarysorts,
                        :multisetsorts, :productsorts, :partitionsorts,
                        :namedoperators, :arbitraryoperators, :useroperators,
                        :partitionops, :feconstants, :variabledecls))

Base.isempty(dd::DeclDict) = all(isempty, __dd_fields(dd))
Base.length(dd::DeclDict)  = sum(length,  __dd_fields(dd))

useroperators(dd::DeclDict)  = dd.useroperators
variabledecls(dd::DeclDict)  = dd.variabledecls
namedsorts(dd::DeclDict)     = dd.namedsorts
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
partitionsorts(dd::DeclDict) = dd.partitionsorts
namedoperators(dd::DeclDict) = dd.namedoperators
arbitraryops(dd::DeclDict)   = dd.arbitraryoperators
partitionops(dd::DeclDict)   = dd.partitionops
feconstants(dd::DeclDict)    = dd.feconstants
multisetsorts(dd::DeclDict)    = dd.multisetsorts
productsorts(dd::DeclDict)    = dd.productsorts #! put in namedsorts like FiniteItRangeSort

"""
    declarations(dd::DeclDict) -> Iterator

Return an iterator over all the declaration dictionaries' values.
"""
function declarations(dd::DeclDict)
    Iterators.flatten([
        values(variabledecls(dd)),

        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(multisetsorts(dd)),
        values(productsorts(dd)),

        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),

        values(useroperators(dd)),
    ])
end

has_key(dd::DeclDict, dict, key::Symbol)   = haskey(dict(dd),key)

has_variabledecl(dd::DeclDict, id::Symbol)   = has_key(dd, variabledecls, id)
has_namedsort(dd::DeclDict, id::Symbol)      = has_key(dd, namedsorts, id)
has_arbitrarysort(dd::DeclDict, id::Symbol)  = has_key(dd, arbitrarysorts, id)
has_partitionsort(dd::DeclDict, id::Symbol)  = has_key(dd, partitionsorts, id)
has_multisetsort(dd::DeclDict, id::Symbol)   = has_key(dd, multisetsorts, id)
has_productsort(dd::DeclDict, id::Symbol)    = has_key(dd, productsorts, id)
has_namedop(dd::DeclDict, id::Symbol)        = has_key(dd, namedoperators, id)
has_arbitraryop(dd::DeclDict, id::Symbol)    = has_key(dd, arbitraryops, id)
has_partitionop(dd::DeclDict, id::Symbol)    = has_key(dd, partitionops, id)
has_feconstant(dd::DeclDict, id::Symbol)     = has_key(dd, feconstants, id)
has_useroperator(dd::DeclDict, id::Symbol)   = has_key(dd, useroperators, id)

variabledecl(dd::DeclDict, id::Symbol)  = variabledecls(dd)[id]
namedsort(dd::DeclDict, id::Symbol)     = namedsorts(dd)[id]
arbitrarysort(dd::DeclDict, id::Symbol) = arbitrarysorts(dd)[id]
partitionsort(dd::DeclDict, id::Symbol) = partitionsorts(dd)[id]
multisetsort(dd::DeclDict, id::Symbol)  = multisetsorts(dd)[id]
productsort(dd::DeclDict, id::Symbol)   = productsorts(dd)[id]
namedop(dd::DeclDict, id::Symbol)       = namedoperators(dd)[id]
arbitraryop(dd::DeclDict, id::Symbol)   = arbitraryops(dd)[id]
partitionop(dd::DeclDict, id::Symbol)   = partitionops(dd)[id]
feconstant(dd::DeclDict, id::Symbol)    = feconstants(dd)[id]
useroperator(dd::DeclDict, id::Symbol)  = useroperators(dd)[id]

"Return tuple of operator dictionary fields in the Declaration Dictionaries."
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
"Return iterator over operator dictionaries of Declaration Dictionaries."
_ops(dd) = Iterators.map(Fix1(getfield, dd), _op_dictionaries())

"Return tuple of sort dictionary fields in the Declaration Dictionaries."
_sort_dictionaries() = (:namedsorts, :partitionsorts,
                        :arbitrarysorts, :multisetsorts, :productsorts)
"Return iterator over sort dictionaries of Declaration Dictionaries."
_sorts(dd) = Iterators.map(Fix1(getfield, dd), _sort_dictionaries())

"""
    operators(dd::DeclDict)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDict) = Iterators.flatten(Iterators.map(keys, _ops(dd)))

"Does any operator dictionary contain `id`?"
has_operator(dd::DeclDict, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))

"""
    operator(dd::DeclDict, id::Symbol) -> AbstractOperator

Return operator TermInterface expression for `id`.
    `toexpr(::AbstractOpExpr, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

Operator Declarations include:
:namedoperator, :feconstant, :partitionelement, :arbitraryoperator
with types
`NamedOperator`, `FEConstant`, `PartitionElement`, `ArbitraryOperator`.
These define operators of different types that are placed into separate dictionaries.


#! AbstractDeclarations and AbstractTerms are "parallel" semi-overlapping hierarchies
#! in the UML, with AbstractTerms divided into AbstractOperators and AbstractVariables.

#! AbstractTerms overlap with OperatorDeclaration and VariableDeclaration .
#! AbstractSorts overlap with SortDeclaration.

#! Consider OperatorDeclaration, SortDeclaration to be generators of concrete subtypes of
#! AbstractOperator, AbstractSort.
#! Without multiple inheritance, this cannot be expressed in a Julia type hiearchy.

#! What the 'parse_*' of these <declaration> XML elements produce is
#! a concrete AbstractOperator, AbstractSort.

#! VariableDeclaration and Variable are not hiearchies.
#! A `Varaible` is a reference to a `VariableDeclaration`,
#! The variable declaration is a id, name, sort triplet.
#! Where the sort is a SortRefImpl or a sort declaration.

useroperator(REFID) is used to locate the operator definition,
when it is found in `feconstants()`, is a callable returning a `FEConstant` literal.

    `toexpr(::FEConstantEx, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

The FEConstant operators defined by the declaration do not have a distinct type name in the standard.
Note that a FEConstant's value in the standard is its identity.
We could use `objectid(::FEConstant)`, `REFID` or `name` for output value.
Output sort of op is FEConstant.

Other `OperatorDeclaration` dictionarys also hold `TermInterface` expressions accessed by

    `toexpr(::PnmlExpr, varsub, ddict) = :(useroperator(ddict, REFID)(varsub))`

where `PnmlExpr` is the `TermInterface` to match `OperatorDeclaration`.
With output sort to match `OperatorDeclaration` .

#TODO named operator input variables and their sorts

#TODO partition element

#TODO arbitrary opearator

#TODO built-in operators
"""
function operator(dd::DeclDict, opid::Symbol)
    #println("operator($id)")
    for dict in _ops(dd) # Look through all the dictionaries.
        if haskey(dict, opid)
            #@show dict[opid]
            return dict[opid] #! not type stable because each dict holds different type.
        end
    end
    return nothing
end

"""
    verify(dd::DeclDict, verbose::Bool, net::AbstractPnmlNet) -> Bool
"""
function verify(dd::DeclDict, verbose::Bool, net::AbstractPnmlNet)
    errors = String[]
    verify!(errors, dd, verbose, net)
    isempty(errors) ||
        error("verify(::DeclDict) error(s):\n ", join(errors, ",\n "))
    return true
end

function verify!(errors::Vector{String}, dd::DeclDict, verbose::Bool, net::AbstractPnmlNet)
    verbose && println("## verify $(typeof(dd))")
    for k in Iterators.flatten([keys(variabledecls(dd)),
                            keys(namedsorts(dd)),
                            keys(arbitrarysorts(dd)),
                            keys(partitionsorts(dd)),
                            keys(multisetsorts(dd)),
                            keys(productsorts(dd)),
                            keys(partitionops(dd)),
                            keys(namedoperators(dd)),
                            keys(arbitraryops(dd)),
                            keys(feconstants(dd)),
                            keys(useroperators(dd))])
        isregistered(registry_of(net), k) ||
            push!(errors, string("unregisrered id $(repr(k))"))
    end
    for (k,v) in partitionsorts(dd)
        #@show v
        verify!(errors, v, verbose, net)
    end
    return errors
end


function show_sorts(dd::DeclDict)
    println("show_sorts")
    #@show _sort_dictionaries()
    foreach(_sort_dictionaries()) do s
        println("# ", s, ", length = ", length(getfield(dd, s)))
        foreach(getfield(dd, s)) do d
            println(repr(d.first), " => ", d.second)
        end
    end
    println()
end

"Look for matching value `x` in dictionary `d`, return key symbol or nothing."
function find_valuekey(d::AbstractDict, x, func=identity)
    id = nothing
    for (k,v) in pairs(skipmissing(d))
        if func(v) == x # Apply `func` to each value, looking for a match.
            id = k
            @warn("found existing $id for repr($x)")
            break
        end
    end
    return id #  Key of matched value or nothing.
end

"""
If `a` is a `NamedSortRef` return its `sortdefinition`, otherwise return `a`.
"""
unwrap_namedsort(a, net) = isnamedsort(a) ? sortdefinition(namedsort(net, refid(a))) : a
