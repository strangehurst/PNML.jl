#!--------------------
#! see decldictcore.jl
#!--------------------

# """
#     DeclDict

# Collection of Declaration dictionaries that apply to a single `PnmlNet`.
# """
# @kwdef struct DeclDict
#     # TODO tuple(vd::VariableDeclaration, x::typeof(sortof(vd)))
#     # TODO Each VariableDeclaration is a single data item, tuple(decl, instance_of_sort)
#     # TODO the sort is the part that is shared and should be de-duplicated.
#     variabledecls::Dict{Symbol, VariableDeclaration} = Dict{Symbol, VariableDeclaration}()

#     namedsorts::Dict{Symbol, NamedSort} = Dict{Symbol, NamedSort}()
#     arbitrarysorts::Dict{Symbol, ArbitrarySort} = Dict{Symbol, ArbitrarySort}()
#     partitionsorts::Dict{Symbol, PartitionSort} = Dict{Symbol, PartitionSort}()

#     # useroperator refers to a OperatorDeclaration by name.
#     # todo use flattened iterator over all OperatorDeclarations
#     # OperatorDecls include: namedoperator, feconstant, partition element, et al.
#     # namedoperators are used to access built-in operators
#     namedoperators::Dict{Symbol, NamedOperator} = Dict{Symbol, NamedOperator}()
#     arbitraryoperators::Dict{Symbol, ArbitraryOperator} = Dict{Symbol, ArbitraryOperator}()
#     # PartitionElement is an operator, there are other built-in operators
#     partitionops::Dict{Symbol,PartitionElement} = Dict{Symbol,PartitionElement}()
#     # FEConstants are 0-ary OperatorDeclarations.
#     # The only explicit attributes are id symbol and name string.
#     # We record an optional partition id
#     feconstants::Dict{Symbol, FEConstant} = Dict{Symbol, FEConstant}()

#     # Allows using an IDREF symbol as a network-level "global".
#     # Useful for non-high-level networks that mimic HLNets to share implementation.
#     # Long way of saying generic? (in what sense generic?)
#     usersorts::Dict{Symbol, UserSort} = Dict{Symbol, UserSort}()
# end

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

    print(io, "UserSort[")
    for (k,v) in pairs(dd.usersorts)
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, ")")
end
