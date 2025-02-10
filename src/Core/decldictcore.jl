"""
    struct DeclDict

$(DocStringExtensions.TYPEDFIELDS)

Collection of dictionaries holding various kinds of PNML declarations.
Each keyed by REFID symbols.
"""
@kwdef struct DeclDict
    variabledecls::Dict{Symbol, Any} = Dict{Symbol, Any}()

    namedsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    arbitrarysorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    partitionsorts::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # OperatorDecls include: namedoperator, feconstant, partition element, et al.
    # namedoperators are used to access built-in operators
    namedoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    arbitraryoperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # PartitionElement is an operator, there are other built-in operators
    partitionops::Dict{Symbol, Any} = Dict{Symbol, Any}()
    # FEConstants are 0-ary OperatorDeclarations.
    feconstants::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # AllowsThese use an IDREF symbol as a network-level "global" by referencing  abstract
    # SortDeclaration or Operatordeclaration.
    usersorts::Dict{Symbol, Any} = Dict{Symbol, Any}()
    useroperators::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

_decldict_fields = (:namedsorts, :arbitrarysorts,
                    :namedoperators, :arbitraryoperators,
                    :variabledecls,
                    :partitionsorts, :partitionops, :feconstants,
                    :usersorts, :useroperators)

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) = all(isempty, Iterators.map(Fix1(getproperty,dd), _decldict_fields))
Base.length(dd::DeclDict)  = sum(length,  Iterators.map(Fix1(getproperty,dd), _decldict_fields))

"Return dictonary of UserSort"
usersorts(dd::DeclDict)      = dd.usersorts
"Return dictonary of UserOperator"
useroperators(dd::DeclDict)  = dd.useroperators
"Return dictonary of VariableDecl"
variabledecls(dd::DeclDict)  = dd.variabledecls
"Return dictonary of NamedSort"
namedsorts(dd::DeclDict)     = dd.namedsorts
"Return dictonary of ArbitrarySort"
arbitrarysorts(dd::DeclDict) = dd.arbitrarysorts
"Return dictonary of PartitionSort"
partitionsorts(dd::DeclDict) = dd.partitionsorts
"Return dictonary of NamedOperator"
namedoperators(dd::DeclDict) = dd.namedoperators
"Return dictonary of ArbitraryOperator"
arbitraryops(dd::DeclDict)   = dd.arbitraryoperators
"Return dictonary of partitionops (PartitionElement)"
partitionops(dd::DeclDict)   = dd.partitionops
"Return dictonary of FEConstant"
feconstants(dd::DeclDict)    = dd.feconstants

# Default to ScopedValue
usersorts()      = usersorts(PNML.DECLDICT[])
useroperators()  = useroperators(PNML.DECLDICT[])
variabledecls()  = variabledecls(PNML.DECLDICT[])
namedsorts()     = namedsorts(PNML.DECLDICT[])
arbitrarysorts() = arbitrarysorts(PNML.DECLDICT[])
partitionsorts() = partitionsorts(PNML.DECLDICT[])
namedoperators() = namedoperators(PNML.DECLDICT[])
arbitraryops()   = arbitraryops(PNML.DECLDICT[])
partitionops()   = partitionops(PNML.DECLDICT[])
feconstants()    = feconstants(PNML.DECLDICT[])


"""
    declarations(dd::DeclDict) -> Iterator

Return an iterator over all the declaration dictionaries' values.
Flattens iterators: variabledecls, namedsorts, arbitrarysorts, partitionsorts, partitionops,
namedoperators, arbitraryops, feconstants, usersorts, useroperators.
"""
function declarations(dd::DeclDict)
    Iterators.flatten([
        values(variabledecls(dd)),
        values(namedsorts(dd)),
        values(arbitrarysorts(dd)),
        values(partitionsorts(dd)),
        values(partitionops(dd)),
        values(namedoperators(dd)),
        values(arbitraryops(dd)),
        values(feconstants(dd)),
        values(usersorts(dd)),
        values(useroperators(dd)),
    ])
end

has_variabledecl(dd::DeclDict, id::Symbol)   = haskey(variabledecls(dd), id)
has_namedsort(dd::DeclDict, id::Symbol)      = haskey(namedsorts(dd), id)
has_arbitrarysort(dd::DeclDict, id::Symbol)  = haskey(arbitrarysorts(dd), id)
has_partitionsort(dd::DeclDict, id::Symbol)  = haskey(partitionsorts(dd), id)
has_namedop(dd::DeclDict, id::Symbol)        = haskey(namedoperators(dd), id)
has_arbitraryop(dd::DeclDict, id::Symbol)    = haskey(arbitraryops(dd), id)
has_partitionop(dd::DeclDict, id::Symbol)    = haskey(partitionops(dd), id)
has_feconstant(dd::DeclDict, id::Symbol)     = haskey(feconstants(dd), id)
has_usersort(dd::DeclDict, id::Symbol)       = haskey(usersorts(dd), id)
has_useroperator(dd::DeclDict, id::Symbol)   = haskey(usersorts(dd), id)

has_variabledecl(id::Symbol)  = has_variabledecl(PNML.DECLDICT[], id)
has_namedsort(id::Symbol)     = has_namedsort(PNML.DECLDICT[], id)
has_arbitrarysort(id::Symbol) = has_arbitrarysort(PNML.DECLDICT[], id)
has_partitionsort(id::Symbol) = has_partitionsort(PNML.DECLDICT[], id)
has_namedop(id::Symbol)       = has_namedop(PNML.DECLDICT[], id)
has_arbitraryop(id::Symbol)   = has_arbitraryop(PNML.DECLDICT[], id)
has_partitionop(id::Symbol)   = has_partitionop(PNML.DECLDICT[], id)
has_feconstant(id::Symbol)    = has_feconstant(PNML.DECLDICT[], id)
has_usersort(id::Symbol)      = has_usersort(PNML.DECLDICT[], id)
has_useroperator(id::Symbol)  = has_useroperator(PNML.DECLDICT[], id)

variable(dd::DeclDict, id::Symbol)       = variabledecls(dd)[id]
namedsort(dd::DeclDict, id::Symbol)      = namedsorts(dd)[id]
arbitrarysort(dd::DeclDict, id::Symbol)  = arbitrarysorts(dd)[id]
partitionsort(dd::DeclDict, id::Symbol)  = partitionsorts(dd)[id]
namedop(dd::DeclDict, id::Symbol)        = namedoperators(dd)[id]
arbitrary_op(dd::DeclDict, id::Symbol)   = arbitraryoperators(dd)[id]
partitionop(dd::DeclDict, id::Symbol)    = partitionops(dd)[id]
feconstant(dd::DeclDict, id::Symbol)     = feconstants(dd)[id]
usersort(dd::DeclDict, id::Symbol)       = usersorts(dd)[id]
useroperator(dd::DeclDict, id::Symbol)   = useroperators(dd)[id]

variable(id::Symbol)       = variabledecls(PNML.DECLDICT[])[id]
namedsort(id::Symbol)      = namedsorts(PNML.DECLDICT[])[id]
arbitrarysort(id::Symbol)  = arbitrarysorts(PNML.DECLDICT[])[id]
partitionsort(id::Symbol)  = partitionsorts(PNML.DECLDICT[])[id]
namedop(id::Symbol)        = namedoperators(PNML.DECLDICT[])[id]
arbitrary_op(id::Symbol)   = arbitraryoperators(PNML.DECLDICT[])[id]
partitionop(id::Symbol)    = partitionops(PNML.DECLDICT[])[id]
feconstant(id::Symbol)     = feconstants(PNML.DECLDICT[])[id]
usersort(id::Symbol)       = usersorts(PNML.DECLDICT[])[id]
useroperator(id::Symbol)   = useroperators(PNML.DECLDICT[])[id]

#TODO :useroperator -> opdictionary -> op  # how type-stable is this?
"Return tuple of operator dictionary fields in the Declaration Dictionaries."
_op_dictionaries() = (:namedoperators, :feconstants, :partitionops, :arbitraryoperators)
"Return iterator over operator dictionaries of Declaration Dictionaries."
_ops(dd) = Iterators.map(Fix1(getfield, dd), _op_dictionaries())

"Return tuple of sort dictionary fields in the Declaration Dictionaries."
_sort_dictionaries() = (:namedsorts, :usersorts, :partitionsorts, :arbitrarysorts)
"Return iterator over sort dictionaries of Declaration Dictionaries."
_sorts(dd) = Iterators.map(Fix1(getfield, dd), _sort_dictionaries())

"""
    operators(dd::DeclDict)-> Iterator
Iterate over each operator in the operator subset of declaration dictionaries .
"""
operators(dd::DeclDict) = Iterators.flatten(Iterators.map(keys, _ops(dd)))
operators() = operators(PNML.DECLDICT[])

"Does any operator dictionary contain `id`?"
has_operator(dd::DeclDict, id::Symbol) = any(opdict -> haskey(opdict, id), _ops(dd))
has_operator(id::Symbol) = has_operator(PNML.DECLDICT[], id)

#! Change first to only when de-duplication implementd? as test?
"Return operator dictionary containing key `id`."
_get_op_dict(dd::DeclDict, id::Symbol) = first(Iterators.filter(Fix2(haskey, id), _ops(dd)))

"""
    operator(dd::DeclDict, id::Symbol) -> AbstractOperator
    operator(id::Symbol) -> AbstractOperator

Return operator TermInterface expression for `id`.
    `toexpr(::OpExpr, varsub) = :(useroperator(REFID)(varsub))`

"Operator Declarations" include: :namedoperator, :feconstant, :partitionelement, :arbitraryoperator
with types `NamedOperator`, `FEConstant`, `PartitionElement`, `ArbitraryOperator`.
These define operators of different types that are placed into separate dictionaries.

#! CORRECT AbstractOperator type hierarchy that has `Operator` as concrete type.
#! AbstractDeclarations and AbstractTerms are "parallel" hierarchies in the UML,
#! with AbstractTerms divided into AbstractOperators and AbstractVariables.

useroperator(REFID) is used to locate the operator definition, when it is found in `feconstants()`,
is a callable returning a `FEConstant` literal.

    `toexpr(::FEConstantEx, varsub) = :(useroperator(REFID)(varsub))`

The FEConstant operators defined by the declaration do not have a distinct type name in the specification.
Note that a FEConstant's value in the specification is its identity.
We could use `objectid(::FEConstant)`, `REFID` or `name` for output value.
Output sort of op is FEConstant.

Other `OperatorDeclaration` dictionarys also hold `TermInterface` expressions accessed by

    `toexpr(::OpExpr, varsub) = :(useroperator(REFID)(varsub))`

where `OpExpr` is the `TermInterface` to match `OperatorDeclaration`.
With output sort to match `OperatorDeclaration` .

#TODO named operator input variables and thier sorts

#TODO partition element

#TODO arbitrary opearator

#TODO built-in operators
"""
function operator(dd::DeclDict, opid::Symbol)
    #println("operator($id)")
    for dict in _ops(dd)
        if haskey(dict, opid)
            @show dict[opid]
            return dict[opid] #! not type stable because each dict holds different type.
        end
    end
    return nothing
end
operator(id::Symbol) = operator(PNML.DECLDICT[], id)

"""
    validate_declarations(dd::DeclDict) -> Bool
"""
function validate_declarations(dd::DeclDict)
    println("validate declarations")
    show_sorts(dd)
    @show _op_dictionaries()
    println()
    @show all(Fix1(hasfield, typeof(dd)), _op_dictionaries())
    foreach(_op_dictionaries()) do opd
        println(opd, " length ", length(getfield(dd, opd)))
        @show getfield(dd, opd)
    end
    #@show collect(_ops(dd))
    println()
    @show collect(operators(dd))
    println()
    for opid in operators(dd)
        @show operator(opid)
        @show operator(opid)(NamedTuple()) # operators take parameters
    end
    println("-----------------------------------------")
    return true
end

function show_sorts(dd::DeclDict)
    println("show_sorts")
    @show _sort_dictionaries()
    foreach(_sort_dictionaries()) do s
        println(s, " length ", length(getfield(dd, s)))
        @show getfield(dd, s)
    end
   println()
end

"""
    fill_nonhl!() -> Nothing
    fill_nonhl!(dd::DeclDict) -> Nothing

Fill a DeclDict with defaults and values needed by non-high-level networks.
Defaults to filling the scoped value PNML.DECLDICT[].

    NamedSort(:integer, "Integer", IntegerSort())
    NamedSort(:natural, "Natural", NaturalSort())
    NamedSort(:positive, "Positive", PositiveSort())
    NamedSort(:real, "Real", RealSort())
    NamedSort(:dot, "Dot", DotSort())
    NamedSort(:bool, "Bool", BoolSort())

    UserSort(:integer)
    UserSort(:natural)
    UserSort(:positive)
    UserSort(:real)
    UserSort(:dot)
    UserSort(:bool)
"""
function fill_nonhl! end

fill_nonhl!() = fill_nonhl!(PNML.:DECLDICT[]) # ScopedValue
function fill_nonhl!(dd::DeclDict)
    for (tag, name, sort) in ((:integer, "Integer", IntegerSort()),
                              (:natural, "Natural", NaturalSort()),
                              (:positive, "Positive", PositiveSort()),
                              (:real, "Real", RealSort()),
                              (:dot, "Dot", DotSort()),
                              (:bool, "Bool", BoolSort()),
                              (:null, "Null", NullSort()),
                              )
        #TODO list, strings, arbitrarysorts other built-ins
        fill_sort_tag!(dd, tag, name, sort)
    end
end

"""
    fill_sort_tag!(dd::DeclDict, tag::Symbol, name, sort)

If not already in the declarations dictionary, create and add a namedsort, usersort duo for `tag`.
"""
function fill_sort_tag! end

function fill_sort_tag!(dd::DeclDict, tag::Symbol, name, sort)
    if !has_namedsort(dd, tag) # Do not overwrite existing content.
        !isregistered(PNML.idregistry[], tag) && register_id!(PNML.idregistry[], tag)
        namedsorts(dd)[tag] = NamedSort(tag, name, sort)
    end
    if !has_usersort(dd, tag) # Do not overwrite existing content.
        #! DO NOT register REFID! ID owned by NamedSort
        usersorts(dd)[tag] = UserSort(tag)
    end
end

fill_sort_tag!(tag::Symbol, name, sort) = fill_sort_tag!(PNML.DECLDICT[], tag::Symbol, name, sort)
