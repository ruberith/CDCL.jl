"""
Decide an unassigned variable using the Variable State Independent Decaying Sum (VSIDS) heuristics.

Return `true` if a decision has been made and `false` if all variables are already assigned.
"""
function decide!(model::Model)::Bool
    # Select the unassigned variable with maximum priority.
    local selected::StringOrNothing = nothing
    for (name, var) in model.variables
        if isnothing(var.assignment)
            if isnothing(selected)
                selected = name
            else
                # The primary priority is the dynamic conflict counter.
                if var.conflicts > model.variables[selected].conflicts
                    selected = name
                else
                    # The secondary priority is the static priority value.
                    if var.conflicts == model.variables[selected].conflicts && var.priority > model.variables[selected].priority
                        selected = name
                    end
                end
            end
        end
    end
    if isnothing(selected)
        # All variables are already assigned.
        return false
    end
    # Assign the designated decision value to the variable and add it to the trail.
    local var::Variable = model.variables[selected]
    var.assignment = model.decision
    var.decision_level = isnothing(model.trail) ? 1 : (model.variables[model.trail].decision_level + 1)
    var.predecessor = model.trail
    model.trail = selected
    @event output_decide(selected => var)
    return true
end
