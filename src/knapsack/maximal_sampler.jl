struct MaximalKnapsackSampler <: SolutionSampler
    prob::KnapsackPricing
end

problem(sampler::MaximalKnapsackSampler) = sampler.prob

function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{MaximalKnapsackSampler})
    prob = sampler[].prob
    w, C, n = prob.weights, prob.capacity, num_items(prob)
    items = shuffle(rng, 1:n)
    cumweights = cumsum(@view w[items])
    h = findlast(<=(C), cumweights)
    return BitSet(@view items[1:h])
end
