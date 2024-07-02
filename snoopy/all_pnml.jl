#julia -e 'include("all_pnml.jl"); testpn()'
#julia -e 'include("all_pnml.jl"); testpn("MCC")'
#julia -e 'include("all_pnml.jl"); testpn(topdir="/home/jeff/Projects/Resources/PetriNet/ePNK", dir="pnml-examples")'
#julia -t1 --project=.snoopy  -e 'include("all_pnml.jl"); testpn("")' 2>&1 | tee  /tmp/testpn.txt
#julia -t1 --project=.snoopy  -e 'include("snoopy/all_pnml.jl"); testfile("/home/jeff/Jules/test-files.list")'
using PNML
using DataFrames, DataFramesMeta, Dates, CSV, Graphs, MetaGraphsNext
using LoggingExtras

# Use default display width for printing.
if !haskey(ENV, "COLUMNS")
    ENV["COLUMNS"] = 180
end

pnml_files(files) = filter(files) do f
    isfile(f) && success(run(Cmd(`grep -qF "<pnml" $f`, ignorestatus=true)))
end

function testfile(file::AbstractString = "test-files.list";
                  topdir = "/home/jeff/PetriNet/PNML",
                  outdir = "/home/jeff/Jules/testpmnl")
    opened = open(file)
    tests = filter(l -> !isempty(l) && !contains(l, r"^\s*#"), readlines(opened))
    #tests = map(i->joinpath(topdir,i),
    #            filter(l -> !isempty(l) && !contains(l, r"^\s*#"), readlines(opened)))
    close(opened)
    println("running ", length(tests), " tests in ", file)
    _testpn(tests; topdir, outdir)
end

function testpn(dir = "";
                topdir = "/home/jeff/PetriNet/PNML",
                outdir = "/home/jeff/Jules/testpmnl")

    srcdir = isempty(dir) ? topdir : joinpath(topdir, dir)
    tests = String[] # Construct list of test files.
    cd(srcdir) do
        for (root, _, files) in walkdir(".")
            flist = map(f -> joinpath(root, f), filter(endswith(r"pnml|xml"), files))
            pnmls = filter(f -> success(run( Cmd(`grep -qF "<pnml xmlns" "$f"`, ignorestatus=true))), flist)
            append!(tests, map(l->chop(l; head=2, tail=0), pnmls)) # remove leading "./"
        end
    end
    println("running ", length(tests), " tests from $srcdir")
    _testpn(tests; topdir=srcdir, outdir)
end


function _testpn(tests::Vector{String} = String[];
                topdir = "/home/jeff/PetriNet/PNML",
                outdir = "/home/jeff/Jules/testpmnl")

    outdir = joinpath(outdir, Dates.format(now(), dateformat"yyyymmddHHMM"))
    mkpath(outdir)

    consolelogger = ConsoleLogger(stdout, Logging.Debug)
    outputlog = joinpath(outdir, "testrun.log")
    filelogger = FileLogger(outputlog)
    demux_logger = TeeLogger(consolelogger, MinLevelLogger(filelogger, Logging.Debug))
    global_logger(demux_logger)

    @show topdir outdir outputlog
    #map(println, tests)

    df = DataFrame()
    @show start_time = now()
    cd(topdir) do
        @time for (i,test) in enumerate(tests)
            print(i, " of ", length(tests), ": ")
            per_file!(df, joinpath(outdir, string(test, ".txt")), test)
            GC.gc()
        end
    end
    # Exception Summary Report
    xfile = open(joinpath(outdir, "exceptions.txt"), "w")
    cd(outdir) do
        for (root, dirs, files) in walkdir(".")
            flist = map(f -> joinpath(root, f), files)
            for f in filter(f -> success(run(Cmd(`grep -q "^CAUGHT EXCEPTION" $f`, ignorestatus=true))), flist)
                x = read(`grep -nHP -A3 '^CAUGHT' $f`, String)
                write(xfile, x, "\n")
            end
        end
    end # cd
    close(xfile)

    sort!(df, [:time])
    dt = joinpath(outdir, "DataFrame.txt")
    Base.redirect_stdio(; stdout=dt, stderr=dt) do
        show(df; truncate=80)
        println()
    end
    println()
    show(df; truncate=80)
    println()
    CSV.write(joinpath(outdir, "DataFrame.csv"), df)
    println("finish_time = ", now(), ", elapsed time = ", (now() - start_time))
end

#-------------------------------------------------------------------------------------------
# `filename` is relative to the cwd. `outdir` is absolute or relative
function per_file!(df, outfile::AbstractString, testf::AbstractString; exersize_net=exersize_netA)
    #@show outfile testf pwd()

    isfile(outfile) && error("overwriting $outfile")
    mkpath(dirname(outfile)) # Create output directory.
    yield()
    file_start = now()
    println("$testf at $(Time(file_start)) size = $(filesize(testf))") # Display path to file and size.

    Base.redirect_stdio(stdout=outfile, stderr=outfile) do
        try
            #PNML.reset_reg!(PNML.idregistry[])
            # parse_file() will do empty!(PNML.IDRegistryVec)
            println(stat(testf), " at ", Time(file_start))
            println()

            stats = @timed parse_file(testf) #^ PARSE PNML MODEL

            #todo Add fields of testf path components to allow sorting the table.
            push!(df, (file=testf, fsize=filesize(testf),
                       time=stats.time, bytes=stats.bytes, gctime=stats.gctime))

            # Display PnmlModel as a test of parsing, creation and show().
            !isnothing(exersize_net) && exersize_net(stats.value) #^ EXERSIZE PNML MODEL
            println("took ", stats.time, " memory: ", stats.bytes, " bytes")

        catch e
            bt = Base.catch_backtrace()

            println("\n\nCAUGHT EXCEPTION:", sprint(showerror, e, bt)) # full backtrace to file
            @info "CAUGHT EXCEPTION: $(sprint(showerror,e))"
            #! Ignore first ^C, it serves to end processing of a single file.
            #! The "second" (is there a window of opurtunity?) should end the loop processing files.
            # e isa InterruptException && rethrow()
            # end
        end # try
    end   # redirect
    # print exceptions
    run(Cmd(`grep "^CAUGHT EXCEPTION" $outfile`, ignorestatus=true))
end

function exersize_netA(model)
    println(model)
    # Petri Net & Graph
    @showtime anet = PNML.SimpleNet(model)
    if !(PNML.narcs(anet) > 0 && PNML.nplaces(anet) > 0 && PNML.ntransitions(anet) > 0)
        println("incomplete graph $(PNML.pid(anet)) not compatible with `exersize_netA`")
        return
    end
    @showtime mg = PNML.metagraph(anet)
    @show mg
    @show Graphs.is_bipartite(mg)
    @show ne = Graphs.ne(mg)
    @show nv = Graphs.nv(mg)
    @show labels =  collect(MetaGraphsNext.labels(mg))
    @show elabels = collect(MetaGraphsNext.edge_labels(mg))
    println("-----")
    #C = PNML.incidence_matrix(anet)
    #@showtime C  = PNML.incidence_matrix(anet)
    @show m₀ = PNML.initial_markings(anet)
    #@showtime e  = PNML.enabled(anet, m₀)
    println("-----")
end
