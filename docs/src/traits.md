```@meta
CurrentModule = PNML
```
# Traits

Some of the traits used are based on the pntd.
Each supported pntd has a singleton subtype of PnmlType.

3 branches of pntd based on number system
  - _core_ uses integers
  - _high-level_ uses terms of many-sorted algebra
  - _continuous/hybrid_ uses floating point

Default place markings and arc inscriptions are different for the three.


```@setup types
using  PNML, InteractiveUtils, Markdown
list_type(f) = for pntd in values(PNML.PnmlTypeDefs.pnmltype_map)
    println(rpad(pntd, 15), " -> ", f(pntd))
end
```
# isdiscrete
```@example types
list_type(PNML.isdiscrete)
```

# iscontinuous
```@example types
list_type(PNML.iscontinuous)
```

# ishighlevel
```@example types
list_type(PNML.ishighlevel)
```
