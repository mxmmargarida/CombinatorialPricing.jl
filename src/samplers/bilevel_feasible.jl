struct BilevelFeasibleSampler{S<:AbstractSampler} <: AbstractSampler
    inner::S
    fmodel::Model
end

problem(sampler::BilevelFeasibleSampler) = problem(sampler.inner)

function BilevelFeasibleSampler(inner::AbstractSampler)
    fmodel = follower_model(problem(inner); silent=true, threads=1)
    return BilevelFeasibleSampler(inner, fmodel)
end

function Base.rand(sampler::BilevelFeasibleSampler)
    inner, fmodel = sampler.inner, sampler.fmodel
    x = fmodel[:x]
    x_set = rand(inner)
    
    # Fix the values of tolled items, solve for the optimal toll-free combination
    for a in tolled(problem(inner))
        fix(x[a], a ∈ x_set, force=true)
    end
    optimize!(fmodel)

    return convert_x_to_set(value.(x))
end
