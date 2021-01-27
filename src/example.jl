using RayMarch
using RayMarch: xHat, yHat, zHat, Light, PassiveObject, Wall, Matte, Block, Sphere, Mirror, Params, Camera, takePicture
using Images 
using BenchmarkTools

dex_test_mode = true
smallDim = 100

# define colors
lightColor     = [0.2, 0.2, 0.2]
leftWallColor  = 1.5 .* [0.611, 0.0555, 0.062]
carColor       = 1.5 .* [0.611, 0.0555, 0.062]
rightWallColor = 1.5 .* [0.117, 0.4125, 0.115]
whiteWallColor = [255.0, 239.0, 196.0] / 255.0
blockColor     = [200.0, 200.0, 255.0] / 255.0

# define scene: car
theScene = [Light([0.0, 1.9, 0.0], 0.5, lightColor),
            PassiveObject(Wall(-yHat, 2.0), Matte(whiteWallColor)),
            PassiveObject(Wall(zHat,  2.0), Matte(whiteWallColor)),
            PassiveObject(Block([1.0, -1.2,  1.2], [0.9, 0.7, 0.5], 0), Matte(carColor)),
            PassiveObject(Block([-0.3, -1.2,  1.2], [0.4, 0.3, 0.5], 0), Matte(carColor)),
            PassiveObject(Block([2.3, -1.2,  1.2], [0.4, 0.3, 0.5], 0), Matte(carColor)),
            PassiveObject(Sphere([0.6, -1.4,  0.9], 0.2), Matte(blockColor)),
            PassiveObject(Sphere([0.6, -1.4,  1.5], 0.2), Matte(blockColor)),
            PassiveObject(Sphere([1.4, -1.4,  0.9], 0.2), Matte(blockColor)),
            PassiveObject(Sphere([1.4, -1.4,  1.5], 0.2), Matte(blockColor))]

# define scene: default
# theScene = [Light((1.9 .* yHat), 0.5, lightColor),
#             PassiveObject(Wall(xHat, 2.0), Matte(leftWallColor)),
#             PassiveObject(Wall(-xHat, 2.0), Matte(rightWallColor)),
#             PassiveObject(Wall(yHat, 2.0), Matte(whiteWallColor)),
#             PassiveObject(Wall(-yHat, 2.0), Matte(whiteWallColor)),
#             PassiveObject(Wall(zHat,  2.0), Matte(whiteWallColor)),
#             PassiveObject(Block([1.0, -1.6,  1.2], [0.6, 0.8, 0.6], 0.5), Matte(blockColor)),
#             PassiveObject(Sphere([-1.0, -1.2,  0.2], 0.8), Matte(0.7 .* whiteWallColor)),
#             PassiveObject(Sphere([ 2.0,  2.0, -2.0], 1.5), Mirror())]

# define params
defaultParams = Params(50, 10, true)

# define camera
defaultCamera = Camera(250, 10.0 .* zHat, 0.3, 1.0)

# We change to a small num pix here to reduce the compute needed for tests
params = defaultParams

if dex_test_mode
  camera = Camera(smallDim, [0.0, 0.0, 10.0], 0.3, 1.0)
else 
  camera = defaultCamera
end

# compute image!
@time begin
  image_matrix = takePicture(params, theScene, camera)
end

m = maximum(map(x -> x > 1 ? -Inf64 : x, image_matrix/mean(image_matrix)))
n = minimum(map(x -> x > 1 ? Inf64 : x, image_matrix/mean(image_matrix)))

# m = maximum(image_matrix)
# n = minimum(image_matrix)


a = 255.0/(m - n)
b = -a*n

thresholded_image = map(x -> x > 1 ? Inf64 : x, image_matrix/mean(image_matrix)) .* a .+ b
final_image = map(x -> x == Inf64 ? 255.0 : x, thresholded_image)
# final_image = image_matrix .* a .+ b
save("rgb.png", colorview(RGB, final_image./255))