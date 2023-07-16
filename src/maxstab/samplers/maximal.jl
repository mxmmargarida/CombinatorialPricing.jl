struct MaximalStableSetSampler <: AbstractSampler
    prob::MaxStableSetPricing
end

function Base.rand(sampler::MaximalStableSetSampler)
    return BitSet(independent_set(graph(sampler.prob), MaximalIndependentSet()))
end
