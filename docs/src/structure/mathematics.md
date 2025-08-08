# Mathematical Semantics

__ISO 15909 High-level Petri nets Standard__  parts 1 and 3 describe the sematics using math notation and part 2 provides the syntax using XML, UML2 and RelaxNG Schema.

Here we pick out bits for exposition.  Recommend using the standard for completeness.

## Color Functions

> In symmetric nets, arcs are labelled by color functions which select tokens in adjacent places depending on the instantiation performed for the firing.


### Basic Color Functions

In Part 1 refer to *Concept 15 (symmetric finite cartesian net)*
and *Concept 16 (basic color functions)*

Let ``C`` be a non-empty finite set.
 A non-empty finite color class ``C_i`` defines a type over ``C``. Part 2 calls this a Sort.

 A color domain is a finite cartesian product of color classes: ``D = \prod_{i=1}^{n} {C}_i``.
 Part 2 calls this a ProductSort.

Let ``C_i`` be a color class and ``D = C_1^{e_1} \times ... \times C_k^{e_k}`` a color domain.

General color function: C(transition) -> Bag(C(place)), where ``C`` is a mapping (not a finite set as before).

Color functions from ``D`` to  ``Bag(C_i)``
for multiset ``c = \langle c_1^1, ... , c_1^{e_1}, ..., c_k^1, ..., c_k^{e_k} \rangle ``:

  - projections that select one component of a color

  ``X_{C_i}^{j}(c) = c_i^j,\, \forall j \,|\, 1 \leq j \leq e_j``

  - successor functions that select the successor of a component of a color

  ``X_{C_i}^{j}(c){++}`` the successor of ``c_i^j \in C_i,\, \forall j \,|\, 1 \leq j \leq e_j``

  -  "global" selections that map any color to the "sum" of colors
  ``C_i.{all}(c) = \sum_{c \in C_i}{x}`` and ``C_{i,q}.{all}(c) = \sum_{c \in C_i}{x}``

``\sum{x}`` in Part 1 is *A.5.3.3 Notation 5 (bag notation, equivalence with the supporting set)*.

``C_{i,q}`` seems to refer to what Part 2 calls a Partition.
Where ``C_i = \uplus_{q=1..s_i} C_{i,q}`` is a color class that is partitioned into ``s_i`` static subclasses.

*Concept 17 (class color functions)*

```math
f_{C_i} = \sum_{k=1..e_i} {\alpha_{i,k} \cdot \langle X_{C_i}^k \rangle} +
\sum_{q=1..s_i} {\beta_{i,q} \cdot \langle C_{i,q}.all \rangle} +
\sum_{k=1..e_i} {\gamma_{i,k} \cdot \langle X_i^k{++} \rangle}
```
such that ``\forall d \in D,\, \forall c \in C_i,\, f_{C_i}(d)(c) \geq 0``,
where constrants on ``\alpha_{i,k},\, \beta_{i,q}.\, \gamma_{i,k}`` are defined to ensure
``f_{C_i}(d)(d) > 0 ,\, \forall c \in C_i``
