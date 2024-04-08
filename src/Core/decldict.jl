"""
    DeclDict

Collection of Declartion dictionaries.
"""
@kwdef struct DeclDict
    # useroperator refers to a namedoperator, feconstant, or other OperatorDecl by name.
    # feconstant refers to an 0-ary operator by id/name.
    # Other OperatorDecls: PartitionElement, ArbitraryOperator
    namedoperators::Dict{Symbol, NamedOperator} = Dict{Symbol, NamedOperator}()
    namedsorts::Dict{Symbol, NamedSort} = Dict{Symbol, NamedSort}()
    partitionsorts::Dict{Symbol, PartitionSort} = Dict{Symbol, PartitionSort}()
    variabledecls::Dict{Symbol, VariableDeclaration} = Dict{Symbol, VariableDeclaration}()
    # PartitionElement is an operator
    partitionops::Dict{Symbol,PartitionElement} = Dict{Symbol,PartitionElement}()
    # FEConstants are OperatorDeclarations (constants are 0-ary opeators).
    feconstants::Dict{Symbol, FEConstant} = Dict{Symbol, FEConstant}()
end
decldict(netid::Symbol) = haskey(TOPDECLDICTIONARY, netid) ? TOPDECLDICTIONARY[netid] : error("$netid not in TOPDECLDICTIONARY")

# Explicit propeties allows ignoring metadata.
Base.isempty(dd::DeclDict) =
    all(f->isempty(getproperty(dd, f)), (:namedsorts, :namedoperators, :variabledecls, :partitionsorts, :partitionops, :feconstants))
Base.length(dd::DeclDict) =
    sum(f->length(getproperty(dd, f)), (:namedsorts, :namedoperators, :variabledecls, :partitionsorts, :partitionops, :feconstants))

named_op(dd::DeclDict, id::Symbol)      = dd.namedoperators[id]
named_sort(dd::DeclDict, id::Symbol)    = dd.namedsorts[id]
variable(dd::DeclDict, id::Symbol)      = dd.variabledecls[id]
partitionsort(dd::DeclDict, id::Symbol) = dd.partitionsorts[id]
partitionop(dd::DeclDict, id::Symbol)   = dd.partitionops[id]
feconstant(dd::DeclDict, id::Symbol)    = dd.feconstants[id]

has_named_op(dd::DeclDict, id::Symbol)      = haskey(dd.namedoperators, id)
has_named_sort(dd::DeclDict, id::Symbol)    = haskey(dd.namedsorts, id)
has_variable(dd::DeclDict, id::Symbol)      = haskey(dd.variabledecls, id)
has_partitionsort(dd::DeclDict, id::Symbol) = haskey(dd.partitionsorts, id)
has_partitionop(dd::DeclDict, id::Symbol)   = haskey(dd.partitionops, id)
has_feconstant(dd::DeclDict, id::Symbol)    = haskey(dd.feconstants, id)

function declarations(dd::DeclDict)
    Iterators.flatten([
        values(dd.namedsorts),
        values(dd.namedoperators),
        values(dd.partitionsorts),
        values(dd.partitionops),
        values(dd.feconstants),
        values(dd.variabledecls),
                               ])
end

"""
    validate_declarations(dd::DeclDict) -> Bool
"""
function validate_declarations(dd::DeclDict)
    println("validate declarations")
    return true
end

function Base.show(io::IO, dd::DeclDict)
    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)
    iio = inc_indent(io)
    print(io, "NamedSort[")
    for (k,v) in pairs(dd.namedsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "NamedOperator[")
    for (k,v) in pairs(dd.namedoperators)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "VariableDeclaration[")
    for (k,v) in pairs(dd.variabledecls)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "PartitionSort[")
    for (k,v) in pairs(dd.partitionsorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
        # Does/should this also print the partition elements
    end
    println(io, "]")

    print(io, "PartitionElement[")
    for (k,v) in pairs(dd.partitionops)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "FEConstant[")
    for (k,v) in pairs(dd.feconstants)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")


    print(io, ")")
end
