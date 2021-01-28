module RayMarch
using StaticArrays
const Vec3 = SVector{3, Float64}

include("util.jl")
include("march.jl")
export Vec3

end # module