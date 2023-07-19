struct BilevelFeasibleSampler{S<:SolutionSampler} <: SolutionSampler
    inner::S
    fmodel::Model
end

problem(sampler::BilevelFeasibleSampler) = problem(sampler.inner)

function BilevelFeasibleSampler(inner::SolutionSampler)
    fmodel = follower_model(problem(inner); silent=true, threads=1)
    return BilevelFeasibleSampler(inner, fmodel)
end

function Base.rand(rng::AbstractRNG, sampler::Random.SamplerTrivial{<:BilevelFeasibleSampler})
    @unpack inner, fmodel = sampler[]
    x = fmodel[:x]
    x_set = rand(rng, inner)
    
    # Fix the values of tolled items, solve for the optimal toll-free combination
    for a in tolled(problem(inner))
        fix(x[a], a ∈ x_set, force=true)
    end
    optimize!(fmodel)

    return convert_x_to_set(value.(x))
end
