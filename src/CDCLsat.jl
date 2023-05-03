module CDCLsat

export Model, Variable, Clause, @variable, @clause, solve!

using DataStructures: Queue, enqueue!, dequeue!
using Formatting: format
using RomanNumerals: RomanNumeral
using Term: Panel
using Term.Tables: Table

include("nullable.jl")
include("model.jl")
include("language.jl")
include("output.jl")
include("propagate.jl")
include("decide.jl")
include("learn.jl")

"""
Check satisfiability (SAT) of a propositional logic formula in Conjunctive Normal Form (CNF) using the Davis-Putnam-Logemann-Loveland (DPLL) algorithm with Boolean Constraint Propagation (BCP), Conflict-Driven Clause Learning (CDCL), and the Variable State Independent Decaying Sum (VSIDS) decision heuristics.

Return `true` if the formula is satisfiable and `false` otherwise.
"""
function solve!(model::Model)::Bool
    @report output_model(model)
    local start::Float64 = time()
    # Check for empty clauses and propagate single-literal clauses.
    if !propagate!(model)
        # There is an unresolvable conflict, so the formula is unsatisfiable.
        @report output_unsat(time() - start)
        return false
    end
    while true
        # Decide an unassigned variable.
        if !decide!(model)
            # All variables are assigned without conflicts, so the formula is satisfiable.
            @report output_sat(model, time() - start)
            return true
        end
        # Propagate the decision and, in case of conflicts, any learned assignments.
        while !propagate!(model)
            # The propagation leads to a conflict, so backtrack and learn the asserting clause.
            if !learn!(model)
                # There is an unresolvable conflict, so the formula is unsatisfiable.
                @report output_unsat(time() - start)
                return false
            end
        end
    end
end

end
