struct MaximalStableSetSampler <: SolutionSampler
    prob::MaxStableSetPricing
end

problem(sampler::MaximalStableSetSampler) = sampler.prob

function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{MaximalStableSetSampler})
    return BitSet(independent_set(graph(sampler[].prob), MaximalIndependentSet(); rng))
end
