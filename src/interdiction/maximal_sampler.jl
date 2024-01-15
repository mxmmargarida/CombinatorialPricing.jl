struct MaximalKnapsackInterdictionSampler <: SolutionSampler
    prob::KnapsackInterdiction
end

problem(sampler::MaximalKnapsackInterdictionSampler) = sampler.prob

function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{MaximalKnapsackInterdictionSampler})
    prob = sampler[].prob
    w, C, n = lower_weights(prob), lower_cap(prob), num_items(prob)
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
