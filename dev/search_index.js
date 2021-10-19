var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = PNML","category":"page"},{"location":"#PNML","page":"Home","title":"PNML","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for PNML.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [PNML]","category":"page"},{"location":"#PNML.PNML","page":"Home","title":"PNML.PNML","text":"PNML Module reads and parses a Petri Net Markup Language file.\n\n\n\n\n\n","category":"module"},{"location":"#PNML.INCLUDEXML","page":"Home","title":"PNML.INCLUDEXML","text":"Include the XML as part of data.\n\n\n\n\n\n","category":"constant"},{"location":"#PNML.Maybe","page":"Home","title":"PNML.Maybe","text":"Maybe of type T or nothing.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.default_pntd_map","page":"Home","title":"PNML.default_pntd_map","text":"default_pntd_map\n\nMap from Petri Net Type Definition (pntd) URI to Symbol. The URI used can be any string regardless of any violation of the PNML Specification. There is a companion map pnmltype_map that takes the symbol to a type object. The 'pntd symbol' should match the name used in the URI with inconvinient characters removed or replaced. For example, '-' is replaced by '_'.\n\n\n\n\n\n","category":"constant"},{"location":"#PNML.pnmltype_map","page":"Home","title":"PNML.pnmltype_map","text":"pnmltype_map\n\nThe keys are the supported kinds of Petri Nets.\n\nProvides a place to abstract relationship of pntd name and implementation type. Allows multiple strings to map to the same parser implementation. Is a point at which different parser implmentations may be introduced.\n\n\n\n\n\n","category":"constant"},{"location":"#PNML.tagmap","page":"Home","title":"PNML.tagmap","text":"Map XML tag names to parser functions.\n\n\n\n\n\n","category":"constant"},{"location":"#PNML.AbstractHLCore","page":"Home","title":"PNML.AbstractHLCore","text":"Base of High Level Petri Net pntds.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.AbstractPnmlCore","page":"Home","title":"PNML.AbstractPnmlCore","text":"Most minimal Petri Net type that is the foundation of all pntd.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.Document","page":"Home","title":"PNML.Document","text":"Wrap the collection of PNML nets from a single XML tree.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.HLCore","page":"Home","title":"PNML.HLCore","text":"High-Level Petri Nets add large extensions to core.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.IDRegistry","page":"Home","title":"PNML.IDRegistry","text":"Holds a set of pnml id symbols and a lock to allow safe reentrancy.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.MissingIDException","page":"Home","title":"PNML.MissingIDException","text":"Use exception to allow dispatch and additional data presentation to user.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.PTNet","page":"Home","title":"PNML.PTNet","text":"Place-Transition Petri Nets add small extensions to core.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.PnmlCfg","page":"Home","title":"PNML.PnmlCfg","text":"PnmlCfg\n\nContains configuration data. #TODO add something\n\n\n\n\n\n","category":"type"},{"location":"#PNML.PnmlCore","page":"Home","title":"PNML.PnmlCore","text":"All Petri Nets support core.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.PnmlType","page":"Home","title":"PNML.PnmlType","text":"abstract type PnmlType\n\nAbstract root of a dispatch type based on Petri Net Type Definition (pntd).\n\nEach Petri Net Markup Language (PNML) network element will have a single pntd URI as a required type XML attribute. That URI could/should refer to a RelaxNG schema defining the syntax and semantics of the XML model.\n\nSee (`pnmltype_map)[@ref] for the map from type string to a  dispatch singleton.\n\nWithin PNML.jl no schema-level validation is done. Nor is any use made of the schema within the code. Schemas, UML, ISO Specification and papers used to inform the design. See https://www.pnml.org/ for details.\n\nIn is allowed by the PNML specification to omit validation with the presumption that some specialized, external tool can be applied, thus allowing the file format to be used for inter-tool communication with lower overhead.\n\nSome pnml files exist that do not use a valid type URI. However it is done, an appropriate subtype of PnmlType must be chosen. Refer to to_net_type and pnmltype_map for how to get from the URI string to a Julia type.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.SimpleNet","page":"Home","title":"PNML.SimpleNet","text":"SimpleNet wraps the place, transition & arc collections of a single page of one net.\n\nOmits the page level of the pnml-defined hierarchy, and all labels at the merged net/page level of pnml. Note that there may be labels attached to the places, transitions & arcs.\n\nTODO: Support labels at net/page level? Some, all, non-standard?\n\nA multi-page net can be collpsed by removing referenceTransitions & referencePlaces, and merging labels of net and all pages.\n\n\n\n\n\n","category":"type"},{"location":"#PNML.add_label!-Tuple{Dict{Symbol, Union{Nothing, AbstractString, Number, Symbol, Dict, Vector{T} where T, NamedTuple}}, Any}","page":"Home","title":"PNML.add_label!","text":"Add node tod[:labels]. Return updated d[:labels].\n\n\n\n\n\n","category":"method"},{"location":"#PNML.add_nettype!-Union{Tuple{T}, Tuple{AbstractDict, Symbol, T}} where T<:PNML.PnmlType","page":"Home","title":"PNML.add_nettype!","text":"Add or replace mapping from symbol s to nettype dispatch singleton t.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.add_tool!-Tuple{Dict{Symbol, Union{Nothing, AbstractString, Number, Symbol, Dict, Vector{T} where T, NamedTuple}}, Any}","page":"Home","title":"PNML.add_tool!","text":"Add node tod[:tools]. Return updated d[:tools].\n\n\n\n\n\n","category":"method"},{"location":"#PNML.all_arcs-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.all_arcs","text":"Return vector of arcs that have a source or target of transition id.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.allchildren","page":"Home","title":"PNML.allchildren","text":"Return vector of 'elelement's immediate children withtag`.\n\n\n\n\n\n","category":"function"},{"location":"#PNML.attribute_content-Tuple{Any}","page":"Home","title":"PNML.attribute_content","text":"Return PnmlDict with values that are vectors when there are multiple instances of a tag in 'nv' and scalar otherwise.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.attribute_elem-Tuple{Any}","page":"Home","title":"PNML.attribute_elem","text":"attribute_elem(node)\n\nReturn PnmlDict after debug print of nodename. If element node has any children, each is placed in the dictonary with the tag name symbol as the key, repeated tags produce a vector as the value. Any XML attributes found are added as as key,value. to the tuple returned.\n\nNote that this will recursivly decend the well-formed XML, transforming the the children into vector NamedTuples & Dicts.\n\nNote the assumption that children and content are mutually exclusive. Content is always a leaf element. However XML attributes can be anywhere in the hiearchy.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.collapse_pages-Tuple{Any}","page":"Home","title":"PNML.collapse_pages","text":"collapse_pages(net)\n\nReturn NamedTuple holding merged page content.\n\nStart with simplest case of assuming that only the first page is meaningful. Collect places, transitions and arcs. #TODO COLLECT LABELS\n\n\n\n\n\n","category":"method"},{"location":"#PNML.condition-Tuple{Any}","page":"Home","title":"PNML.condition","text":"Return condition value of transition.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.condition-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.condition","text":"Return condition value of a transition with id t.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.conditions-Tuple{PNML.SimpleNet}","page":"Home","title":"PNML.conditions","text":"Return a vector of condition values for net s.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.duplicate_id_action-Tuple{Symbol}","page":"Home","title":"PNML.duplicate_id_action","text":"Use a global configuration to choose what to do when a duplicated pnml node id has been detected. Default is to do nothing. There are many pnml files on the internet that have many duplicates.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.find_nets","page":"Home","title":"PNML.find_nets","text":"Return nets of d matching the given pntd type.\n\n\n\n\n\n","category":"function"},{"location":"#PNML.firstchild","page":"Home","title":"PNML.firstchild","text":"Return up to 1 immediatechild of elementelthat is atag`.\n\n\n\n\n\n","category":"function"},{"location":"#PNML.has_place-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.has_place","text":"Is there any place with id in net s?\n\n\n\n\n\n","category":"method"},{"location":"#PNML.in_out-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.in_out","text":"Return tuple of input, output labelled vectors with key of place ids and value of arc inscription's value. \n\n\n\n\n\n","category":"method"},{"location":"#PNML.includexml-Tuple{Any}","page":"Home","title":"PNML.includexml","text":"Set value of key :xml based on global variable.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.inscription-Tuple{Any}","page":"Home","title":"PNML.inscription","text":"Return incription value of arc.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.inscription-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.inscription","text":"Return inscription value of an arc with id a.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.marking-Tuple{Any}","page":"Home","title":"PNML.marking","text":"Return marking value of a place P.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.marking-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.marking","text":"Return marking value of place with id p.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.node_summary","page":"Home","title":"PNML.node_summary","text":"node_summary([io::IO], node; n=5, pp=EzXML.prettyprint)\n\nPretty print the first n lines of the XML node. If io is not supplied, prints to the default output stream stdout. pp can be any pretty print method that takes (io::IO, node).\n\n\n\n\n\n","category":"function"},{"location":"#PNML.number_value-Tuple{AbstractString}","page":"Home","title":"PNML.number_value","text":"Parse XML content as a number. First try integer then float.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_and-Tuple{Any}","page":"Home","title":"PNML.parse_and","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_arbitraryoperator-Tuple{Any}","page":"Home","title":"PNML.parse_arbitraryoperator","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_arbitrarysort-Tuple{Any}","page":"Home","title":"PNML.parse_arbitrarysort","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_bool-Tuple{Any}","page":"Home","title":"PNML.parse_bool","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_booleanconstant-Tuple{Any}","page":"Home","title":"PNML.parse_booleanconstant","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_condition-Tuple{Any}","page":"Home","title":"PNML.parse_condition","text":"Annotation label of transition nodes. Meaning it can have text, graphics, et al.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_declaration-Tuple{Any}","page":"Home","title":"PNML.parse_declaration","text":"Attribute label of 'net' and 'page' nodes\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_declarations-Tuple{Any}","page":"Home","title":"PNML.parse_declarations","text":" parse_declarations(node; kwargs...)\n\nReturn NamedTuple with :contents holding a vector of parsed child elements.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_doc-Tuple{EzXML.Document}","page":"Home","title":"PNML.parse_doc","text":"parse_doc(doc::EzXML.Document)\n\nReturn a PNML.Document. Start descent from the root XML element node. A well formed PNML XML document has a single root node: 'pnml'.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_equality-Tuple{Any}","page":"Home","title":"PNML.parse_equality","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_file-Tuple{Any}","page":"Home","title":"PNML.parse_file","text":"Build pnml from a file.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_graphics-Tuple{Any}","page":"Home","title":"PNML.parse_graphics","text":"parse_graphics\n\nArcs, Annotations and Nodes (places, transitions, pages) have different graphics semantics. Return a dictonary with the union of possibilities.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_graphics_coordinate-Tuple{Any}","page":"Home","title":"PNML.parse_graphics_coordinate","text":"Coordinates x, y are in points.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_imply-Tuple{Any}","page":"Home","title":"PNML.parse_imply","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_inequality-Tuple{Any}","page":"Home","title":"PNML.parse_inequality","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_label-Tuple{Any}","page":"Home","title":"PNML.parse_label","text":"Should not often have a 'label' tag, this will bark if one is found. Return named tuple (tag,node), used to defer parsing the xml while matching usage of PnmlDict that has at least the :tag and :xml keys.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_mulitsetsort-Tuple{Any}","page":"Home","title":"PNML.parse_mulitsetsort","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_name-Tuple{Any}","page":"Home","title":"PNML.parse_name","text":"Return named tuple with pnml name text and optional tool & GUI information.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_namedoperator-Tuple{Any}","page":"Home","title":"PNML.parse_namedoperator","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_net-Tuple{Any}","page":"Home","title":"PNML.parse_net","text":"parse_net(node)\n\nReturn a dictonary of the pnml net with keys matching their XML tag names.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_node-Tuple{Any}","page":"Home","title":"PNML.parse_node","text":"parse_node(node;verbose=true)\n\nTake a node and parse it by calling the method matching node.name from tagmap if mapping exists, otherwise call attribute_elem. verbose is a boolean controlling debug logging.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_not-Tuple{Any}","page":"Home","title":"PNML.parse_not","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_or-Tuple{Any}","page":"Home","title":"PNML.parse_or","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_page-Tuple{Any}","page":"Home","title":"PNML.parse_page","text":"parse_page(node)\n\nPNML requires at least on page.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_pnml-Tuple{Any}","page":"Home","title":"PNML.parse_pnml","text":"parse_pnml(node; reg=IDRegistry())\n\nStart parse from the pnml root node of the well formed XML document. Return a a named tuple containing vector of pnml petri nets.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_pnml_common!-Tuple{Dict{Symbol, Union{Nothing, AbstractString, Number, Symbol, Dict, Vector{T} where T, NamedTuple}}, Any}","page":"Home","title":"PNML.parse_pnml_common!","text":"parse_pnml_common(s, node; kwargs...)\n\nUpdate d with graphics, tools, label children of pnml node and label elements. Used by parsepnmlnodecommonlabel ! & parsepnmllabelcommon!. Adds, graphics, tools, labels. Note that \"lables\" are the everything else option and this should be called after parsing any elements that has an expected tags.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_pnml_label_common!-Tuple{Any, Any}","page":"Home","title":"PNML.parse_pnml_label_common!","text":"parse_pnml_label_common!(d, node; kwargs...)\n\nUpdate d with  'text' and 'structure' children of node, defering other tags to parse_pnml_common!.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_pnml_node_common!-Tuple{Dict{Symbol, Union{Nothing, AbstractString, Number, Symbol, Dict, Vector{T} where T, NamedTuple}}, Any}","page":"Home","title":"PNML.parse_pnml_node_common!","text":"parse_pnml_node_common!(d, node; kwargs...)\n\nUpdate d with name children, defering other tags to parse_pnml_common!.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_productsort-Tuple{Any}","page":"Home","title":"PNML.parse_productsort","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_str-Tuple{Any}","page":"Home","title":"PNML.parse_str","text":"Build pnml from a string.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_structure-Tuple{Any}","page":"Home","title":"PNML.parse_structure","text":"Return dictonary including a vector of child content elements. A pnml structure can possibly hold any well formed XML. Structure will vary based on parent element and petri net type definition of the net. #TODO: Specialized structure parsers are needed. 2nd pass parser?\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_term-Tuple{Any}","page":"Home","title":"PNML.parse_term","text":"parse_term(n)\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_text-Tuple{Any}","page":"Home","title":"PNML.parse_text","text":"Return the striped string of text child's nodecontent in a named tuple.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_tokengraphics-Tuple{Any}","page":"Home","title":"PNML.parse_tokengraphics","text":"High-level place-transition nets have a toolspecific structure defined for token graphics.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_tokenposition-Tuple{Any}","page":"Home","title":"PNML.parse_tokenposition","text":"Position is relative to containing element. Units are points.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_toolspecific-Tuple{Any}","page":"Home","title":"PNML.parse_toolspecific","text":"Return tuple with tag name, tool & version attributes and xml node. Anyone that can parse the nodecontents may specialize on tool & version.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_tuple-Tuple{Any}","page":"Home","title":"PNML.parse_tuple","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_type-Tuple{Any}","page":"Home","title":"PNML.parse_type","text":"Parse type of a place. Id different from net type or pntd.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.parse_unparsed-Tuple{Any}","page":"Home","title":"PNML.parse_unparsed","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_useroperator-Tuple{Any}","page":"Home","title":"PNML.parse_useroperator","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_usersort-Tuple{Any}","page":"Home","title":"PNML.parse_usersort","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_variable-Tuple{Any}","page":"Home","title":"PNML.parse_variable","text":"\n\n\n\n","category":"method"},{"location":"#PNML.parse_variabledecl-Tuple{Any}","page":"Home","title":"PNML.parse_variabledecl","text":"\n\n\n\n","category":"method"},{"location":"#PNML.place-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.place","text":"Return the place with id in net s.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.pnml_common_defaults-Tuple{Any}","page":"Home","title":"PNML.pnml_common_defaults","text":"Return Dict of tags common to both pnml nodes and pnml labels.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.pnml_label_defaults-Tuple{Any, Vararg{Any, N} where N}","page":"Home","title":"PNML.pnml_label_defaults","text":"Merge xs into dictonary with default pnml label tags. Used on pnml tags below a pnmlnode tag. Label level tags include: name, inscription, initialMarking. Notable differences from [`pnmlnode_defaults`](@ref): text, structure, no name tag.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.pnml_node_defaults-Tuple{Any, Vararg{Any, N} where N}","page":"Home","title":"PNML.pnml_node_defaults","text":"Merge xs into dictonary with default pnml node tags. Used on: net, page ,place, transition, arc. Usually default value will be nothing or empty vector.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.pntd-Tuple{AbstractString}","page":"Home","title":"PNML.pntd","text":"pntd(s::AbstractString) Map s to a pntd symbol. Any unknown s is mapped to pnmlcore.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.register_id!-Tuple{PNML.IDRegistry, AbstractString}","page":"Home","title":"PNML.register_id!","text":"Register id symbol and return the symbol.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.reset_registry!-Tuple{PNML.IDRegistry}","page":"Home","title":"PNML.reset_registry!","text":"reset_registry!(reg)\n\nEmpty the set of id symbols. Use case is unit tests. In normal use it should never be needed.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.src_arcs-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.src_arcs","text":"Return vector of arcs that have a source of transition id.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.tgt_arcs-Tuple{PNML.SimpleNet, Symbol}","page":"Home","title":"PNML.tgt_arcs","text":"Return vector of arcs that have a  target of transition id.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.to_net_type","page":"Home","title":"PNML.to_net_type","text":"to_net_type(uri)\nto_net_type(symbol)\n\nMap either a text string or a symbol to a dispatch type singlton.\n\nWhile that string may be a URI for a pntd, we treat it as a simple string without parsing. The pnmltypemap and pntdmap are both assumed to be correct here.\n\nUnknown or empty uri will map to symbol :pnmlcore as part of the logic. Unknown symbol returns nothing.\n\n\n\n\n\n","category":"function"},{"location":"#PNML.to_net_type_sym-Tuple{AbstractString}","page":"Home","title":"PNML.to_net_type_sym","text":"to_net_type_sym(uri)\n\nWe map uri to a symbol using a dictionary like default_pntd_map. Return symbol that is a valid pnmltype_map key. Defaults to :pnmlcore.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.transition_function-Tuple{PNML.SimpleNet}","page":"Home","title":"PNML.transition_function","text":"Transition function of a Petri Net. Each transition has an input vector and an output vector. Each labelled vector is indexed by the place on the other end of the arc. Values are inscriptions.\n\n\n\n\n\n","category":"method"},{"location":"#PNML.validate-Tuple{Symbol}","page":"Home","title":"PNML.validate","text":"Log a warning if s is not a known Petri Net Markup Language schema/pntd. \n\n\n\n\n\n","category":"method"},{"location":"#PNML.validate_node-Tuple{Any}","page":"Home","title":"PNML.validate_node","text":"\n\n\n\n","category":"method"},{"location":"#PNML.validate_pnml-Tuple{Any}","page":"Home","title":"PNML.validate_pnml","text":"Check the <pnml> element against TODO.\n\nReturn TODO\n\n\n\n\n\n","category":"method"},{"location":"#PNML.@xml_str-Tuple{Any}","page":"Home","title":"PNML.@xml_str","text":"@xml_str(s)\n\nUtility macro for parsing xml strings into node.\n\n\n\n\n\n","category":"macro"}]
}
