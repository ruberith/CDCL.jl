"""
Name-variable pair type.
"""
const NamedVariable = Pair{String,Variable}
"""
Nullable name-variable pair type.
"""
const NamedVariableOrNothing = Union{NamedVariable,Nothing}

"""
Construct the literal string for a variable.

Return the constructed `String`.
"""
function construct_literal(variable::NamedVariable)::String
    return (variable.second.assignment ? "" : "¬") * variable.first
end

"""
Construct the decision level string for a variable.

Return the constructed `String`.
"""
function construct_decision_level(variable::NamedVariable)::String
    return "$(variable.second.decision_level)"
end

"""
Output the specified event.
"""
function output_event(clause::String, relation::String, literal::String, decision_level::String, name::String, color::String)::Nothing
    print(Panel(
        "$clause $relation $literal",
        justify=:center,
        subtitle="@ $decision_level",
        subtitle_justify=:right,
        title=name,
        title_style=color,
        style=color
    ))
    return nothing
end

"""
Output the specified conflict.
"""
function output_conflict(clause::String, variable::NamedVariableOrNothing)::Nothing
    output_event(
        clause, "↯",
        isnothing(variable) ? "□" : construct_literal(variable),
        isnothing(variable) ? "0" : construct_decision_level(variable),
        "CONFLICT", "yellow"
    )
    return nothing
end

"""
Output the specified propagation.
"""
function output_propagate(clause::String, variable::NamedVariable)::Nothing
    output_event(clause, "→", construct_literal(variable), construct_decision_level(variable), "PROPAGATE", "blue")
    return nothing
end

"""
Output the specified decision.
"""
function output_decide(variable::NamedVariable)::Nothing
    output_event("♢", "→", construct_literal(variable), construct_decision_level(variable), "DECIDE", "magenta")
    return nothing
end

"""
Output the specified learning.
"""
function output_learn(clause::String, variable::NamedVariable)::Nothing
    output_event(clause, "→", construct_literal(variable), construct_decision_level(variable), "LEARN", "cyan")
    return nothing
end

"""
Usage:

    @event <output call>

Define an event guard for an output call, i.e. the output is only shown if the model parameter `output` is set to `true`.

Note that the `model::Model` has to be initialized and accessible.
"""
macro event(output_call)
    return esc(quote
        if !isnothing(model.output) && model.output
            $output_call
        end
    end)
end

"""
Usage:

    @report <output call>

Define a report guard for an output call, i.e. the output is only shown if the model parameter `output` is not set to `nothing`.

Note that the `model::Model` has to be initialized and accessible.
"""
macro report(output_call)
    return esc(quote
        if !isnothing(model.output)
            $output_call
        end
    end)
end

"""
Output the configuration of the given model.
"""
function output_model(model::Model)::Nothing
    println()
    print(Panel(
        Table(
            [
                "|Variables|" "$(length(model.variables))"
                "|Clauses|" "$(length(model.clauses))"
                "Decision" "$(model.decision)"
                "{underline}VSIDS{/underline}" ""
                " ↪ {italic}Increment{/italic}" "$(model.vsids_increment)"
                " ↪ {italic}Increase{/italic}" "$(model.vsids_increase)"
                " ↪ {italic}Period{/italic}" "$(model.vsids_period)"
                " ↪ {italic}Decay{/italic}" "$(model.vsids_decay)"
                "Output" "$(model.output)"
            ],
            header=["Model Parameter", "Value"],
            columns_justify=[:left, :right],
            box=:ROUNDED
        ),
        justify=:center,
        title="{yellow}C{/yellow}" *
              "{magenta}D{/magenta}" *
              "{blue}C{/blue}" *
              "{cyan}L{/cyan}" *
              "sat",
        title_style="bold",
        subtitle="v0.1.0",
        subtitle_style="bold",
        subtitle_justify=:right,
        box=:DOUBLE
    ))
    return nothing
end

"""
Output the negative solution (UNSAT).
"""
function output_unsat(duration::Float64)::Nothing
    print(Panel(
        "{bold}An unresolvable conflict has been found.{/bold}",
        justify=:center,
        title="UNSATISFIABLE",
        title_style="bold red",
        subtitle="{bold}" * format("{:.3f} s", duration) * "{/bold}",
        subtitle_justify=:right,
        box=:DOUBLE,
        style="red"
    ))
    println()
    return nothing
end

"""
Output the positive solution (SAT).
"""
function output_sat(model::Model, duration::Float64)::Nothing
    print(Panel(
        model.output ? Table(
            construct_literal.(sort(collect(model.variables), by=x -> x[1])),
            header=["Satisfying Assignment"],
            columns_justify=[:right],
            box=:ROUNDED
        ) : "{bold}A satisfying assignment has been found.{/bold}",
        justify=:center,
        title="SATISFIABLE",
        title_style="bold green",
        subtitle="{bold}" * format("{:.3f} s", duration) * "{/bold}",
        subtitle_justify=:right,
        box=:DOUBLE,
        style="green"
    ))
    println()
    return nothing
end
