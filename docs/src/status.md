High-level nets are not completely implemented. This statement will remain true
as incremental progress is slowly made. It is safe to state this will be one of
the last feature to near completion.

(as of November 2022).
Supporting continuous/hybrid high-level nets may not be possible. We currently do not try.
Note this is a extension to what the specifiction covers: natural numbers.

## Roadmap

https://www.pnml.org/tools.php lists two expected features of a "PNML supporting tool":
- create PNML files conforming to a PNTD meta-model
- load PNML files and use PNTD meta-models to "make" a Petri Net
with the presumption that one does something useful.

Have not considered any part of creating or writing out a Petri Net model.
This package, PNML.jl, aims to provide infrastructure to interact with other Julia packages,
including graphs, category theory, SciML, agents.
All focus has been on the "load" part of the expected behavior.
The meta-models are encoded in the structure of PNML.jl, notably in the type system.
Doing "something useful" is mostly aspriational until adequate function is present.

The first useful things will be trivial and obvious:
- display the PNML Model
- analyze the PNML Model
- construct a Petri.jl Model to solve an ODE.  # maybe not trivial or obvious :)

Next will be to interface with graph-theoretical packages.
Enhancing the display and analysis features.

Editing petri net models is not planned, so writing the model is trivial

Checkpointing and writing in some "non-PNML" format is another anticipated feature.

Features mentioned in
[ISO/IEC 15909-3:2021 Part 3: Extensions and Structuring Mechanisms](https://www.iso.org/standard/81504.html)

- special arcs: inhibitor, read, reset
- capacity place: maximum multiset of tokens a place can hold
- FIFO queue place (queues in general)
- sort generator: sorts and operators from signatures
