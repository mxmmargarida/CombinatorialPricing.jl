mutable struct SolutionProvider
    solution::Union{Vector{Float64},Nothing}
    objective::Float64
end

function add_heuristic_provider!(model::Model)
    x, t, tx = model[:x], model[:t], model[:tx]
    vars = vcat(x, t.data, tx.data)

    provider = SolutionProvider(nothing, -Inf)
    model[:heur_provider] = provider

    function heuristic_callback(cb_data)
        if !isnothing(provider.solution)
            MOI.submit(model, MOI.HeuristicSolution(cb_data), vars, provider.solution)
            provider.solution = nothing
        end
    end
    MOI.set(model, MOI.HeuristicCallback(), heuristic_callback)

    return provider
end

function Base.push!(provider::SolutionProvider, x, t)
    i1 = axes(t)[1]
    tx = t.data .* x[i1]
    if sum(tx) > provider.objective
        provider.solution = vcat(x, t.data, tx)
        provider.objective = sum(tx)
    end
end
