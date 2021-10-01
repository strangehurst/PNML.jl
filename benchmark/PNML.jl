using BenchmarkTools
const SUITE = BenchmarkGroup() 

using PNML

bench = SUITE["label"] = BenchmarkGroup()

# FROM CATLAB
function benchmark_pullback(suite::BenchmarkGroup, name, arg)
  for alg in (NestedLoopJoin(), SortMergeJoin(), HashJoin())
    suite["$name:$(nameof(typeof(alg)))"] =
      @benchmarkable limit($arg, alg=$alg)
  end
end

sizes = (100, 150)
f, g = (FinFunction(ones(Int, size), 1) for size in sizes)
benchmark_pullback(bench, "pullback_terminal", Cospan(f, g))
