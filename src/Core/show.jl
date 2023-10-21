# Show methods for the intermediate representation.
# References:
#  - base/show.jl
#  - ?show
#
#
# TODO: use  MIME"application/vnd.julia-vscode.diagnostics" for runtime diagnostics
#
#-------------------
function Base.show(io::IO, fill::Fill)
    pprint(io, fill)
end

PrettyPrinting.quoteof(f::Fill) = :(Fill($(PrettyPrinting.quoteof(f.color)),
                                         $(PrettyPrinting.quoteof(f.image)),
                                         $(PrettyPrinting.quoteof(f.gradient_color)),
                                         $(PrettyPrinting.quoteof(f.gradient_rotation))))

#-------------------
function Base.show(io::IO, font::Font)
    pprint(io, font)
end

PrettyPrinting.quoteof(f::Font) = :(Font($(PrettyPrinting.quoteof(f.family)),
                                         $(PrettyPrinting.quoteof(f.style)),
                                         $(PrettyPrinting.quoteof(f.weight)),
                                         $(PrettyPrinting.quoteof(f.size)),
                                         $(PrettyPrinting.quoteof(f.align)),
                                         $(PrettyPrinting.quoteof(f.rotation)),
                                         $(PrettyPrinting.quoteof(f.decoration))))

#-------------------
function Base.show(io::IO, line::Line)
    pprint(io, line)
end

PrettyPrinting.quoteof(l::Line) = :(Line($(PrettyPrinting.quoteof(l.color)),
                                         $(PrettyPrinting.quoteof(l.style)),
                                         $(PrettyPrinting.quoteof(l.shape)),
                                         $(PrettyPrinting.quoteof(l.width))))

#-------------------
function Base.show(io::IO, c::Coordinate)
    compact = get(io, :compact, false)::Bool
    print(io, "(", c.x, ",", c.y, ")")
end

function Base.show(io::IO, g::Graphics)
    print(io, "Graphics(",
            g.dimension, ", ",
            g.fill, ", ",
            g.font, ", ",
            g.line, ", ",
            g.offset, ", ",
            g.positions, ")")
end

#-------------------
function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    show(io, MIME"text/plain"(), labelvector)
end
function Base.show(io::IO, mime::MIME"text/plain", labelvector::Vector{PnmlLabel})
    print(io, indent(io), typeof(labelvector), "[")
    io = inc_indent(io)
    for (i,label) in enumerate(labelvector)
        i > 1 && print(io, indent(io))
        pprint(io, label)
        i < length(labelvector) && print(io, "\n")
    end
    print(io, "]")

end

function Base.show(io::IO, label::PnmlLabel)
    pprint(io, label)
end

PrettyPrinting.quoteof(l::PnmlLabel) = :(PnmlLabel($(PrettyPrinting.quoteof(l.tag)),
                                                   $(PrettyPrinting.quoteof(l.elements))))

#-------------------

PrettyPrinting.quoteof(a::AnyElement) = :(AnyElement($(PrettyPrinting.quoteof(a.tag)),
                                                     $(PrettyPrinting.quoteof(a.elements))))

# #-------------------

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    for (i, ti) in enumerate(toolvector)
        print(io, "\n", indent(io), "$i: ")
        show(io, ti)
    end
end

function Base.show(io::IO, ti::ToolInfo)
    pprint(io, ti)
end

PrettyPrinting.quoteof(ti::ToolInfo) = :(ToolInfo($(PrettyPrinting.quoteof(ti.toolname)),
                                         $(PrettyPrinting.quoteof(ti.version)),
                                         $(PrettyPrinting.quoteof(ti.infos))))

function Base.show(io::IO, tg::TokenGraphics)
    print(io, "positions: ", tg.positions)
end

function Base.show(io::IO, place::Place)
    print(io, summary(place),
          " id ", place.id,
          ", name '", name(place), "'",
          ", type ", place.sorttype,
          ", initial marking ", initial_marking(place))
end

function Base.show(io::IO, trans::Transition)
    print(io, typeof(trans),
          " id ", pid(trans), ", name '", name(trans), "'", ", condition ", condition(trans))
end

function Base.show(io::IO, r::ReferenceNode)
    print(io, typeof(r), " (id ", pid(r), ", ref ", refid(r))
    print(io, ")")
end

function Base.show(io::IO, arc::Arc)
    print(io, typeof(arc), " id ", arc.id,
          ", name '", has_name(arc) ? name(arc) : "", "'",
          ", source: ", source(arc),
          ", target: ", target(arc),
          ", inscription: ", arc.inscription)
end

function Base.summary( page::Page)
    string(typeof(page)," id ", page.id, ", ",
           " name '", name(page), "', ",
           length(place_idset(page)), " places, ",
           length(transition_idset(page)), " transitions, ",
           length(arc_idset(page)), " arcs, ",
           isnothing(declarations(page)) ? 0 : length(declarations(page)), " declarations, ",
           length(refplace_idset(page)), " refP, ",
           length(reftransition_idset(page)), " refT, ",
           length(page_idset(page)), " subpages, ",
           has_graphics(page) ? " has graphics " : " no graphics",
           length(tools(page)), " tools, ",
           length(labels(page)), " labels"
           )
end

function show_page_field(io::IO, label::AbstractString, x)
    println(io, indent(io), label)
    if !isnothing(x) && length(x) > 0
        show(inc_indent(io), MIME"text/plain"(), x)
        print(io, "\n")
    end
end

function Base.show(io::IO, page::Page)
    #TODO Add support for :trim and :compact
    println(io, indent(io), summary(page))
    # Start indent here. Will indent subpages.
    inc_io = inc_indent(io)

    show_page_field(inc_io, "places:",         place_idset(page))
    show_page_field(inc_io, "transitions:",    transition_idset(page))
    show_page_field(inc_io, "arcs:",           arc_idset(page))
    show_page_field(inc_io, "declaration:",    declarations(page))
    show_page_field(inc_io, "refPlaces:",      refplace_idset(page))
    show_page_field(inc_io, "refTransitions:", reftransition_idset(page))
    show_page_field(inc_io, "subpages:",       page_idset(page))
end

# #-------------------
function Base.summary(net::PnmlNet)
    string( typeof(net), " id ", pid(net),
            " name '", has_name(net) ? name(net) : "", "', ",
            " type ", nettype(net), ", ",
            length(pagedict(net)), " pages ",
            length(declarations(net)), " declarations",
            length(tools(net)), " tools, ",
            length(labels(net)), " labels"
             )
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    println(io, summary(net))
    iio = inc_indent(io) # Indent any declarations.
    for decl in declarations(net)
        print(iio, indent(io))
        show(iio, MIME"text/plain"(), decl)
        println(iio, "\n")
    end
    show(io, pages(net))
end

function Base.show(io::IO, ::MIME"text/plain", net::PnmlNet)
    show(io, net)
end

#-------------------
function Base.summary(pnml::PnmlModel)
    string(typeof(pnml), " model with ",  length(nets(pnml)), " nets" )
end

# No indent done here.
function Base.show(io::IO, pnml::PnmlModel)
    println(io, summary(pnml))
    println(io, "namespace = ", namespace(pnml))
    for (i, net) in enumerate(nets(pnml))
        show(io, MIME"text/plain"(), net)
        if i < length(nets(pnml))
            print(io, "\n")
        end
    end
end


#-------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------

function Base.show(io::IO, ptm::Marking)
    pprint(io, ptm)
end

PrettyPrinting.quoteof(m::Marking) = :(Marking($(PrettyPrinting.quoteof(value(m))),
        $(PrettyPrinting.quoteof(m.graphics)),
        $(PrettyPrinting.quoteof(m.tools))))

#-------------------
function Base.show(io::IO, cond::Condition)
    pprint(io, cond)
end

function Base.show(io::IO, ::MIME"text/plain", cond::Condition)
    show(io, cond)
end
PrettyPrinting.quoteof(c::Condition) = :(Condition($(PrettyPrinting.quoteof(c.text)),
                                                   $(PrettyPrinting.quoteof(value(c))),
                                                   $(PrettyPrinting.quoteof(c.graphics)),
                                                   $(PrettyPrinting.quoteof(c.tools))
                                                   ))

#-------------------
function Base.show(io::IO, inscription::Inscription)
    pprint(io, inscription)
end
function Base.show(io::IO, ::MIME"text/plain", inscription::Inscription)
    show(io, inscription)
end
PrettyPrinting.quoteof(i::Inscription) = :(Inscription($(PrettyPrinting.quoteof(value(i))),
                                                    $(PrettyPrinting.quoteof(i.graphics)),
                                                    $(PrettyPrinting.quoteof(i.tools))
                                            ))

function Base.summary(hlm::HLMarking)
    string(typeof(hlm))
end

function Base.show(io::IO, hlm::HLMarking)
    pprint(io, hlm)
end

quoteof(m::HLMarking) = :(HLMarking($(quoteof(text(m))), $(quoteof(value(m))),
                                    $(quoteof(graphics(m))), $(quoteof(tools(m)))))
#-------------------
function Base.show(io::IO, inscription::HLInscription)
    pprint(io, inscription)
end
function Base.show(io::IO, ::MIME"text/plain", inscription::HLInscription)
    show(io, inscription)
end

quoteof(i::HLInscription) =
    :(HLInscription($(quoteof(i.text)), $(quoteof(value(i))),
                    $(quoteof(graphics(i))), $(quoteof(tools(i)))))

#-------------------
function Base.show(io::IO, declare::AbstractDeclaration)
    pprint(io, declare)
end

quoteof(i::AbstractDeclaration) = :(AbstractDeclaration($(quoteof(i.id)), $(quoteof(i.name))))

quoteof(t::Term) = :(Term($(quoteof(t.tag)), $(quoteof(t.elements))))

#-------------------
function Base.show(io::IO, nsort::NamedSort)
    pprint(IOContext(io, :displaysize => (24, 180)), nsort)
end

quoteof(n::NamedSort) = :(NamedSort($(quoteof(n.id)), $(quoteof(n.name)), $(quoteof(n.def))))
