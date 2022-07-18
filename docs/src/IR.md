```@meta
CurrentModule = PNML
```


# Intermediate Representation

The intermediate representation (IR) is between the XML model and
a "usable" network. Many different flavors of Petri Nets are expected 
to be implemented using the IR.

The IR is constructed by traversing the XML and using tag names as dictonary keys.

In the first part of parsing, a [`PnmlDict`](@ref) is filled with appropriate 
initial values for each xml tag. Then optional child keys have values bound 
as they are parsed. 

The second part of parsing instantiates objects using a `PnmlDict` as input.

The structure of the IR follows the tree structure of a well-formed XML document
and the PNML specification.

XML attribute names and child element tag names are used for keys 
of the same dictonary. The _pnml_ specification/schemas do not use colliding names.
However, the <toolspecific> tag's content is not required to be valid pnml, just
well-formed XML. We assume nobody would use colliding names intentionally.



The crude structure required by the pnmlcore schema:
PnmlModel
  - Net
    - Page
    	- Places, Marking
    	- Transitions, Condition
    	- Arcs, Inscription
    	- Toolinfos 
    	- Labels
    	- Subpages
    - Name
	- Toolinfos
	- Labels
	
The IR is implemented under the assumption the the input pnml file is valid.
All tags are assumed to be meaningful to the resulting network.
The pnmlcore schema requires undefined tags will be considered pnml labels.
The IR is capable of handling arbitrary labels.
Many label tags from higherlevel pnml schemas are recognized by the IR parsers.

While the Petri Net Type Definition (pntd) is present in every valid net,
it was not necessary to consult the type during creation of the IR. 
It is expected that conforming to pntd will be done at a higher level.

Some parts of pnml are complicated. Not yet completed bits may be implemented
as wrappers holdind unparsed XML. In fact, parts of pnml are specified as holding
any well-formed XML.

# History of this IR

Started as nested Dict{Symbol,Any} see [`PnmlDict`](@ref). 

2021-12-15, Began the process of moving to a struct-based scheme 
based on [`PnmlModel`](@ref) and the rest of the intermediate representation.

Some instances of `PnmlDict` are still present in the parsing mechanism.

As experience with building & using more complicated pnml network models,
more of the IR will be implemented or changed.
