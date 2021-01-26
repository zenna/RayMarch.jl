using GeometyBasics

const Distance = Float64

const Position = Vec3
const Direction = Vec3  ## Should be normalized. TODO: use a newtype wrapper

const Color = Vec3
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

struct Matte <: Surface
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

function sampleReflection(oriented_surface::OrientedSurface, ray::Ray, rng::AbstractRNG)::Ray 
  nor, surf = oriented_surface
  pos, dir = ray
  if surf isa Matte
    new_dir = sample_cosine_weighted_hemisphere(nor, rng)
  else
    new_dir = dir - (2.0 * dot(dir, nor)) * nor
  end
  (pos, new_dir)
end

function probReflection(oriented_surface::OrientedSurface, ray1::Ray, ray2::Ray)::Float 
  nor, surf = oriented_surface
  _, outRayDir = ray2
  if surf isa Matte
    relu(dor(nor, outRayDir))
  else
    0.0
  end
end

function applyFilter(filter::Filter, radiance::Radiance)::Radiance 
  filter .* radiance
end

function surfaceFilter(filter::Filter, surf::Surface)::Filter 
  if surf isa Matte
    filter .* surf.color
  else
    filter
  end
end

function sdObject(pos::Position, obj::Object)::Distance 
  if obj isa PassiveObject
    object_geom = obj.object_geom
    if object_geom isa Wall
      nor = object_geom.direction
      d = object_geom.distance
      d + dot(nor, pos)
    elseif object_geom isa Block
      blockPos = object_geom.position
      halfWidths = object_geom.blockhalfwidths
      angle = object_geom.angle
      
      newPos = rotateY(pos - blockPos, angle)
      length(map(relu, map(abs, newPos) - halfWidths))
    else # object_geom isa Sphere
      spherePos = object_geom.position
      r = object_geom.radius

      newPos = pos - spherePos
      relu(length(newPos) - r)
    end
  else # obj isa Light
    squarePos = object.position
    hw = object.something

    newPos = pos - squarePos
    halfWidths = [hw, 0.01, hw]
    length(map(relu, map(abs, newPos) - halfWidths))
  end
end

function sdScene(scene::Scene, pos::Position) # (Object & Distance) 
  tuples = []
  for i in length(objects)
    push!(tuples, (sdObject(pos, objects[i]), i))
  end
  reverse(minimum(tuples))
end

function calcNormal(obj::Object, pos::Position)::Direction 
  normalize(grad(flip(sdObject, obj)) pos)
end

# ----- Start: Define RayMarchResult ----- #
abstract type RayMarchResult end

struct HitObj <: RayMarchResult
  ray::Ray
  oriented_surface::OrientedSurface
end

struct HitLight <: RayMarchResult
  radiance::Radiance
end

struct HitNothing <: RayMarchResult end

# ----- End: Define RayMarchResult ----- #

function raymarch(scene::Scene, ray::Ray)::RayMarchResult 
  maxIters = 100
  tol = 0.01
  startLength = 10.0 * tol # trying to escape the current surface
  (rayOrigin, rayDir) = ray

end

function rayDirectRadiance(scene::Scene, ray::Ray)::Radiance 
  result = raymarch(scene, ray)
  if result isa HitLight
    result.radiance
  elseif result isa HitNothing
    [0.0, 0.0, 0.0] # color zero
  else # result isa HitObj
    [0.0, 0.0, 0.0] # color zero
  end
end

function sampleSquare(hw::Float, rng::AbstractRNG)::Position
  x = rand_uniform(-hw, hw, rng)
  z = rand_uniform(-hw, hw, rng)
  [x, 0.0, z] 
end

function sampleLightRadiance(scene::Scene, osurf::OrientedSurface, inRay::Ray, rng::AbstractRNG)::Radiance 
  surfNor, surf = osurf
  rayPos, _ = inRay

  radiance = [0.0, 0.0, 0.0]
  for object in scene
    if object isa Light
      lightPos = object.position
      hw = object.something
      dirToLight, distToLight = directionAndLength(lightPos + sampleSquare(hw, rng) - rayPos)
      if positiveProject(dirToLight, surfNor)
        fracSolidAngle = relu(dot(dirToLight, yHat)) * (hw^2) / (pi * (distToLight)^2)
        outRay = (rayPos, dirToLight)
        coeff = fracSolidAngle * probReflection(osurf, inRay, outRay)
        radiance += coeff .* rayDirectRadiance(scene, outRay)
      end
    end
    radiance
  end
  #=
  yieldAccum \radiance.
    for i. case objs.i of
      PassiveObject _ _ -> ()
      Light lightPos hw _ ->
        (dirToLight, distToLight) = directionAndLength $ lightPos + sampleSquare hw k - rayPos
        if positiveProjection dirToLight surfNor then
          -- light on this far side of current surface
          fracSolidAngle = (relu $ dot dirToLight yHat) * sq hw / (pi * sq distToLight)
          outRay = (rayPos, dirToLight)
          coeff = fracSolidAngle * probReflection osurf inRay outRay
          radiance += coeff .* rayDirectRadiance scene outRay
  =#
end

function trace(params::Params, scene::Scene, initRay::Ray, rng::AbstractRNG)::Color 
  filter = [1.0, 1.0, 1.0]
  ray = initRay
  for i in 1:(params.maxBounces)
    result = raymarch(scene, ray)
    if result isa HitNothing           
      break
    elseif result isa HitLight
      if i == 0
        radiance += itensity
      end
      break
    else # result isa HitObj
      incidentRay = result.ray
      osurf = result.oriented_surface
      
      lightRadiance = sampleLightRadiance(scene, osurf, incidentRay, rng)
      ray = sampleReflection(osurf, incidentRay, rng)
      filter = surfaceFilter(filter, osurf[2])
      radiance += applyFilter(filter, lightRadiance)
    end
  end
  radiance
  #=
  yieldAccum \radiance.
    runState  noFilter \filter.
      runState initRay  \ray.
      boundedIter (getAt #maxBounces params) () \i.
        case raymarch scene $ get ray of
          HitNothing -> Done ()
          HitLight intensity ->
            if i == 0 then radiance += intensity   -- TODO: scale etc
            Done ()
          HitObj incidentRay osurf ->
            [k1, k2] = splitKey $ hash k i
            lightRadiance = sampleLightRadiance scene osurf incidentRay k1
            ray    := sampleReflection osurf incidentRay k2
            filter := surfaceFilter (get filter) (snd osurf)
            radiance += applyFilter (get filter) lightRadiance
            Continue
  =#
end

struct Camera 
  numPix::Int
  pos::Position
  halfWidth::Float64
  sensorDist::Float64
end

function cameraRays(n::Int, camera::Camera)
  halfWidth = camera.halfWidth
  pixHalfWidth = halfWidth / IToF n 
  ys = reverse(linspace(n, -halfWidth, halfWidth))
  xs = linspace(n, -halfWidth, halfWidth)
  output = zeros(n,n)
  for i in 1:n
    for j in 1:n 
      output[i][j] = function(rng::AbstractRNG)
                       x = xs[j] + rand_uniform(-pixHalfWidth, pixHalfWidth, rng)
                       y = ys[i] + rand_uniform(-pixHalfWidth, pixHalfWidth, ky)
                       (camera.pos, normalize([x, y, -camera.sensorDist]))
                     end
    end 
  end
  output
end

function takePicture(params::Params, scene::Scene, camera::Camera)::Image 
  n = camera.numPix
  rays = cameraRays(n, camera)
  rng = MersenneTwister(0)
  image = zeros(n,n)
  for i in 1:n
    for j in 1:n 
      function sampleRayColor(rng::AbstractRNG, color::Color)
        trace(params, scene, rays[i][j](rng), rng)
      end
      image[i][j] = sample_average(sampleRayColor, params.num_samples, rng)
    end
  end
  meanColor = sum(sum(sum(image)))/(n*n*3)
  image/meanColor  
end

# TODO: Image? Matrix? flip? grad?