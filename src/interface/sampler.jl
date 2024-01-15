abstract type SolutionSampler end

"""
    problem(sampler::SolutionSampler) -> AbstractProblem

Return the problem corresponding to the `sampler`.
"""
function problem end
