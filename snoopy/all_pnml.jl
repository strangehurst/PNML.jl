#julia -e 'include("all_pnml.jl"); testpn()'
#julia -e 'include("all_pnml.jl"); testpn(dir="MCC")'
#julia -e 'include("all_pnml.jl"); testpn(topdir="/home/jeff/Projects/Resources/PetriNet/ePNK", dir="pnml-examples")'

using PNML
using DataFrames, DataFramesMeta, Dates, CSV

function testpn(; topdir = "/home/jeff/Projects/Resources/PetriNet/PNML", dir = "examples",
                  outdir = "/home/jeff/Jules/testpmnl")
    pnml = endswith(".pnml")
    df = DataFrame() # Collects data from tests.
    indir  = joinpath(topdir, dir)
    subd = Dates.format(now(), dateformat"yyyymmddHHMM")
    outdir = joinpath(outdir, subd)
    mkpath(outdir)
    @show indir outdir
    cd(indir) do
        for (root, dirs, files) in walkdir(".")
            for file in filter(pnml, files)
                f = lstrip(joinpath(root, file), ['.', '/'])
                println(f, " size = ", filesize(f)) # Display path to file and size.
                try
                    # Collect per-file output.
                    #outfile = joinpath(outdir, (first ∘ splitext ∘ basename)(f))
                    outfile = joinpath(outdir, (first ∘ splitext)(f))
                    mkpath(dirname(outfile)) # Create output directory.
                    isfile(outfile) && println("Warning overwriting $outfile")
                    Base.redirect_stdio(stdout=outfile, stderr=outfile) do
                        println(f)
                        println()
                        stats = @timed parse_file(f)
                        push!(df, (file=f, fsize=filesize(f), time=stats.time, bytes=stats.bytes, gctime=stats.gctime))
                        # Display PnmlModel as a test of parsing, creation and show().
                        println(stats.value)
                    end
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

    sort!(df, [:time])
    write(joinpath(outdir, "DataFrame.txt"), repr(df))
    CSV.write(joinpath(outdir, "DataFrame.csv"), df)
end
