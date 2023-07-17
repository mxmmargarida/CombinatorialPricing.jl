struct MaximalStableSetSampler <: AbstractSampler
    prob::MaxStableSetPricing
end

problem(sampler::MaximalStableSetSampler) = sampler.prob

function Base.rand(sampler::MaximalStableSetSampler)
    return BitSet(independent_set(graph(sampler.prob), MaximalIndependentSet()))
end
