abstract type AbstractSampler end

"""
    problem(sampler::AbstractSampler) -> PricingProblem

Return the problem corresponding to the `sampler`.
"""
function problem end

function Base.rand(sampler::AbstractSampler, count::Int)
    return [rand(sampler) for _ in 1:count]
end
