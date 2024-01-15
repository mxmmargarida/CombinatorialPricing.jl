struct MaximalKnapsackSampler <: SolutionSampler
    prob::KnapsackPricing
end

problem(sampler::MaximalKnapsackSampler) = sampler.prob

function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{MaximalKnapsackSampler})
    prob = sampler[].prob
    w, C, n = prob.weights, prob.capacity, num_items(prob)
    items = shuffle(rng, 1:n)

    selected = BitSet()
    for i in items
        if w[i] <= C
            push!(selected, i)
            C -= w[i]
        end
    end
    return selected
end
