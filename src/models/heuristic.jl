mutable struct SolutionProvider
    prob::AbstractProblem
    solution::Union{Vector{Float64},Nothing}
    objective::Float64
end

function add_heuristic_provider!(model::Model)
    x, t = model[:x], model[:t]
    vars = vcat(x, _data(t))

    provider = SolutionProvider(model[:prob], nothing, -Inf)
    model[:heur_provider] = provider

    function heuristic_callback(cb_data)
        if !isnothing(provider.solution)
            # println("Submitted $(provider.objective)")
            MOI.submit(model, MOI.HeuristicSolution(cb_data), vars, provider.solution)
            provider.solution = nothing
        end
    end
    MOI.set(model, MOI.HeuristicCallback(), heuristic_callback)

    return provider
end

function Base.push!(provider::SolutionProvider, x, t)
    obj = _leader_objective(provider.prob, x, t)
    if obj > provider.objective
        provider.solution = vcat(x, _data(t))
        provider.objective = _leader_objective(provider.prob, x, t)
    end
end

# Utilities
_data(arr::Array) = arr
_data(arr::DenseAxisArray) = arr.data

function _leader_objective(::PricingProblem, x, t) 
    i1 = axes(t)[1]
    tx = _data(t) .* x[i1]
    return sum(tx)
end
