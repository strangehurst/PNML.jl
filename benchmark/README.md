# PNMLToolkit.jl benchmarks

This directory contains benchmarks for different parts of PNMLToolkit. To run all the
benchmarks, launch `julia --project=benchmark` and enter:

``` julia
using PkgBenchmark
import PNML

benchmarkpkg(PNML)
```

To run a specific set of benchmarks, use the `script` keyword argument, for example:

``` julia
benchmarkpkg(PNML; script="benchmark/PNML.jl")
```


### Test statistics
Fri 10 Feb 2023 09:07:19 PM CST
ALL TESTS: 56.789463 seconds (134.48 M allocations: 6.960 GiB, 5.18% gc time, 84.75% compilation time: 3% of which was recompilation)

change `_anyelement_content` from foreach to for

