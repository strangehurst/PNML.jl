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

function Base.show(io::IO, ::MIME"text/plain", c::Coordinate)
    print(io, c)
end

#-------------------
function shownames(io::IO, g::Graphics)
    print(io, "Graphics(",
        "dimension=", g.dimension,
        ", fill=",      g.fill,
        ", font=",      g.font,
        ", line=",      g.line,
        ", offset=",    g.offset,
        ", positions=",  g.positions, ")")
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

function Base.show(io::IO, mime::MIME"text/plain", label::PnmlLabel)
    pprint(io, label)
end

PrettyPrinting.quoteof(l::PnmlLabel) = :(PnmlLabel($(PrettyPrinting.quoteof(l.tag)),
                                                   $(PrettyPrinting.quoteof(l.elements))))

#-------------------
# function Base.show(io::IO, elvector::Vector{AnyElement})
#     show(io, MIME"text/plain"(), elvector)
# end
# function Base.show(io::IO, mime::MIME"text/plain", elvector::Vector{AnyElement})
#     print(io, typeof(elvector), "[")
#     io = inc_indent(io)
#     for (i,el) in enumerate(elvector)
#         print(io, "\n", indent(io), "$i: ")
#         pprint(io, el)
#     end
#     print(io, "]")
# end

function Base.show(io::IO, el::AnyElement) #TODO Make parametric.
    pprint(io, el)
end

function Base.show(io::IO, mime::MIME"text/plain", el::AnyElement) #TODO Make parametric.
    pprint(io, el)
end

PrettyPrinting.quoteof(a::AnyElement) = :(AnyElement($(PrettyPrinting.quoteof(a.tag)),
                                                     $(PrettyPrinting.quoteof(a.elements))))

#-------------------
Base.summary(io::IO, ti::ToolInfo) = print(io, summary(ti))
function Base.summary(ti::ToolInfo)
    string(typeof(ti), " name ", ti.toolname, ", version ", ti.version,
           ", ", length(ti.infos), " infos")
end

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

#-------------------
function Base.show(io::IO, tg::TokenGraphics)
    print(io, "positions: ", tg.positions)
end

function Base.show(io::IO, ::MIME"text/plain", tg::TokenGraphics)
    print(io, tg)
end

#-------------------
function Base.show(io::IO, name::Name)
    print(io, typeof(name), " '", name.text, "'")
    isnothing(name.graphics) || print(io, ", has graphics")
    isempty(name.tools)    || print(io, ", ", length(name.tools), " tool info")
end
function Base.show(io::IO, ::MIME"text/plain", name::Name)
    print(io, name)
end

#---------------------------------------------------------------------------------
Base.summary(io::IO, place::Place)  = summary(io, summary(place))
function Base.summary(place::Place)
    string(typeof(place))
end

function Base.show(io::IO, place::Place)
    print(io, summary(place),
          " id ", place.id,
          ", name '", name(place), "'",
          ", type ", place.sorttype,
          ", initial marking ", initial_marking(place))
end

function Base.show(io::IO, ::MIME"text/plain", place::Place)
    show(io, place)
end
function Base.show(io::IO, ::MIME"text/plain", placevector::Vector{Place})
    show(io, placevector)
end

function Base.show(io::IO, placevector::Vector{Place})
    isempty(placevector) && return
    for (i,place) in enumerate(placevector)
        print(io, indent(io), place)
        i < length(placevector) && print(io, "\n")
    end
end

#-------------------
function Base.show(io::IO, trans::Transition)
    print(io, typeof(trans),
          " id ", pid(trans), ", name '", name(trans), "'", ", condition ", condition(trans))
end

function Base.show(io::IO, ::MIME"text/plain", transvector::Vector{Transition})
    show(io, transvector)
end

function Base.show(io::IO, transvector::Vector{Transition})
    for (i,trans) in enumerate(transvector)
        print(io, indent(io), trans)
        i < length(transvector) && print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", trans::Transition)
    show(io, trans)
end

#-------------------
#TODO Make RefPlace, RefTransition an Abstract Type
function Base.show(io::IO, ::MIME"text/plain", r::ReferenceNode)
    show(io, r)
end
function Base.show(io::IO, r::ReferenceNode)
    print(io, typeof(r), " (id ", pid(r), ", ref ", refid(r))
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", rvector::Vector{<:ReferenceNode})
    show(io, rvector)
end
function Base.show(io::IO, rvector::Vector{<:ReferenceNode})
    for (i,r) in enumerate(rvector)
        print(io, indent(io), r)
        i < length(rvector) && print(io, "\n")
    end
end

#-------------------
function Base.show(io::IO, arc::Arc)
    print(io, typeof(arc), " id ", arc.id,
          ", name '", has_name(arc) ? name(arc) : "", "'",
          ", source: ", source(arc),
          ", target: ", target(arc),
          ", inscription: ", arc.inscription)
end
function Base.show(io::IO, ::MIME"text/plain", arcvector::Vector{Arc})
    for (i,arc) in enumerate(arcvector)
        print(io, indent(io), arc)
        i < length(arcvector) && print(io, "\n")
    end
end
function Base.show(io::IO, ::MIME"text/plain", arc::Arc)
    show(io, arc)
end

#-------------------
Base.summary(io::IO, page::Page) = print(io, summary(page))
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

function Base.show(io::IO, ::MIME"text/plain", p::Page)
    show(io, p)
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

function Base.show(io::IO, ::MIME"text/plain", pagevec::Vector{Page})
    show(io, pagevec)
end
function Base.show(io::IO, pagevec::Vector{Page})
    isempty(pagevec) && return
    for (i,page) in enumerate(pagevec)
        show(io, MIME"text/plain"(), page)
        i < length(pagevec) && println(io)#, "\n")
    end
end

#-------------------
Base.summary(io::IO, net::PnmlNet) = print(io, summary(net))
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
Base.summary(io::IO, pnml::PnmlModel) = print(io, summary(pnml))
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
    # Omit display of any xml
end

function Base.show(io::IO, ::MIME"text/plain", pnml::PnmlModel)
    return show(io, pnml)
end


#-------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------

#-------------------
Base.summary(io::IO, ptm::Marking)  = summary(io, summary(ptm))
function Base.summary(ptm::Marking)
    string(typeof(ptm))
end

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
