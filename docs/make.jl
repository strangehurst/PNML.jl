using PNML
using PrettyPrinting
using Documenter

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

# copy news file into src directory
cp(joinpath(pathroot, "NEWS.md"), joinpath(srcpath, "news.md"); force=true)

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

@info("Running `makedocs` from make.jl.")

makedocs(;
         clean = true,
         modules=[PNML],
         authors="Jeff Hurst <strangehurst@users.noreply.github.com>",
         repo="https://github.com/strangehurst/PNML.jl/blob/{commit}{path}#{line}",
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
             "Home" => "index.md",
             
             "API" => "library.md",
             "Intermediate Representation" => "IR.md",
             "pnml.md",
             "Examples" => Any[
                 "lotka-volterra.md",
                 "example2.md",
             ],
             "news.md",
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
