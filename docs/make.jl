using PNML, PnmlTypeDefs, PnmlIDRegistrys
#using PrettyPrinting
using Documenter

using PnmlTypeDefs: PnmlType,
    StochasticNet,
    SymmetricNet,
    TimedNet,
    PnmlCore,
    OpenNet,
    HLCore,
    HLPNG # High-Level Petri Net Graph



using PNML

# Makie.jl is a source of many of these good ideas. (Bad ones are mine?)

################################################################################
#                              Utility functions                               #
################################################################################


################################################################################
#                                    Setup                                     #
################################################################################

#pathroot   = normpath(@__DIR__, "..")
#docspath   = joinpath(pathroot, "docs")
#srcpath    = joinpath(docspath, "src")
#buildpath  = joinpath(docspath, "build")
#genpath    = joinpath(srcpath,  "generated")
#srcgenpath = joinpath(docspath, "src_generation")
#! Eventually we plan on generating pictures, et al in genpath.
#mkpath(genpath) #TODO where should initialization happen?

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
         modules=[PNML, PnmlTypeDefs, PnmlIDRegistrys],
         authors="Jeff Hurst <strangehurst@users.noreply.github.com>",
         #repo="https://github.com/strangehurst/PNML.jl/blob/{commit}{path}#{line}",
         repo="/home/jeff/PNML/{path}",
         checkdocs=:all,

         format=Documenter.HTML(;
                                # CI means publish documentation on GitHub.
                                prettyurls=get(ENV, "CI", nothing) == "true",
                                canonical="https://strangehurst.github.io/PNML.jl",
                                #assets=String[],
                                #prerender=false,
                                #no highlight.js
                                ),
         sitename="PNML.jl",
         pages=[
            "Petri Net Markup Language" => "pnml.md",
            "Subpackages" => "subpackages.md",
            "Intermediate Representation" => "IR.md",
            "Type Hierarchies" => "type_hierarchies.md",
            "Interfaces" => "interface.md",
            "API" => [
                "PNML"      => "API/library.md",
               # "PnmlTypeDefs" => "API/pnmltypes.md"
            ],
            "Default Values"   => "defaults.md",
            "Parser" => "parser.md",
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
