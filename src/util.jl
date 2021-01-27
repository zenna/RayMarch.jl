using GeometryBasics
using Distributions
using LinearAlgebra: dot, cross
using Random

relu(x::Float64) = max(x, 0.0)
len(x::Array{Float64}) = sqrt(sum(x.^ 2))
normalize(x::Array{Float64}) = x ./ len(x)
direction_and_length(x::Array{Float64}) = (l = length(x); (x ./ l, l))
rand_uniform(a::Float64, b::Float64, rng::AbstractRNG) = rand(rng, Uniform(a, b))
sample_average(sample::Function, n::Int, rng::AbstractRNG) = sum([sample(rng) for i in 1:n])/n
positive_projection(x::Array{Float64}, y::Array{Float64}) = dot(x, y) > 0.0

const xHat  = [1., 0., 0.]
const yHat  = [0., 1., 0.]
const zHat  = [0., 0., 1.]

const Angle = Float64

function rotate_X(p::Array{Float64}, angle::Angle)::Array{Float64}
  c = cos(angle)
  s = sin(angle)
  px, py, pz = p
  [px, c*py - s*pz, s*py + c*pz]
end

function rotate_Y(p::Array{Float64}, angle::Angle)::Array{Float64}
  c = cos(angle)
  s = sin(angle)
  px, py, pz = p
  [c*px + s*pz, py, - s*px+ c*pz]
end

function rotate_Z(p::Array{Float64}, angle::Angle)::Array{Float64}
  c = cos(angle)
  s = sin(angle)
  px, py, pz = p
  [c*px - s*py, s*px+c*py, pz]
end

function sample_cosine_weighted_hemisphere(normal::Array{Float64}, rng::AbstractRNG)::Array{Float64}
  u1 = rand(rng)
  u2 = rand(rng)
  uu = normalize(cross(normal, [0.0, 1.1, 1.1]))
  vv = cross(uu, normal)
  ra = sqrt(u2)
  rx = ra * cos(2.0 * pi * u1)
  ry = ra * sin(2.0 * pi * u1)
  rz = sqrt(1.0 - u2)
  rr = (rx .* uu) + (ry .* vv) + (rz .* normal)
  normalize(rr)
end