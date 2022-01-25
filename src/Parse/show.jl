# show methods fot the intermediate representation
"Indention increment."
const indent_width = 4

#-------------------
"Return string of current indent size in `io`."
indent(io::IO) = repeat(' ', get(io, :indent, 0))

"Increment the `:indent` value `inc`."
inc_indent(io::IO) = IOContext(io, :indent => get(io, :indent, 0) + indent_width)

#-------------------
function Base.show(io::IO, fill::Fill)
    compact = get(io, :compact, false)
    if compact
        print(io, "(", fill.color, ",",
              fill.image, ",",
              fill.gradient_color, ",",
              fill.gradient_rotation, ")")
    else
        print(io, "Fill(color, ", fill.color,
              ", image, ", fill.image,
              ", gradient-color, ", fill.gradient_color,
              ", gradient-rotation ", fill.gradient_rotation,
              ")")
    end
end

function Base.show(io::IO, ::MIME"text/plain", fill::Fill)
    show(io, fill)
end

#-------------------
function Base.show(io::IO, font::Font)
    print(io,
          "Font(family: ", font.family,
          ", style: ", font.style,
          ", weight: ", font.weight,
          ", size: ", font.size,
          ", aligh: ", font.align,
          ", rotation: ", font.rotation,
          ", decoration: ", font.decoration,
          ")")
end

function Base.show(io::IO, ::MIME"text/plain", font::Font)
    show(io, font)
end

#-------------------
function Base.show(io::IO, line::Line)
    print(io,
          "Line(color: ", line.color,
          ", style: ", line.style,
          ", shape: ", line.shape,
          ", width: ", line.width,
          ")")
end

function Base.show(io::IO, ::MIME"text/plain", line::Line)
    print(io, line)
end

#-------------------
function Base.show(io::IO, c::Coordinate)
    compact = get(io, :compact, false)
    print(io, "(", c.x, ",", c.y, ")")
end

function Base.show(io::IO, ::MIME"text/plain", c::Coordinate)
    print(io, c)
end

#-------------------
function Base.show(io::IO, g::Graphics)
    compact = get(io, :compact, false)
    print(io, "Graphics(",
          "dimension=", g.dimension,
          ", fill=",      g.fill,
          ", font=",      g.font,
          ", line=",      g.line,
          ", offset=",    g.offset,
          ", position=",  g.position, ")")
end

#-------------------
function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    for (i,label) in enumerate(labelvector)
        print(io, indent(io), label)
        i < length(labelvector) && print(io, "\n")
    end
end
          
function Base.show(io::IO, n::PnmlLabel)
    print(io, typeof(n), " ")
    pprint(io, n.dict)
end
          
function Base.show(io::IO, ::MIME"text/plain", f::PnmlLabel)
    print(io, f)
end

#-------------------
Base.summary(io::IO, ti::ToolInfo) = print(io, summary(ti))
function Base.summary(ti::ToolInfo)
    string(typeof(ti), " name ", ti.toolname, ", version ", ti.version,
           ", ", length(ti.infos), " info dicts")
end

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    for (i, ti) in enumerate(toolvector)
        print(io, indent(io), ti)
        i < length(toolvector) && print(io, "\n")
    end
end

function Base.show(io::IO, ti::ToolInfo)
    println(io, summary(ti), ":")
    io = inc_indent(io)
    for (i,info) in enumerate(ti.infos)
        print(io, indent(io))
        pprintln(io, info)
        i < length(ti.infos) && print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", ti::ToolInfo)
    print(io, ti)
end

#-------------------
function Base.show(io::IO, tool::DefaultTool)
    print(io, "content: (", tool.content, ")")
end
function Base.show(io::IO, ::MIME"text/plain", tool::DefaultTool)
    print(io, tool)
end

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
    !isnothing(name.graphics) && print(io, ", has graphics")
    !isnothing(name.tools)    && print(io, ", ", length(name.tools), " tool info")
end
function Base.show(io::IO, ::MIME"text/plain", name::Name)
    print(io, name)
end
 
#-------------------
Base.summary(io::IO, oc::ObjectCommon) = print(io, summary(oc))
function Base.summary(oc::ObjectCommon)
    string("name: ",
           isnothing(oc.name)  ? nothing : oc.name,
           isnothing(oc.graphics) ? ", no graphics, " : ", has graphics, ",
           isnothing(oc.tools)  ? 0 : length(oc.tools),  " tools, ",
           isnothing(oc.labels) ? 0 : length(oc.labels), " labels")
end

function Base.show(io::IO, oc::ObjectCommon)
    io = inc_indent(io)
    if !isnothing(oc.graphics)
        print(io, indent(io), "graphics: ", oc.graphics)
    end
    if !isnothing(oc.tools)
        println(io, "\n", indent(io), "tools:")
        show(inc_indent(io), oc.tools)
    end
    if !isnothing(oc.labels)
        println(io, "\n", indent(io), "labels:")
        show(inc_indent(io), oc.labels)
    end
    # In general, do not display/print the XML. 
end

#-------------------
Base.summary(io::IO, ptm::PTMarking)  = summary(io, summary(ptm))
function Base.summary(ptm::PTMarking)
    string(typeof(ptm))
end

function Base.show(io::IO, ptm::PTMarking)
    print(io, summary(ptm), " value: ", ptm.value, ", ", ptm.com,)
end

function Base.show(io::IO, ::MIME"text/plain", ptm::PTMarking)
    print(io, ptm)
end

#-------------------
function Base.show(io::IO, hlm::HLMarking)
    print(io, "'", hlm.text, "', ", hlm.structure, ", ", hlm.com,)
end
function Base.show(io::IO, ::MIME"text/plain", hlm::HLMarking)
    print(io, hlm)
end

#-------------------
Base.summary(io::IO, place::Place)  = summary(io, summary(place))
function Base.summary(place::Place)
    string(typeof(place))
end

function Base.show(io::IO, place::Place)
    print(io, summary(place),
          " id ", place.id,
          ", type ", place.type, ", ",
          ", marking ", place.marking,
          ", ", place.com)
end

function Base.show(io::IO, ::MIME"text/plain", place::Place)
    show(io, place)
end

function Base.show(io::IO, placevector::Vector{Place})
    isempty(placevector) && return
    for (i,place) in enumerate(placevector)
        print(io, indent(io), place)
        i < length(placevector) && print(io, "\n")
    end
end

#-------------------
function Base.show(io::IO, cond::Condition)
    print(io, typeof(cond), " '", cond.text, "', ", cond.structure, ", ", cond.com)
end
function Base.show(io::IO, ::MIME"text/plain", cond::Condition)
    print(io, cond)
end

#-------------------
function Base.show(io::IO, trans::Transition)
    print(io, typeof(trans),
          " id ", trans.id, ", condition ", trans.condition, ", ", trans.com)
end

function Base.show(io::IO, transvector::Vector{Transition})
    for (i,trans) in enumerate(transvector)
        print(io, indent(io), trans)
        i < length(transvector) && print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", trans::Transition)
    print(io, trans)
end

#-------------------
function Base.show(io::IO, refp::RefPlace)
    print(io, "(id ", refp.id, ", ref ", refp.ref, ", ", refp.com, ")")
end
function Base.show(io::IO, rpvector::Vector{RefPlace})
    for (i,rp) in enumerate(rpvector)
        print(io, indent(io), rp)
        i < length(rpvector) && print(io, "\n")
    end
end
function Base.show(io::IO, ::MIME"text/plain", refp::RefPlace)
    show(io, refp)
end

#-------------------
function Base.show(io::IO, reft::RefTransition)
    print(io, "(id ", reft.id, ", ref ", reft.ref, ", ",  reft.com, ")")
end
function Base.show(io::IO, rtvector::Vector{RefTransition})
    for (i,rt) in enumerate(rtvector)
        print(io, indent(io), rt)
        i < length(rtvector) && print(io, "\n")
    end
end
function Base.show(io::IO, ::MIME"text/plain", reft::RefTransition)
    show(io, reft)
end

#-------------------
function Base.show(io::IO, ins::PTInscription)
    print(io, typeof(ins), " value ", ins.value, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::PTInscription)
    show(io, ins)
end

#-------------------
function Base.show(io::IO, ins::HLInscription)
    print(io, typeof(ins),  " '", ins.text, "', ", ins.structure, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::HLInscription)
    show(io, ins)
end

#-------------------
function Base.show(io::IO, arc::Arc)
    print(io, "id: ", arc.id,
          ", source: ", arc.source,
          ", target: ", arc.target,
          ", inscription: ", arc.inscription,
          arc.com)
end
function Base.show(io::IO, arcvector::Vector{Arc})
    for (i,arc) in enumerate(arcvector)
        print(io, indent(io), arc)
        i < length(arcvector) && print(io, "\n")
    end
end
function Base.show(io::IO, ::MIME"text/plain", arc::Arc)
    show(io, arc)
end

#-------------------
function Base.show(io::IO, declarations::Vector{Declaration})
    isempty(declarations) && return
    for (i,dec) in enumerate(declarations)
        print(io, indent(io), dec)
        i < length(declarations) && print(io, "\n")
    end
end
function Base.show(io::IO, declare::Declaration)
    print(io, declare.d, ", ", declare.com,)
end
function Base.show(io::IO, ::MIME"text/plain", declare::Declaration)
    show(io, declare)
end

#-------------------
Base.summary(io::IO, page::Page) = print(io, summary(page))
function Base.summary( page::Page)
    string(typeof(page)," id ", page.id, ", ",
           length(page.places), " places, ",
           length(page.transitions), " transitions, ",
           length(page.arcs), " arcs, ",
           length(page.declarations), " declarations, ",
           length(page.refPlaces), " refP, ",
           length(page.refTransitions), " refT, ",
           length(page.subpages), " subpages, ",
           summary(page.com)
           )
end

function show_page_field(io::IO, label::AbstractString, x)
    println(io, indent(io), label)
    if !isempty(x)
        show(inc_indent(io), x)
        print(io, "\n")
    end
end

function Base.show(io::IO, page::Page)
    #TODO Add support for :trim and :compact
    println(io, indent(io), summary(page))
    # Start indent here. Will indent subpages.
    inc_io = inc_indent(io)    

    show_page_field(inc_io, "places:",         page.places)
    show_page_field(inc_io, "transitions:",    page.transitions)
    show_page_field(inc_io, "arcs:",           page.arcs)
    show_page_field(inc_io, "declarations:",   page.declarations)
    show_page_field(inc_io, "refPlaces:",      page.refPlaces)
    show_page_field(inc_io, "refTransitions:", page.refTransitions)
    show_page_field(inc_io, "subpages:",       page.subpages)

    print(inc_io, indent(io),  page.com)
end

function Base.show(io::IO, pages::Vector{Page})
    isempty(pages) && return
    for (i,page) in enumerate(pages)
        show(io, page)
        i < length(pages) && print(io, "\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", p::Page)
    show(io, p)
end

#-------------------
Base.summary(io::IO, net::PnmlNet) = print(io, summary(net))
function Base.summary(net::PnmlNet)
    string( typeof(net), " id ", net.id, " type ", net.type, ", ",
            length(net.pages), " pages ",
            length(net.declarations), " declarations ",
            summary(net.com))
end

# No indent here.
function Base.show(io::IO, net::PnmlNet)
    println(io, summary(net))
    for (i, dec) in enumerate(net.declarations)
        show(io, dec)
        i < length(net.declarations) && println(io) 
    end
    print(io, net.com)
    show(io, net.pages)
end

function Base.show(io::IO, ::MIME"text/plain", net::PnmlNet)
    show(io, net)
end

#-------------------
Base.summary(io::IO, pnml::PnmlModel) = print(io, summary(pnml))
function Base.summary(pnml::PnmlModel)
    string(typeof(pnml), " model with ",  length(pnml.nets), " nets" )
end

# No indent done here.
function Base.show(io::IO, pnml::PnmlModel)
    println(io, summary(pnml))
    for (i, net) in enumerate(pnml.nets)
        print(io, net)
        if i < length(pnml.nets)
            print(io, "\n")
        end
    end
    # Omit display of any xml
end

function Base.show(io::IO, ::MIME"text/plain", pnml::PnmlModel)
    return show(io, pnml)
end


#-------------------
# show(io, x) ... _show_default formats as
#type(f1(...), f2(...), ...)
