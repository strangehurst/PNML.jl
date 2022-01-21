# show methods fot the intermediate representation
"Indention increment."
const inc = 4

#-------------------
"Return string of current indent size in `io`."
indent(io::IO) = repeat(' ', get(io, :indent, 0))

"Increment the `:indent` value `inc`."
inc_indent(io::IO) = IOContext(io, :indent => get(io, :indent, 0) + inc)

#-------------------
function Base.show(io::IO, fill::Fill)
    compact = get(io, :compact, false)
    if compact
        print(io, "(", fill.color, ",", fill.image, ",",
              fill.gradient_color, ",", fill.gradient_rotation, ")")
    else
        print(io, "(color: ", fill.color,
              ", image: ", fill.image,
              ", gradient-color: ", fill.gradient_color,
              ", gradient-rotation: ", fill.gradient_rotation,
              ")")
    end
end

function Base.show(io::IO, ::MIME"text/plain", fill::Fill)
    print(io, "Fill:\n   ", fill)
end

#-------------------
function Base.show(io::IO, font::Font)
    print(io,
          "(family: ", font.family,
          ", style: ", font.style,
          ", weight: ", font.weight,
          ", size: ", font.size,
          ", aligh: ", font.align,
          ", rotation: ", font.rotation,
          ", decoration: ", font.decoration,
          ")")
end

function Base.show(io::IO, ::MIME"text/plain", font::Font)
    print(io, "Font:\n   ", font)
end

#-------------------
function Base.show(io::IO, line::Line)
    print(io,
          "(color: ", line.color,
          ", style: ", line.style,
          ", shape: ", line.shape,
          ", width: ", line.width,
          ")")
end

function Base.show(io::IO, ::MIME"text/plain", line::Line)
    print(io, "Line:\n   ", line)
end

#-------------------
function Base.show(io::IO, c::Coordinate)
    compact = get(io, :compact, false)
    print(io, "(", c.x, ",", c.y, ")")
end

function Base.show(io::IO, ::MIME"text/plain", c::Coordinate)
    print(io, "Coordinate:\n   ", c)
end

#-------------------
function Base.show(io::IO, g::Graphics)
    compact = get(io, :compact, false)
    print(io, "(",
          "dimension=", g.dimension,
          ", fill=",      g.fill,
          ", font=",      g.font,
          ", line=",      g.line,
          ", offset=",    g.offset,
          ", position=",  g.position, ")")
end

#-------------------
function Base.show(io::IO, labelvector::Vector{PnmlLabel})
    foreach(label->println(io,label), @view labelvector[begin:end-1])
    print(io, labelvector[end])
end
          
function Base.show(io::IO, n::PnmlLabel)
    print(io, indent(io))
    pprint(io, n.dict)
end
          
function Base.show(io::IO, ::MIME"text/plain", f::PnmlLabel)
    print(io, "PnmlLabel: ", f)
end

#-------------------
Base.summary(io::IO, ti::ToolInfo) = print(io, summary(ti))
function Base.summary(ti::ToolInfo)
    string(typeof(ti), " name ", ti.toolname, ", version ", ti.version,
           ", ", length(ti.infos), " info dicts")
end

function Base.show(io::IO, toolvector::Vector{ToolInfo})
    foreach(ti->println(io, indent(io), ti), @view toolvector[begin:end-1])
    io = IOContext(io, :indent => get(io, :indent, 0) + inc)
    print(io, indent(io), toolvector[end])
end

function Base.show(io::IO, ti::ToolInfo)
    println(io, indent(io), summary(ti), ":")
    io = IOContext(io, :indent => get(io, :indent, 0) + inc)
    foreach(ti.infos[begin:end-1]) do info
        print(io, indent(io))
        pprintln(io, info)
    end
    print(io, indent(io))
    pprint(io, ti.infos[end])
end

function Base.show(io::IO, ::MIME"text/plain", ti::ToolInfo)
    print(io, "ToolInfo:\n   ", ti)
end

#-------------------
function Base.show(io::IO, tool::DefaultTool)
    print(io, indent(io), "content: (", tool.content, ")")
end
function Base.show(io::IO, ::MIME"text/plain", tool::DefaultTool)
    print(io, "DefaultTool:\n   ", tool)
end

#-------------------
function Base.show(io::IO, tg::TokenGraphics)
    print(io, indent(io), "positions: ", tg.positions)
end

function Base.show(io::IO, ::MIME"text/plain", tg::TokenGraphics)
    print(io, "TokenGraphics:\n   ", tg)
end

#-------------------
function Base.show(io::IO, name::Name)
    print(io, "'",name.text,"'")
    !isnothing(name.graphics) && print(io, ", has graphics")
    !isnothing(name.tools)    && print(io, ", ", length(name.tools), " tool info")
end
function Base.show(io::IO, ::MIME"text/plain", name::Name)
    print(io, indent(io), "Name: ", name)
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
    io = IOContext(io, :indent => get(io, :indent, 0) + inc)
    !isnothing(oc.graphics) && println(io, indent(io), "graphics: ", oc.graphics)
    !isnothing(oc.tools)    && println(io, indent(io), "tools: \n", oc.tools)
    !isnothing(oc.labels)   && println(io, indent(io), "labels: \n", oc.labels)
    # In general, do not display/print the XML. 
end

#-------------------
Base.summary(io::IO, ptm::PTMarking)  = summary(io, summary(ptm))
function Base.summary(ptm::PTMarking)
    string(typeof(ptm))
end

function Base.show(io::IO, ptm::PTMarking)
    print(io, indent(io), summary(ptm), " value: ", ptm.value, ", ", ptm.com,)
end

function Base.show(io::IO, ::MIME"text/plain", ptm::PTMarking)
    print(io, "PTMarking:\n   ", ptm)
end

#-------------------
function Base.show(io::IO, hlm::HLMarking)
    print(io, indent(io), "'", hlm.text, "', ", hlm.structure, ", ", hlm.com,)
end
function Base.show(io::IO, ::MIME"text/plain", hlm::HLMarking)
    print(io, "HLMarking:\n   ", hlm)
end

#-------------------
Base.summary(io::IO, place::Place)  = summary(io, summary(place))
function Base.summary(place::Place)
    string(typeof(place))
end

function Base.show(io::IO, place::Place)
    print(io, summary(place))
    print(io, indent(io), 
          "id: ", place.id,
          ", type: ", place.type, ", ",
          ", marking: ", place.marking,
          place.com)
end

function Base.show(io::IO, ::MIME"text/plain", place::Place)
    print(io, "Place:\n   ", place)
end

function Base.show(io::IO, placevector::Vector{Place})
    isempty(placevector) && return
    foreach(place->println(io, indent(io), place), @view placevector[begin:end-1])
    print(io, indent(io), placevector[end])
end

#-------------------
function Base.show(io::IO, cond::Condition)
    print(io, indent(io), "'", cond.text, "', ", cond.structure, ", ",  cond.com)
end
function Base.show(io::IO, ::MIME"text/plain", cond::Condition)
    print(io, "Condition:\n   ", cond)
end

#-------------------
function Base.show(io::IO, trans::Transition)
    print(io, indent(io), "id: ", trans.id, ", condition: ", trans.condition, ", ", trans.com,)
end

function Base.show(io::IO, ::MIME"text/plain", trans::Transition)
    print(io, "Transition:\n   ", trans)
end

#-------------------
function Base.show(io::IO, refp::RefPlace)
    print(io, indent(io), "id: ", refp.id, ", ref: ", refp.ref, ", ", refp.com,)
end
function Base.show(io::IO, ::MIME"text/plain", refp::RefPlace)
    print(io, "RefPlace:\n   ", refp)
end

#-------------------
function Base.show(io::IO, reft::RefTransition)
    print(io, indent(io), "id: ", reft.id, ", ref: ", reft.ref, ", ",  reft.com,)
end
function Base.show(io::IO, ::MIME"text/plain", reft::RefTransition)
    print(io, "RefTransition:\n   ", reft)
end

#-------------------
function Base.show(io::IO, ins::PTInscription)
    print(io, indent(io), "value: ", ins.value, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::PTInscription)
    print(io, "PTInscription:\n   ", ins)
end

#-------------------
function Base.show(io::IO, ins::HLInscription)
    print(io, indent(io),  "'", ins.text, "', ", ins.structure, ", ", ins.com,)
end
function Base.show(io::IO, ::MIME"text/plain", ins::HLInscription)
    print(io, "HLInscription:\n   ", ins)
end

#-------------------
function Base.show(io::IO, arc::Arc)
    print(io, indent(io), "(id: ", arc.id,
          ", source: ", arc.source,
          ", target: ", arc.target,
          ", inscription: ", arc.inscription,
          arc.com,
          ")")
end
function Base.show(io::IO, ::MIME"text/plain", arc::Arc)
    print(io, "Arc:\n   ", arc)
end

#-------------------
function Base.show(io::IO, declarations::Vector{Declaration})
    isempty(declarations) && return
    foreach(declare->println(io, declare), @view declarations[begin:end-1])
    print(io, declarations[end])
end
function Base.show(io::IO, declare::Declaration)
    print(io, declare.d, ", ", declare.com,)
end
function Base.show(io::IO, ::MIME"text/plain", declare::Declaration)
    print(io, "Declaration:\n   ", declare)
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
           length(page.refTransitions), " ref, ",
           length(page.subpages), " subpages, ",
           summary(page.com)
           )
end

function Base.show(io::IO, page::Page)
    println(io, summary(page))
    io = IOContext(io, :indent => get(io, :indent, 0) + inc)
    f_indent = indent(io) # Save 
    io = IOContext(io, :indent => get(io, :indent, 0) + inc)
    println(io, f_indent, "places: \n", page.places)
    println(io, f_indent, "transitions: \n", page.transitions)
    println(io, f_indent, "arcs: \n", page.arcs)
    println(io, f_indent, "declarations: \n", page.declarations)
    println(io, f_indent, "refPlaces: ", page.refPlaces)
    println(io, f_indent, "refTransitions: ", page.refTransitions)
    println(io, f_indent, "subpages: \n", page.subpages)
    println(io, f_indent,  page.com)
end

function Base.show(io::IO, pages::Vector{Page})
    isempty(pages) && return
    foreach(page->println(io, page), @view pages[begin:end-1])
    print(io, pages[end])
end

function Base.show(io::IO, ::MIME"text/plain", p::Page)
    print(io, "Page:\n   ", p)
end

#-------------------
Base.summary(io::IO, net::PnmlNet) = print(io, summary(net))
function Base.summary(net::PnmlNet)
    string( typeof(net), " id ", net.id, " type ", net.type, ", ",
            length(net.pages), " pages ",
            length(net.declarations), " declarations ",
            summary(net.com))
end

function Base.show(io::IO, net::PnmlNet)
    println(io, summary(net))
    f_indent = indent(io)
    io = IOContext(io, :indent => get(io, :indent, 0) + inc)
    println(io, indent(io), net.com)
    println(io, indent(io), net.declarations)
    print(io, indent(io), net.pages)
end

function Base.show(io::IO, ::MIME"text/plain", net::PnmlNet)
    print(io, "PnmlNet:\n   ", net)
end

#-------------------
Base.summary(io::IO, pnml::Pnml) = print(io, summary(pnml))
function Base.summary(pnml::Pnml)
    l = length(pnml.nets)
    return string(typeof(pnml), " model with ", l, " nets" )
end

function Base.show(io::IO, pnml::Pnml)
    println(io, summary(pnml))
    print(inc_indent(io), indent(io), pnml.nets)
end
function Base.show(io::IO, ::MIME"text/plain", pnml::Pnml)
    print(io, "Pnml:\n   ", pnml)
end


#-------------------
