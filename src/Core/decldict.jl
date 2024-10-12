#!--------------------
#! see decldictcore.jl for  struct DeclDict
#!--------------------

function Base.show(io::IO, dd::DeclDict)
    println(io, nameof(typeof(dd)), "(")

    io = inc_indent(io)  # one indent
    iio = inc_indent(io) # two indents
    print(io, "NamedSort[")
    for (k,v) in pairs(namedsorts(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "NamedOperator[")
    for (k,v) in pairs(namedoperators(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "VariableDeclaration[")
    for (k,v) in pairs(variabledecls(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => "); show(io, v)
    end
    println(io, "]")

    print(io, "PartitionSort[")
    for (k,v) in pairs(partitionsorts(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
        # Does/should this also print the partition elements
    end
    println(io, "]")

    print(io, "PartitionElement[")
    for (k,v) in pairs(partitionops(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, "FEConstant[")
    for (k,v) in pairs(feconstants(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => "); show(io, v)
    end
    println(io, "]")

    print(io, "UserSort[")
    for (k,v) in pairs(usersorts(dd))
        print(iio, '\n', indent(iio)); show(io, k); print(io, " => ", v)
    end
    println(io, "]")

    print(io, ")")
end
