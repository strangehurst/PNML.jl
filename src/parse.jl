#TODO; replace Any by more specific types
#const PnmlDict = Dict{Symbol, Union{Nothing,Any}}
const PnmlDict = Dict{Symbol, Union{Nothing,Dict,Vector,NamedTuple,Symbol,AbstractString,Number}}

"Build pnml from a string."
function parse_str(str)
    doc = EzXML.parsexml(str)
    parse_doc(doc)
end

"Build pnml from a file."
function parse_file(fn)
    doc = EzXML.readxml(fn)
    parse_doc(doc)
end

"""
Start descent from the root XML element node of `doc`.
A well formed XML document has a single root node
"""
function parse_doc(doc)
    node = root(doc)
    pnml = parse_node(node)
    pnml    #TODO: return pnml document wrapping root "pnml" element.
end

"Return the striped string of text child's nodecontent in a named tuple."
function parse_text(node)
    nn = nodename(node)
    nn == "text" || error("parse_text element name wrong")
    (; :tag=>Symbol(nn), :content=>string(strip(nodecontent(node))),)#xml=>node, )
end

"""
    attribute_elem(node)

Return PnmlDict after debug print of nodename.
If element `node` has any children, each is placed in the dictonary with the
tag name symbol as the key, repeated tags produce a vector as the value.
Any XML attributes found are added as as key,value. to the tuple returned.

Note that this will recursivly decend the well-formed XML, transforming
the the children into vector NamedTuples & Dicts.

Note the assumption that children and content are mutually exclusive.
Content is always a leaf element. However XML attributes can be anywhere in
the hiearchy.
"""
function attribute_elem(node)
    @debug "attribute = $(nodename(node))"
    d = PnmlDict(:tag=>Symbol(nodename(node)),
                 (Symbol(a.name)=>(a.name=="id" ? Symbol(a.content) : a.content) for a in eachattribute(node))...)
#                 attribute_attributes(eachattribute(node))...)
    e = elements(node)
    if !isempty(e)
        merge!(d, attribute_content(e))
    else
        d[:content] = (!isempty(nodecontent(node)) ? strip(nodecontent(node)) : nothing)
    end
    includexml!(d, node)
    @debug d
    d
end

"Return vector of pairs."
function attribute_attributes(nv)
    #Symbol(a.name)=>a.content for a in
    v = Vector{Pair}[]
    for a in nv
        tag = Symbol(a.name)
        push!(v, Pair(tag, tag === :id ? Symbol(a.content) : a.content))
    end
    v
end

"""
Return PnmlDict with values that are vectors when there are multiple instances
of a tag in the `nv` node vector and scalar otherwise.
"""
function attribute_content(nv)
    d = PnmlDict()
    nn = [nodename(n)=>n for n in nv] # Not yet turned into Symbols.
    tagnames = unique(map(first,nn))
    foreach(tagnames) do tname 
        e = filter(x->x.first===tname, nn)
        
        d[Symbol(tname)] = if length(e) > 1
            map(x->parse_node(x.second), e)
        else
            parse_node(e[1].second)
        end
    end
    d
end


"Add `node` to`d[:labels]`. Return updated `d[:labels]`."
function add_label!(d::PnmlDict, node)
    @debug "add label $(nodename(node))"
    # Pnml considers any "unknown" element to be a label so its key is ':labels'.
    # The value is initialized to `nothing since it is expected that most labels
    # will have defined tags and semantics. And be given a key `:tag`.
    # Will convert value to a vector on first use.
    if d[:labels] === nothing
        d[:labels] = Any[] #TODO: pick type allowd in PnmlDict values? 
    end
    # Use of parse_node allows the :labels vector to contain fully parsed nodes.
    # Some higher-level might be able to make use of these.
    push!(d[:labels], parse_node(node))
end

"Add `node` to`d[:tools]`. Return updated `d[:tools]`."
function add_tool!(d::PnmlDict, node)
    if d[:tools] === nothing
        d[:tools] = Any[] #TODO: pick type allowd in PnmlDict values? 
    end
    # Use of parse_node allows the :tools vector to contain fully parsed nodes.
    # Some higher-level might be able to make use of these.
    push!(d[:tools], parse_node(node))
end

"Return Dict of tags common to both pnml nodes and pnml labels."
function pnml_common_defaults(node)
    d = PnmlDict(:graphics=>nothing, # graphics tag is single despite the 's'.
             :tools=>nothing, # Here the 's' indicates multiples are allowed.
             :labels=>nothing)
    includexml!(d, node)
    d
end
"""
Merge `xs` into dictonary with default pnml node tags.
Used on: net, page ,place, transition, arc.
Usually default value will be `nothing` or empty vector.
"""
function pnml_node_defaults(node, xs...) 
    PnmlDict(pnml_common_defaults(node)...,
             :name=>nothing,
             xs...)
end

"""5.17017
Merge `xs` into dictonary with default pnml label tags.
Used on pnml tags below a pnml_node tag.
Label level tags include: name, inscription, initialMarking.
Notable differences from [`pnml_node_defaults`](@ref): text, structure, no name tag.
"""
function pnml_label_defaults(node, xs...)
    PnmlDict(pnml_common_defaults(node)...,
             :text=>nothing,
             :structure=>nothing,
             xs...)
end


"""
    parse_node(node;verbose=true)

Take a `node` and parse it by calling the method matching `node.name` from
[`tagmap`](@ref) if it exists, otherwise call [`attribute_elem`](@ref).
`verbose` is a boolean controlling debug logging.
"""
function parse_node(node; verbose=true)
    node === nothing && return # Make all nodes optional. #TODO: is this a good idea?
    if verbose
        # Allow unknown tags to be treated as an attribute element.
        parser = haskey(tagmap, node.name) ? "present" : "attribute_elem"
        @debug( "parse_node($(node.name)) -> $(parser)" *
                " attributes $(nodename.(attributes(node)))" *
                " children $(nodename.(elements(node)))")
    end
    if haskey(tagmap, node.name)
        tagmap[node.name](node)
    else
        attribute_elem(node)
    end
end 

""" """
function parse_node_pair(node; verbose=true)
    Symbol(nodename(node)) => parse_node(node;verbose)
end

#TODO: make same as other label nodes?
"Return named tuple with pnml name text and optional tool & GUI information."
function parse_name(node)
    node === nothing && return # Pnml names are optional. #TODO: error check mode? redundant?
    nn = nodename(node)
    nn == "name" || error("parse_name element name wrong")
    # These can cause parse_node to be passed nothing.
    text     = parse_node(firstchild("text", node); verbose=false)
    graphics = parse_node(firstchild("graphics", node); verbose=false)
    ts = allchildren("toolspecific", node)
    tools = !isempty(ts) ? parse_node.(ts; verbose=false) : nothing
    # There are pnml files that break the rules & do not have a text element here.
    # Ex: PetriNetPlans-PNP/parallel.jl
    isnothing(text) && @warn "$(nn) missing <text> element"
    
    #TODO: rename :value to :content?
    (; :tag=>Symbol(nn), :value=>isnothing(text) ? nothing : text[:content],
     :graphics=>graphics, :tools=>tools)
end

"""
    parse_pnml_common(s, node)

Update `d` with graphics, tools, label children of pnml node and label elements.
Used by parse_pnml_node_commonlabel ! & parse_pnml_label_common!.
Adds, graphics, tools, labels.
Note that "lables" are the everything else option and this should be called after parsing
any elements that has an expected tags.
"""
function parse_pnml_common!(d::PnmlDict, node)
    @assert haskey(d, :graphics)
    @assert haskey(d, :tools)
    @assert haskey(d, :labels)

    @match nodename(node) begin
        "graphics"     => (d[:graphics] = parse_node(node))
        "toolspecific" => add_tool!(d, node)
        _ => add_label!(d,node) # label with a label allows any node to be attached & parsable.
    end
end

"""
    parse_pnml_node_common!(d, node)

Update `d` with name children, defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_node_common!(d::PnmlDict, node)
    @assert haskey(d, :name)
    
    @match nodename(node) begin
        "name" => (d[:name] = parse_node(node))
        _      => parse_pnml_common!(d,node)
    end
end

"""
    parse_pnml_label_common!(d, node)

Update `d` with  'text' and 'structure' children of `node`,
defering other tags to [`parse_pnml_common!`](@ref).
"""
function parse_pnml_label_common!(d, node)
    @assert haskey(d, :text)
    @assert haskey(d, :structure)
    !isempty(allchildren("name", node)) && @warn "label $(nodename(node)) has unexpected name"
    
    @match nodename(node) begin
        "text" => (d[:text] = parse_node(node)) #TODO label with name?
        "structure" => (d[:structure] = parse_node(node))
        "name" => (d[:name] = parse_node(node))
        _      => parse_pnml_common!(d,node)
    end
end

#------------------------------------------------------------
"""
    parse_pnml(node)

Start parse from the pnml root node of the well formed XML document.
Return a a named tuple with vector of pnml petri nets.
"""
function parse_pnml(node)
    nn = nodename(node)
    nn == "pnml" || error("parse_pnml element name wrong: $nn" )
    EzXML.hasnamespace(node) || @warn("$(nn) missing namespace: ", node)
    #TODO: Make @warn optional? Maybe can use default pnml namespace without notice.
    validate_node(node) #TODO
    nets = parse_node.(allchildren("net", node))
    if INCLUDEXML
        (; :tag=>Symbol(nn), :nets=>nets, :xml=>node)
    else
        (; :tag=>Symbol(nn), :nets=>nets)
    end
end

"""
    parse_net(node)

Return a dictonary of the pnml net with keys matching their XML tag names.
"""
function parse_net(node)
    nn = nodename(node)
    nn == "net" || error("parse_net element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_type(node) || throw(MalformedException("$(nn) missing type", node))
    
    isempty(allchildren("page", node)) && @warn "net does not have any pages"
    # Missing the page level in the pnml heirarchy causes nodes to be placed in :labels.
    # May result in undefined behavior and/or require ideosyncratic parsing.

    # Create a Dict with keys for possible child tags.
    # Some keys have known/required values.
    # Optional key values are nothing for single object or empty vector when multiples
    # are allowed. Keys that have pural names usually have a vector value.
    # The 'graphics' key is an exception and has a single value.
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]), :type=>node["type"],
                           :pages => [], :declarations => [])
    # Go through children looking for expected tags, delegating common tags and labels..
    foreach(elements(node)) do child
        @match nodename(child) begin
            "page"         => push!(d[:pages], parse_node(child))
            # NB: There is also a tag declarations that is different for this symbol.
            "declaration"  => push!(d[:declarations], parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d 
end

"""
    parse_page(node)

PNML requires at least on page.
"""
function parse_page(node)
    nn = nodename(node)
    nn == "page" || error("parse_page element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))

    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :places=>[], :trans=>[], :arcs=>[],
                           :refP=>[], :refT=>[],
                           :declarations=>[])

    foreach(elements(node)) do child
        @match nodename(child) begin
            "place"       => push!(d[:places], parse_node(child))
            "transition"  => push!(d[:trans], parse_node(child))
            "arc"         => push!(d[:arcs], parse_node(child))
            "referencePlace" => push!(d[:refP], parse_node(child))
            "referenceTransition" => push!(d[:refT], parse_node(child))
            "declaration" => push!(d[:declarations], parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_place(node)
    nn = nodename(node)
    nn == "place" || error("parse_place element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id => Symbol(node["id"]),
                           :marking => nothing, :type=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Tags initialMarking and hlinitialMarking are mutually exclusive.
            "initialMarking"   => (d[:marking] = parse_node(child))
            "hlinitialMarking" => (d[:marking] = parse_node(child))
            "type"             =>  (d[:type] = parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_transition(node)
    nn = nodename(node)
    nn == "transition" || error("parse_transition element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id => Symbol(node["id"]),
                           :condition=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "condition"    => (d[:condition] = parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_arc(node)
    nn = nodename(node)
    nn == "arc" || error("parse_arc element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    @assert has_source(node)
    @assert has_target(node)
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :source=>Symbol(node["source"]),
                           :target=>Symbol(node["target"]),
                           :inscription=>nothing)
    foreach(elements(node)) do child
        @match nodename(child) begin
            # Mutually exclusive tags: inscription, hlinscription
            "inscription"    => (d[:inscription] = parse_node(child))
            "hlinscription"  => (d[:inscription] = parse_node(child))
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_refPlace(node)
    nn = nodename(node)
    nn == "referencePlace" || error("parse_refPlace element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

function parse_refTransition(node)
    nn = nodename(node)
    nn == "referenceTransition" || error("parse_refTransition element name wrong: $nn")
    has_id(node) || throw(MissingIDException(nn, node))
    has_ref(node) || throw(MalformedException("$(nn) missing ref attribute", node))
    d = pnml_node_defaults(node, :tag=>Symbol(nn), :id=>Symbol(node["id"]),
                           :ref=>Symbol(node["ref"]))
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_node_common!(d,child)
        end
    end
    d
end

#
# structure is neither a pnml node nor a pnml annotation-label.
# Behaves like an attribute-label.
# Should be inside of an label. 
#
"""
Return dictonary including a vector of child content elements.
A pnml structure can possibly hold any well formed XML.
Structure will vary based on parent element and petri net type definition of the net.
#TODO: Specialized structure parsers are needed. 2nd pass parser?
"""
function parse_structure(node)
    nn = nodename(node)
    nn == "structure" || error("parse_structure element name wrong: $nn")
    attribute_elem(node)
end

#
# PNML label-like XML element parsers.
#

function parse_initialMarking(node)
    nn = nodename(node)
    nn == "initialMarking" || error("parse_initialMarking element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing, #=:xml=>node=#)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = tryparse(Int, string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child)
        end
    end
    d  
end

function parse_inscription(node)
    nn = nodename(node)
    nn == "inscription" || error("parse_inscription element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), :value=>nothing, #=:xml=>node=#)
    foreach(elements(node)) do child
        @match nodename(child) begin
            "text" => (d[:value] = tryparse(Int, string(strip(nodecontent(child)))))
            _ => parse_pnml_label_common!(d,child)
        end
    end
    d
end

function parse_hlinitialMarking(node)
    nn = nodename(node)
    nn == "hlinitialMarking" || error("parse_initialMarking element name wrong: $nn")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), #=:xml=>node=#)
    foreach(elements(node)) do child
        @match nodename(child) begin
            _ => parse_pnml_label_common!(d,child)
            
        end
    end
    d
end

function parse_hlinscription(node)
    @debug node
    nn = nodename(node)
    nn == "hlinscription" || error("parse_hlinscription element name wrong: $nn'")
    d = pnml_label_defaults(node, :tag=>Symbol(nn), #=:xml=>node=#)
    foreach(elements(node)) do child
        @match nodename(child) begin
           _ => parse_pnml_label_common!(d,child)
        end
    end
    d
end

#TODO: A '<label>' tag could be hidden inside a '<structure>' tag.
"""
Should not often have a 'label' tag, this will bark if one is found.
Return named tuple (tag,node), used to defer parsing the xml while matching
usage of PnmlDict that has at least the :tag and :xml keys.
"""
function parse_label(node)
    nn = nodename(node)
    nn == "label" || error("parse_label element name wrong: $nn")
    @warn "parse_label '$(node !== nothing && nn)'"
    (; :tag=>Symbol(nn), :xml=>node) # Always add xml because this is unexpected.
end
