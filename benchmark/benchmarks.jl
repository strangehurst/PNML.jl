using BenchmarkTools

function foo()
end

@btime foo()

const SUITE = BenchmarkGroup()

module BenchmarkPNML
  include("PNML.jl")
end

module BenchmarkGraphs
  include("Graph.jl")
end

SUITE["PNML"] = BenchmarkPNML.SUITE
SUITE["Graphs"] = BenchmarkGraphs.SUITE
