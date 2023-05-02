#-------------------
Base.summary(io::IO, hlm::HLMarking) = summary(hlm)
function
    Base.summary(hlm::HLMarking)
    string(typeof(hlm))
end

function Base.show(io::IO, hlm::HLMarking)
    pprint(io, hlm)
end

quoteof(m::HLMarking) = :(HLMarking($(quoteof(m.text)), $(quoteof(value(m))), $(quoteof(m.com))))
#-------------------
function Base.show(io::IO, inscription::HLInscription)
    pprint(io, inscription)
end
function Base.show(io::IO, ::MIME"text/plain", inscription::HLInscription)
    show(io, inscription)
end

quoteof(i::HLInscription) =
    :(HLInscription($(quoteof(i.text)), $(quoteof(value(i))), $(quoteof(i.com))))

#-------------------
function Base.show(io::IO, declarations::Vector{AbstractDeclaration})
    iio = inc_indent(io)
    print(io, indent(io), typeof(declarations), "[")

    for (i,dec) in enumerate(declarations)
        print(iio, "\n", indent(iio))
        show(inc_indent(io), MIME"text/plain"(), dec)
    end
    print(io, "]")
end
function Base.show(io::IO, declare::AbstractDeclaration)
    pprint(io, declare)
end
quoteof(i::AbstractDeclaration) = :(AbstractDeclaration($(quoteof(i.id)), $(quoteof(i.name)),
         $(quoteof(i.sort))))
#-------------------
function Base.show(io::IO, terms::Vector{AbstractTerm})
    iio = inc_indent(io)
    print(io, indent(io), typeof(terms), "[")

    for (i,term) in enumerate(terms)
        print(iio, "\n", indent(iio))
        show(inc_indent(io), term)
    end
    print(io, "]")
end
function Base.show(io::IO, term::AbstractTerm)
    pprint(io, term)
end
quoteof(t::AbstractTerm) = :(AbstractTerm($(quoteof(t.tag)), $(quoteof(t.elements))))

function Base.show(io::IO, term::Term)
    pprint(io, term)
end
quoteof(t::Term) = :(Term($(quoteof(t.tag)), $(quoteof(t.elements))))

#-------------------
function Base.show(io::IO, nsorts::Vector{NamedSort})

    print(io, typeof(nsorts), "[")
    for (i,dec) in enumerate(nsorts)
        print(io, "\n", indent(io))
        show(inc_indent(io), dec)
        i < length(nsorts) && print(io, "\n")
    end
    print(io, "]")
end

function Base.show(io::IO, nsort::NamedSort)
    pprint(IOContext(io, :displaysize => (24, 180)), nsort)
end

quoteof(n::NamedSort) = :(NamedSort($(quoteof(n.id)), $(quoteof(n.name)), $(quoteof(n.def))))
