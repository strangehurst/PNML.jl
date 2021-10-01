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
