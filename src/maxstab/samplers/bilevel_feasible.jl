struct BilevelFeasibleStableSetSampler <: AbstractSampler
    prob::MaxStableSetPricing
    fmodel::Model
end

function BilevelFeasibleStableSetSampler(prob::MaxStableSetPricing)
    fmodel = follower_model(prob; silent=true, threads=1)
    return BilevelFeasibleStableSetSampler(prob, fmodel)
end

function Base.rand(sampler::BilevelFeasibleStableSetSampler)
    prob, fmodel = sampler.prob, sampler.fmodel
    x = fmodel[:x]

    # Generate a random maximal stable set
    max_set = BitSet(independent_set(graph(prob), MaximalIndependentSet()))
    
    # Fix the values of tolled nodes, solve for the maximum toll-free stable set
    for a in tolled(prob)
        fix(x[a], a ∈ max_set, force=true)
    end
    optimize!(fmodel)

    return convert_x_to_set(value.(x))
end
