using PNML, EzXML, ModuleDocstrings, InteractiveUtils

node = EzXML.ElementNode("n1/")
reg = PNML.IDRegistry()
pdict = PNML.PnmlDict()

InteractiveUtils.@code_warntype PNML.parse_file("file")
InteractiveUtils.@code_warntype PNML.parse_str("</tag>")
InteractiveUtils.@code_warntype PNML.parse_doc(EzXML.parsexml("<pnml></pnml>"))

InteractiveUtils.@code_warntype PNML.parse_pnml(node; reg)
InteractiveUtils.@code_warntype PNML.parse_net(node; reg)
InteractiveUtils.@code_warntype PNML.parse_arc(node; reg)

#@xml_str
InteractiveUtils.@code_warntype PNML.parse_node(node; reg)
InteractiveUtils.@code_warntype PNML.attribute_content([node]; reg)
InteractiveUtils.@code_warntype PNML.attribute_elem(node; reg)
InteractiveUtils.@code_warntype PNML.parse_name(node; reg)
InteractiveUtils.@code_warntype PNML.parse_text(node; reg)
InteractiveUtils.@code_warntype PNML.parse_structure(node; reg)
InteractiveUtils.@code_warntype PNML.add_label!(pdict, node; reg)
InteractiveUtils.@code_warntype PNML.add_tool!(pdict, node; reg)

InteractiveUtils.@code_warntype PNML.pnml_common_defaults(node)
InteractiveUtils.@code_warntype PNML.pnml_label_defaults(node; pdict)
InteractiveUtils.@code_warntype PNML.pnml_node_defaults(node; pdict)

InteractiveUtils.@code_warntype PNML.parse_pnml_common!(pdict, node; reg)
InteractiveUtils.@code_warntype PNML.parse_pnml_label_common!(pdict, node; reg)
InteractiveUtils.@code_warntype PNML.parse_pnml_node_common!(pdict, node; reg)

InteractiveUtils.@code_warntype PNML.nets(node; reg)
InteractiveUtils.@code_warntype PNML.parse_page(node; reg)
InteractiveUtils.@code_warntype PNML.parse_place(node; reg)
InteractiveUtils.@code_warntype PNML.parse_transition(node; reg)
InteractiveUtils.@code_warntype PNML.place(node; reg)

InteractiveUtils.@code_warntype PNML.parse_label(node; reg)
InteractiveUtils.@code_warntype PNML.parse_toolspecific(node; reg)

InteractiveUtils.@code_warntype PNML.parse_tokengraphics(node; reg)
InteractiveUtils.@code_warntype PNML.parse_tokenposition(node; reg)
InteractiveUtils.@code_warntype PNML.parse_graphics(node; reg)
InteractiveUtils.@code_warntype PNML.parse_graphics_coordinate(node; reg)

InteractiveUtils.@code_warntype PNML.parse_condition(node; reg)
InteractiveUtils.@code_warntype PNML.parse_type(node; reg)
InteractiveUtils.@code_warntype PNML.inscription(node; reg)
InteractiveUtils.@code_warntype PNML.marking(node; reg)

InteractiveUtils.@code_warntype PNML.parse_and(node; reg)
InteractiveUtils.@code_warntype PNML.parse_arbitraryoperator(node; reg)
InteractiveUtils.@code_warntype PNML.parse_arbitrarysort(node; reg)
InteractiveUtils.@code_warntype PNML.parse_bool(node; reg)
InteractiveUtils.@code_warntype PNML.parse_booleanconstant(node; reg)
InteractiveUtils.@code_warntype PNML.parse_declaration(node; reg)
InteractiveUtils.@code_warntype PNML.parse_declarations(node; reg)
InteractiveUtils.@code_warntype PNML.parse_equality(node; reg)
InteractiveUtils.@code_warntype PNML.parse_imply(node; reg)
InteractiveUtils.@code_warntype PNML.parse_inequality(node; reg)
InteractiveUtils.@code_warntype PNML.parse_mulitsetsort(node; reg)
InteractiveUtils.@code_warntype PNML.parse_namedoperator(node; reg)
InteractiveUtils.@code_warntype PNML.parse_not(node; reg)
InteractiveUtils.@code_warntype PNML.parse_or(node; reg)
InteractiveUtils.@code_warntype PNML.parse_productsort(node; reg)
InteractiveUtils.@code_warntype PNML.parse_sort(node; reg)
InteractiveUtils.@code_warntype PNML.parse_term(node; reg)
InteractiveUtils.@code_warntype PNML.parse_tuple(node; reg)
InteractiveUtils.@code_warntype PNML.parse_unparsed(node; reg)
InteractiveUtils.@code_warntype PNML.parse_useroperator(node; reg)
InteractiveUtils.@code_warntype PNML.parse_usersort(node; reg)
InteractiveUtils.@code_warntype PNML.parse_variable(node; reg)
InteractiveUtils.@code_warntype PNML.parse_variabledecl(node; reg)

InteractiveUtils.@code_warntype PNML.add_nettype!(pdict, :simple, :pnmlcore)
InteractiveUtils.@code_warntype PNML.compress(pdict)
InteractiveUtils.@code_warntype PNML.compress([pdict])
InteractiveUtils.@code_warntype PNML.compress!(pdict)
InteractiveUtils.@code_warntype PNML.compress!([pdict])
InteractiveUtils.@code_warntype PNML.to_net_type(PNML.PnmlCore())
InteractiveUtils.@code_warntype PNML.to_net_type_sym("open")
InteractiveUtils.@code_warntype PNML.is_net_type(:pnmlcore)
InteractiveUtils.@code_warntype PNML.pntd("open")
InteractiveUtils.@code_warntype PNML.collapse_pages!(pdict)

#=
InteractiveUtils.@code_warntype PNML.condition
InteractiveUtils.@code_warntype PNML.conditions

InteractiveUtils.@code_warntype PNML.all_arcs
InteractiveUtils.@code_warntype PNML.allchildren
InteractiveUtils.@code_warntype PNML.default_pntd_map
InteractiveUtils.@code_warntype PNML.deref!
InteractiveUtils.@code_warntype PNML.duplicate_id_action
InteractiveUtils.@code_warntype PNML.find_nets
InteractiveUtils.@code_warntype PNML.first_net
InteractiveUtils.@code_warntype PNML.firstchild
InteractiveUtils.@code_warntype PNML.has_place
InteractiveUtils.@code_warntype PNML.in_out
InteractiveUtils.@code_warntype PNML.includexml
InteractiveUtils.@code_warntype PNML.node_summary
InteractiveUtils.@code_warntype PNML.number_value
InteractiveUtils.@code_warntype PNML.place_ids
InteractiveUtils.@code_warntype PNML.pnmltype_map
InteractiveUtils.@code_warntype PNML.register_id!
InteractiveUtils.@code_warntype PNML.reset_registry!
InteractiveUtils.@code_warntype PNML.src_arcs
InteractiveUtils.@code_warntype PNML.tagmap
InteractiveUtils.@code_warntype PNML.tgt_arcs
InteractiveUtils.@code_warntype PNML.transition_function
=#
#=
PNML.Document
PNML.IDRegistry
PNML.PnmlCfg
PNML.SimpleNet

=#

