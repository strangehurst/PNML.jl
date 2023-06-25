#julia -e 'include("/home/jeff/PNML/examples/all_pnml.jl"); testpn()' 2>&1 | tee  /tmp/testpn.txt

using PNML
using DataFrames, DataFramesMeta, Dates, CSV

function testpn(; topdir = "/home/jeff/Projects/Resources/PetriNet/PNML", dir = "examples",
                  outdir = "/tmp/testpmnl")
    pnml = endswith(".pnml")
    df = DataFrame() # Collects data from tests.
    # make outdir
    subd = Dates.format(now(), dateformat"yyyymmddHHSS")
    outdir = joinpath(outdir, subd)
    mkpath(outdir)
    @show outdir
    cd(joinpath(topdir, dir)) do
        for (root, dirs, files) in walkdir(".")
            for file in filter(pnml, files)
                f = lstrip(joinpath(root, file), ['.', '/'])
                println(f, " size = ", filesize(f)) # Display path to file and size.
                try
                    # Collect per-file output.
                    outfile = joinpath(outdir, (first ∘ splitext ∘ basename)(f)) #! collisions?
                    isfile(outfile) && println("overwrite")
                    Base.redirect_stdio(stdout=outfile, stderr=outfile) do
                        println(f)
                        stats = @timed parse_file(f)
                        push!(df, (file=f, fsize=filesize(f), time=stats.time, bytes=stats.bytes, gctime=stats.gctime))
                        # Display PnmlModel as a test of parsing, creation and show().
                        println()
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
    # Display the gathered data frame.
    sort!(df, [:time])
    write(joinpath(outdir, "DataFrame.txt"), repr(df))
    CSV.write(joinpath(outdir, "DataFrame.csv"), df)
end
