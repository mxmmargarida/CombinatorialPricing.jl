struct MinimalSetCoverSampler <: SolutionSampler
    prob::MinSetCoverPricing
end

problem(sampler::MinimalSetCoverSampler) = sampler.prob

function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{MinimalSetCoverSampler})
    prob = sampler[].prob
    n, m, sets = num_items(prob), prob.num_elements, prob.sets
    cover = BitSet(1:n)
    for i in shuffle(rng, 1:n)
        new_cover = collect(setdiff(cover, i))
        if union_sets(@view sets[new_cover]) == BitSet(1:m)
            pop!(cover, i)
        end
    end
    return cover
end
