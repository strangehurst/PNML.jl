# Petri Net Markup Language

PNML is intended to be an interchange format.

## www.pnml.org

<http://www.pnml.org> has publications and tutorials covering PNML at 
various points in its evolution. Is the cannonical site for the 
RELAX-NG XML schemas that define the grammer of several Petri Net Type Defintions (pntd), 
including:
  - PT Net
  - High-level Place/Transition Net
  - Symmetric Net

There are links to a series of ISO/IEC 15909 standards relating to PNML. They cost money.

Note that the people behind PNML appear to be of the "model driven development" camp 
and have chosen Java, Eclipse and its EMF. 

The high-level marking, inscription, condition and declaration are where the hard work waits.


## Interoperability

Pntd is for interchange of pnml models between different tools.
ISO is working on part 3 of the PNML standard covering pntd (as of October 2021).

Petri Net Type Definitions (pntd) are defined using RELAX-NG XML Schema files.
It is possibly to create a non-standard pntd. And more will be standardized, either
formally or informally. Non-standard just means that the interchangibility is restricted.


Since validation is not a goal of PNML.jl, non-standard pntds can be used for the 
URI of an XML `net` tag's `type` attribute. Notably `pnmlcore` and `nonstandard` 
are mapped to PnmlCore. 

PnmlCore is the minimum level of meaning that any pnml file can hold. 
PNML.jl should be able to create a valid intermediate representation since
all the higher-level meaning is expressed as pnml label XML objects.

See [`PNML.PnmlType `](@ref), [`PNML.default_pntd_map`](@ref), [`PNML.pnmltype_map`](@ref)
