using PNML
using Documenter

DocMeta.setdocmeta!(PNML, :DocTestSetup, :(using PNML); recursive=true)

makedocs(;
    modules=[PNML],
    authors="Jeff Hurst <strangehurst@users.noreply.github.com>",
    repo="https://github.com/strangehurst/PNML.jl/blob/{commit}{path}#{line}",
    sitename="PNML.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://strangehurst.github.io/PNML.jl",
        assets=String[],
    ),
    pages=[
        "PNML.jl" => "index.md",
        "pnml.md",
        "Library Reference" => "library.md",
        "Examples" => [
            "lotka-volterra.md",
            "example2.md",
            ],
    ],
)

deploydocs(;
           repo="github.com/strangehurst/PNML.jl",
           devbranch = "dev"
           )
