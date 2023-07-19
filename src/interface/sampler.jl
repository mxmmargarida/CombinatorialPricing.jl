abstract type SolutionSampler end

"""
    problem(sampler::SolutionSampler) -> PricingProblem

Return the problem corresponding to the `sampler`.
"""
function problem end
