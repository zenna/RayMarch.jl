using GeometyBasics
using Distributions
using LinearAlgebra: dot, cross

relu(x) = max(x, 0.0)
len(x) = sqrt(sum(x.^ 2))
normalize(x) = x ./ len(x)
direction_and_length(x) = (l = len(x); (x ./ l, x))
rand_uniform(a, b, rng) = rand(rng, Uniform(a, b))
sample_average(n, rng) = ..
positive_projection(x, y) = dot(x, y) > 0.0

xHat  = [1., 0., 0.]
yHat  = [0., 1., 0.]
zHat  = [0., 0., 1.]

Angle = Float64

function rotate_X(p, angle::Vec3)
  c = cos(angle)
  s = sin(angle)
  px, py, pz = p
  Vec3(px, c*py - s*pz, s*py + c*pz)
end

function rotate_Y(p, angle::Vec3)
  c = cos(angle)
  s = sin(angle)
  px, py, pz = p
  Vec3(c*px + s*pz, py, - s*px+ c*pz)
end

function rotate_Z(p, angle::Vec3)
  c = cos(angle)
  s = sin(angle)
  px, py, pz = p
  Vec3(c*px - s*py, s*px+c*py, pz)
end

function sample_cosine_weighted_hemisphere(normal::Vec3, k::Key)
  k1, k2 = splitKey k
  u1 = rand(k1)
  u2 = rand(k2)
  uu = normalize $ cross normal [0.0, 1.1, 1.1]
  vv = cross(uu, normal)
  ra = sqrt(u2)
  rx = ra * cos(2.0 * pi * u1)
  ry = ra * sin(2.0 * pi * u1)
  rz = sqrt(1.0 - u2)
  rr = (rx .* uu) + (ry .* vv) + (rz .* normal)
  normalize(rr)
end