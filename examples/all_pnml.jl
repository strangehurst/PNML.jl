# julia ~/Jules/PNToyBox/scripts/all_pnml.jl
# include("all_pnml.jl")

#using PNMLTree
using PNML
#using ProfileView, BenchmarkTools
#using PrettyPrinting
using DataFrames, DataFramesMeta

function testpn(;topdir="/home/jeff/Projects/Resources/PetriNet/PNML",
                dir="examples")
    pnml = endswith(".pnml")
    df = DataFrame() # Collects data from tests.
    cd(joinpath(topdir, dir)) do
        for (root, dirs, files) in walkdir(".")
            for file in filter(pnml, files)
                # Display path to file.
                f = lstrip(joinpath(root, file),['.', '/'])
                print(f, " size = ", filesize(f), "\n")
                try
                    # Gather performance data on parsing into PNML.
                    stats = @timed parse_file(f)
                    push!(df, (file=f, size=filesize(f),
                               time=stats.time, bytes=stats.bytes, gctime=stats.gctime))
                    # Display the PnmlModel as a test of the
                    # parsing, creation and show() implementation.
                    @show stats.value
                catch e
                    if e isa PNML.PnmlException
                        @warn " failed: $e"
                    elseif e isa InterruptException
                        return
                    else
                        sprint(showerror, e)
                    end
                end
            end
        end
    end
    # Display the gathered data frame.
    display(sort(df, [:time]))
end
