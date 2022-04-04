"""
$(TYPEDSIGNATURES)

Call the method matching `node.name` from [`tagmap`](@ref) if that mapping exists,
otherwise parse as [`unclaimed_label`](@ref) wrapped in a [`PnmlLabel`](@ref).
"""
function parse_node(node::XMLNode; kw...)
    @assert node !== nothing
    if haskey(tagmap, nodename(node))
        return tagmap[nodename(node)](node; kw...) # Various types returned here.
    else
        return PnmlLabel(unclaimed_label(node; kw...), node)
    end
end

#TODO test pnml_namespace
"""
$(TYPEDSIGNATURES)

Return namespace of `node. When `node` does not have a namespace return default value [`pnml_ns`](@ref)."
"""
function pnml_namespace(node::XMLNode; missing_ns_fatal=false, default_ns=pnml_ns)
    if EzXML.hasnamespace(node) 
         return EzXML.namespace(node)
    else
        emsg = "$(nodename(node)) missing namespace"
        missing_ns_fatal===false ? @warn(emsg) : error(emsg)
        return default_ns
    end
end

"""
$(TYPEDSIGNATURES)

Start parse from the pnml root `node` of a well formed XML document.
Return a [`PnmlModel`](@ref)..
"""
function parse_pnml(node; kw...)
    nn = nodename(node)
    nn == "pnml" || error("element name wrong: $nn" )
    
    @assert haskey(kw, :reg)
    # Do not yet have a PNTD defined, so call parse_net directly.
    PnmlModel(parse_net.(allchildren("net", node); kw...), 
              pnml_namespace(node),
              kw[:reg], 
              node)
end

"""
$(TYPEDSIGNATURES)
Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node; kw...)::PnmlNet
    nn = nodename(node)
    nn == "net" || error("element name wrong: $nn")
    EzXML.haskey(node, "id")   || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "type") || throw(MalformedException("$nn missing type", node))
    @assert haskey(kw, :reg)
    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.
    isempty(allchildren("page", node)) &&
         throw(MalformedException("$nn does not have any pages"))

    # Create a PnmlDict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples.
    # Keys that have pural names usually have a vector value.
    # The 'graphics' key is one exception and has a single value.
    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :pntd => pnmltype(node["type"]),
                           :pages => Page[],
                           :declaration => Declaration())

    pntd = d[:pntd] # Pass the PNTD down the parse tree with keyword arguments.

    # Go through children looking for expected tags, delegating common tags and labels.
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page"         => push!(d[:pages], parse_page(child; pntd, kw...))
            
            # For nets and pages the <declaration> tag is optional 
            # <declaration> ia a High-Level Annotation with a <structure> holding
            # a zero or more <declarations>. Is complicated. You have been warned!
            "declaration"  => (d[:declaration] = parse_declaration(child; pntd, kw...))
            _ => parse_pnml_node_common!(d, child; pntd, kw...)
        end
    end
    PnmlNet(d, pntd, node) # 
end
# Expected XML structure:
#    <declaration> <structure> <declarations> <namedsort id="weight" name="Weight"> ...

"""
$(TYPEDSIGNATURES)

PNML requires at least one page.
"""
function parse_page(node; kw...)
    nn = nodename(node)
    nn == "page" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)
    @assert haskey(kw, :pntd)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :places => Place[],
                           :trans => Transition[],
                           :arcs => Arc[],
                           :refP => RefPlace[],
                           :refT => RefTransition[],
                           :declaration => Declaration(),
                           :pages => Page[])

    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_place(child; kw...))
            "transition"  => push!(d[:trans], parse_transition(child; kw...))
            "arc"         => push!(d[:arcs], parse_arc(child; kw...))
            "referencePlace"      => push!(d[:refP], parse_refPlace(child; kw...))
            "referenceTransition" => push!(d[:refT], parse_refTransition(child; kw...))
            # See note above about declarations vs. declaration.
            "declaration" => (d[:declaration] = parse_declaration(child; kw...))
            "page"        => push!(d[:pages], parse_page(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Page(d, kw[:pntd])
end

"""
$(TYPEDSIGNATURES)
"""
function parse_place(node; kw...)
    nn = nodename(node)
    nn == "place" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag => Symbol(nn),
                           :id => register_id!(kw[:reg], node["id"]),
                           :marking => nothing,
                           :type => nothing) # Place 'type' is different from net 'type'.
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Tags initialMarking and hlinitialMarking are mutually exclusive.
            "initialMarking"   => (d[:marking] = parse_initialMarking(child; kw...))
            "hlinitialMarking" => (d[:marking] = parse_hlinitialMarking(child; kw...))
            # Here type means `sort`. Re: Many-sorted algebra.
            "type"             => (d[:type] = parse_type(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Place(d, kw[:pntd])
end

"""
$(TYPEDSIGNATURES)
"""
function parse_transition(node; kw...)
    nn = nodename(node)
    nn == "transition" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :condition=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition"    => (d[:condition] = parse_condition(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Transition(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_arc(node; kw...)
    nn = nodename(node)
    nn == "arc" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    @assert haskey(node, "source")
    @assert haskey(node, "target")
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :source=>Symbol(node["source"]),
                           :target=>Symbol(node["target"]),
                           :inscription=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Mutually exclusive tags: inscription, hlinscription
            "inscription"    => (d[:inscription] = parse_inscription(child; kw...))
            "hlinscription"  => (d[:inscription] = parse_hlinscription(child; kw...))
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    Arc(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refPlace(node; kw...)
    nn = nodename(node)
    nn == "referencePlace" || error("element name wrong: $nn")
    EzXML.haskey(node, "id")  || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d, child; kw...)
        end
    end
    RefPlace(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_refTransition(node; kw...)
    nn = nodename(node)
    nn == "referenceTransition" || error("element name wrong: $nn")
    EzXML.haskey(node, "id") || throw(MissingIDException(nn, node))
    EzXML.haskey(node, "ref") || throw(MalformedException("$(nn) missing ref attribute", node))
    @assert haskey(kw, :reg)

    d = pnml_node_defaults(node, :tag=>Symbol(nn),
                           :id=>register_id!(kw[:reg], node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child; kw...)
        end
    end
    RefTransition(d)
end

#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return the stripped string of nodecontent.
"""
function parse_text(node; kw...)
    nn = nodename(node)
    nn == "text" || error("$nn nodename wrong")
    string(strip(nodecontent(node)))
end

"""
$(TYPEDSIGNATURES)

Return [`Name`](@ref) holding text value and optional tool & GUI information.
"""
function parse_name(node; kw...)
    nn = nodename(node)
    nn == "name" || error("element nodename wrong")

    # Using firstchild or allchildren can cause parse_node to be passed nothing
    # for optional or missing child nodes.

    textnode = firstchild("text", node)
    if isnothing(textnode)
        @warn "$(nn) missing <text> element"
        # There are pnml files that break the rules & do not have a text element here.
        # Ex: PetriNetPlans-PNP/parallel.jl
        # Attempt to harvest content of <name> element instead of the child <text> element.
        # Assumes there are no other children elements.
        value = string(strip(nodecontent(node)))
    else
        value = string(strip(nodecontent(textnode)))
    end

    graphicsnode = firstchild("graphics", node)
    graphics = isnothing(graphicsnode) ? nothing : parse_graphics(graphicsnode; kw..., verbose=false)

    toolspecific = allchildren("toolspecific", node)
    tools = isempty(toolspecific) ? nothing : parse_toolspecific.(toolspecific; kw..., verbose=false)

    Name(value; graphics, tools)
end

#----------------------------------------------------------
#
#----------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Return [`Structure`](@ref) wrapping a `PnmlDict` holding a <structure>.
Should be inside of an label. 
A "claimed" label usually elids the <structure> level (does not call this method).
"""
function parse_structure(node; kw...)
    nn = nodename(node)
    nn == "structure" || error("element name wrong: $nn")
    Structure(unclaimed_label(node; kw...))
end

#----------------------------------------------------------
#
# PNML annotation-label XML element parsers.
#
#----------------------------------------------------------

# Place Transition nets (PT-Nets) use only the text tag of a label for
# the meaning of marking and inscriptions.

"""
$(TYPEDSIGNATURES)
"""
function parse_initialMarking(node; kw...)
    nn = nodename(node)
    nn == "initialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # We extend to real numbers.
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d, child; kw...)
        end
    end
    PTMarking(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_inscription(node; kw...)
    nn = nodename(node)
    nn == "inscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = number_value(string(strip(nodecontent(child)))))
            # Should not have a sturcture.
            _ => parse_pnml_label_common!(d, child; kw...)
        end
    end
    PTInscription(d)
end

# High-Level Nets, includeing PT-HLPNG, are expected to use the structure child node to
# define the semantics of marking and inscriptions.

"""
$(TYPEDSIGNATURES)
"""
function parse_hlinitialMarking(node; kw...)
    nn = nodename(node)
    nn == "hlinitialMarking" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), 
                            :text=>nothing, 
                            :structure=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
        "structure" => (d[:structure] = haselement(child) ? parse_term(firstelement(child); kw...) : nothing)
        _ => parse_pnml_label_common!(d, child; kw...)
        end
    end
    HLMarking(d)
end

"""
$(TYPEDSIGNATURES)
"""
function parse_hlinscription(node; kw...)
    @debug node
    nn = nodename(node)
    nn == "hlinscription" || error("element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    foreach(elements(node)) do child
        @match nodename(child) begin
    #        "structure" => (d[:structure] = parse_term(child; kw...))
        "structure" => (d[:structure] = haselement(child) ? parse_term(firstelement(child); kw...) : nothing)
        _ => parse_pnml_label_common!(d, child; kw...)
        end
    end
    HLInscription(d)
end

"""
$(TYPEDSIGNATURES)

Annotation label of transition nodes.
"""
function parse_condition(node; kw...)
    @debug node
    nn = nodename(node)
    nn == "condition" || error("element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn))
    #cute trick    parse_pnml_label_common!.(Ref(d), elements(node); kw...)
    foreach(elements(node)) do child
        @match nodename(child) begin
            #"structure" => (d[:structure] = parse_term(child; kw...))
            "structure" => (d[:structure] = haselement(child) ? parse_term(firstelement(child); kw...) : nothing)
            _ => parse_pnml_label_common!(d, child; kw...)
        end
    end
    Condition(d)
end

#---------------------------------------------------------------------
#TODO Will unclaimed_node handle this?
"""
Should not often have a '<label>' tag, this will bark if one is found.
Return minimal PnmlDict holding (tag,node), to defer parsing the xml.

$(TYPEDSIGNATURES)
"""
function parse_label(node; kw...)
    nn = nodename(node)
    nn == "label" || error("element name wrong: $nn")
    @warn "parse_label '$(node !== nothing && nn)'"
    PnmlDict(:tag=>Symbol(nn), :xml=>node) # Always add xml because this is unexpected.
end
