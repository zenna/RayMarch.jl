using GeometyBasics

const Distance = Float64

const Position  = Vec3
const Direction = Vec3  ## Should be normalized. TODO: use a newtype wrapper

const BlockHalfWidths = Vec3
const Radius = Float64
const Radiance = Color # Hmm..

abstract type ObjectGeom end

struct Wall <: ObjectGeom
  direction::Direction
  distance::Distance
end

struct Block <: ObjectGeom
  position::Position
  blockhalfwidths::BlockHalfWidths
  angle::Angle
end

struct Sphere <: ObjectGeom
  position::Position
  radius::Radius
end

abstract type Surface end

struct Matte <: Surfacce
  color::Color
end

struct Mirror <: Surface end

const OrientedSurface = Tuple{Direction, Surface}

abstract type Object end

struct PassiveObject{O <: ObjectGeom, S <: Surface} <: Object
  object_geom::O
  surface::S
end

struct Light <: Object
  position::Position
  something::Float64
  radiance::Radiance
end

const Ray = Tuple{Position, Direction}
const Filter = Color

struct Params
  num_samples::Int
  max_bounces::Int
  shared_seed::Bool
end

const Scene = Vector{Object}