using PNML, PNML.PnmlTypes
#using PrettyPrinting
using Documenter

using PNML
using PNML: AbstractHLCore,
    AbstractLabel,
    AbstractPnmlTool,
    Arc,
    Condition,
    Coordinate,
    AbstractDeclaration,
    AbstractSort,
    BuiltInSort,
    MultisetSort,
    ProductSort,
    UserSort,
    Term,
    Variable,
    AbstractOperator,
    BuiltInOperator,
    BuiltInConst,
    MultiSetOperator,
    PnmlTuple,
    UserOperator,
    Fill,
    Font,
    Graphics,
    HLCore,
    HLAnnotation,
    HLInscription,
    HLMarking,
    HLNet,
    HLPetriNet,
    IDRegistry,
    Line,
    MalformedException,
    Maybe,
    MissingIDException,
    Name,
    ObjectCommon,
    OpenNet,
    PNML,
    PTInscription,
    PTMarking,
    PTNet,
    PT_HLPNG,
    Page,
    PetriNet,
    Place,
    PnmlCfg,
    PnmlCore,
    PnmlDict,
    PnmlException,
    PnmlLabel,
    PnmlModel,
    PnmlNet,
    PnmlNode,
    PnmlObject,
    PnmlType,
    PnmlTypes,
    RefPlace,
    RefTransition,
    SimpleNet,
    StochasticNet,
    SymmetricNet,
    TimedNet,
    TokenGraphics,
    ToolInfo,
    Transition,
    XMLNode,
    _harvest_any!,
    _match,
    add_label!,
    add_toolinfo!,
    all_arcs,
    allchildren,
    append_page!,
    arc,
    arc_ids,
    arcs,
    condition,
    conditions,
    convert,
    deref!,
    deref_place,
    deref_transition,
    duplicate_id_action,
    find_net,
    find_nets,
    first_net,
    firstchild,
    firstpage,
    flatten_pages!,
    get_label,
    get_toolinfo,
    has_arc,
    has_graphics,
    has_label,
    has_labels,
    has_name,
    has_place,
    has_refP,
    has_refT,
    has_structure,
    has_text,
    has_toolinfo,
    has_tools,
    has_transition,
    has_xml,
    in_out,
    inc_indent,
    indent,
    indent_width,
    infos,
    initialMarking,
    ins,
    inscription,
    isregistered,
    marking,
    nets,
    number_value,
    outs,
    parse_and,
    parse_arbitraryoperator,
    parse_arbitrarysort,
    parse_arc,
    parse_bool,
    parse_booleanconstant,
    parse_condition,
    parse_declaration,
    parse_declarations,
    parse_equality,
    parse_file,
    parse_graphics,
    parse_graphics_coordinate,
    parse_graphics_fill,
    parse_graphics_font,
    parse_graphics_line,
    parse_hlinitialMarking,
    parse_hlinscription,
    parse_imply,
    parse_inequality,
    parse_initialMarking,
    parse_inscription,
    parse_label,
    parse_mulitsetsort,
    parse_name,
    parse_namedoperator,
    parse_net,
    parse_node,
    parse_not,
    parse_or,
    parse_page,
    parse_place,
    parse_pnml,
    parse_pnml_common!,
    parse_pnml_label_common!,
    parse_pnml_node_common!,
    parse_productsort,
    parse_refPlace,
    parse_refTransition,
    parse_sort,
    parse_str,
    parse_structure,
    parse_term,
    parse_text,
    parse_tokengraphics,
    parse_tokenposition,
    parse_toolspecific,
    parse_transition,
    parse_tuple,
    parse_type,
    parse_unparsed,
    parse_useroperator,
    parse_usersort,
    parse_variable,
    parse_variabledecl,
    pid,
    place,
    place_ids,
    places,
    pnml_common_defaults,
    pnml_label_defaults,
    pnml_namespace,
    pnml_node_defaults,
    pnml_ns,
    rate,
    rates,
    refplace,
    refplace_ids,
    refplaces,
    reftransition,
    reftransition_ids,
    reftransitions,
    register_id!,
    reset_registry!,
    show_common,
    show_page_field,
    source,
    src_arcs,
    structure,
    tag,
    tagmap,
    target,
    text,
    tgt_arcs,
    transition,
    transition_function,
    transition_ids,
    transitions,
    nettype,
    unclaimed_label,
    update_maybe!,
    xmlnode


# Makie.jl is a source of many of these good ideas. (Bad ones are mine?)

################################################################################
#                              Utility functions                               #
################################################################################


################################################################################
#                                    Setup                                     #
################################################################################

pathroot   = normpath(@__DIR__, "..")
docspath   = joinpath(pathroot, "docs")
srcpath    = joinpath(docspath, "src")
buildpath  = joinpath(docspath, "build")
genpath    = joinpath(srcpath,  "generated")
srcgenpath = joinpath(docspath, "src_generation")

# Eventually we plan on generating pictures, et al in genpath.

mkpath(genpath) #TODO where should initialization happen?

################################################################################
#                          Syntax highlighting theme                           #
################################################################################

#TODO


################################################################################
#                      Automatic Markdown page generation                      #
################################################################################

#TODO


################################################################################
#                 Building HTML documentation with Documenter                  #
################################################################################

DocMeta.setdocmeta!(PNML, :DocTestSetup, :(using PNML); recursive=true)

for m ∈ [PNML]
    for i ∈ propertynames(m)
       xxx = getproperty(m, i)
       println(xxx)
    end
 end

@info("Running `makedocs` from make.jl.")

makedocs(;
         clean = true,
         doctest=true,
         modules=[PNML], #, PNML.PnmlTypes],
         authors="Jeff Hurst <strangehurst@users.noreply.github.com>",
         #repo="https://github.com/strangehurst/PNML.jl/blob/{commit}{path}#{line}",
         repo="/home/jeff/PNML/{path}",
         checkdocs=:all,

         format=Documenter.HTML(;
                                # CI means publish documentation on GitHub.
                                prettyurls=get(ENV, "CI", nothing) == "true",
                                canonical="https://strangehurst.github.io/PNML.jl",
                                assets=String[],
                                sidebar_sitename=true,
                                prerender=false,
                                #no highlight.js
                                ),
         sitename="PNML.jl",
         pages=[
            "Petri Net Markup Language" => "pnml.md",
            "API" => [
                "PNML"      => "API/library.md",
                "PnmlTypes" => "API/pnmltypes.md"
            ],
            "Intermediate Representation" => "IR.md",
            "Interfaces" => "interface.md",
            "Examples"   => "examples.md",
            "Index" => "index.md",
            "acknowledgments.md",
          ],
         )


################################################################################
#                           Deploying documentation                            #
################################################################################

if !isempty(get(ENV, "DOCUMENTER_KEY", ""))
    deploydocs(;
               repo="github.com/strangehurst/PNML.jl",
               devbranch = "main",
               push_preview = true,
               )
end
