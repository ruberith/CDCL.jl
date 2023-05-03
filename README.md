# CDCLsat

CDCL SAT Solver

## Description

Check satisfiability (SAT) of a propositional logic formula in Conjunctive Normal Form (CNF) using the Davis-Putnam-Logemann-Loveland (DPLL) algorithm with Boolean Constraint Propagation (BCP), Conflict-Driven Clause Learning (CDCL), and the Variable State Independent Decaying Sum (VSIDS) decision heuristics.

## Installation

1. Download and install the [Julia](https://julialang.org) language.
2. Start the Julia REPL.
3. Type the following to enter the Pkg REPL and install the package:

```
julia> ]
pkg> add CDCLsat
```

## Usage

Create a model using the constructor `Model()`.

The following model parameters / fields may be set:
- `decision::Bool` – assignment used when making a heuristics-based decision for a variable
- `vsids_increment::Int` – increment of the VSIDS conflict counter for variables involved in a conflict
- `vsids_increase::Int` – increase of the VSIDS increment after each conflict
- `vsids_period::Int` – number of conflicts per VSIDS period
- `vsids_decay::Float64` – multiplier for both VSIDS increment and conflict counters at the end of a period
- `output::BoolOrNothing` – output events and assignments (`true`), only model and solution (`false`), or `nothing`

Add variables using the macro `@variable <model> <name> (<priority>|ε)`.

Add clauses using the macro `@clause <model> <name> [ (¬|!|ε)<variable> ... ]`.

Solve the model with the function `solve!(model::Model)`.

If the formula is satisfiable, a satisfying assignment can be obtained from the model field `variables` by accessing the field `assignment` of each `Variable`.

Note that a model should not be reused.

## Example

```julia
using CDCLsat

model = Model()

@variable model x
@variable model y

@clause model c1 [x y]
@clause model c2 [!x !y]
@clause model c3 [!x y]
@clause model c4 [x !y]

solve!(model)
```

## Dependencies

- [DataStructures.jl](https://github.com/JuliaCollections/DataStructures.jl)
- [Formatting.jl](https://github.com/JuliaIO/Formatting.jl)
- [RomanNumerals.jl](https://github.com/anthonyclays/RomanNumerals.jl)
- [Term.jl](https://github.com/FedeClaudi/Term.jl)

## References

- Erika Ábrahám: [RWTH Satisfiability Checking Lecture](https://ths.rwth-aachen.de/teaching/arc-teaching-materials-rwth-aachen-university/)
- João P. Marques-Silva, Karem A. Sakallah: [GRASP – A New Search Algorithm for Satisfiability](https://doi.org/10.1109/ICCAD.1996.569607), [GRASP: A Search Algorithm for Propositional Satisfiability](https://doi.org/10.1109/12.769433)
- Matthew W. Moskewicz, Conor F. Madigan, Ying Zhao, Lintao Zhang, Sharad Malik: [Chaff: Engineering an Efficient SAT Solver](https://doi.org/10.1145/378239.379017)
