using RayMarch
using RayMarch: xHat, yHat, zHat, Light, PassiveObject, Wall, Matte, Block, Sphere, Mirror, Params, Camera, takePicture
using Images 
using BenchmarkTools

dex_test_mode = true
smallDim = 100

# define colors
lightColor     = [0.2, 0.2, 0.2]
leftWallColor  = 1.5 .* [0.611, 0.0555, 0.062]
rightWallColor = 1.5 .* [0.117, 0.4125, 0.115]
whiteWallColor = [255.0, 239.0, 196.0] / 255.0
blockColor     = [200.0, 200.0, 255.0] / 255.0

# define scene
theScene = [Light((1.9 .* yHat), 0.5, lightColor),
            PassiveObject(Wall(xHat, 2.0), Matte(leftWallColor)),
            PassiveObject(Wall(-xHat, 2.0), Matte(rightWallColor)),
            PassiveObject(Wall(yHat, 2.0), Matte(whiteWallColor)),
            PassiveObject(Wall(-yHat, 2.0), Matte(whiteWallColor)),
            PassiveObject(Wall(zHat,  2.0), Matte(whiteWallColor)),
            PassiveObject(Block([1.0, -1.6,  1.2], [0.6, 0.8, 0.6], 0.5), Matte(blockColor)),
            PassiveObject(Sphere([-1.0, -1.2,  0.2], 0.8), Matte(0.7 .* whiteWallColor)),
            PassiveObject(Sphere([ 2.0,  2.0, -2.0], 1.5), Mirror())]

# define params
defaultParams = Params(50, 10, true)

# define camera
defaultCamera = Camera(250, 10.0 .* zHat, 0.3, 1.0)

# We change to a small num pix here to reduce the compute needed for tests
params = defaultParams

if dex_test_mode
  camera = Camera(smallDim, 10.0 * zHat, 0.3, 1.0)
else 
  camera = defaultCamera
end

# compute image!
@time begin
  image = takePicture(params, theScene, camera)
end

red = [[image[i][j][1] for j in 1:smallDim] for i in 1:smallDim]
blue = [[image[i][j][2] for j in 1:smallDim] for i in 1:smallDim]
green = [[image[i][j][3] for j in 1:smallDim] for i in 1:smallDim]

image = [red, blue, green]


image_matrix = [image[i][j][k] for i = 1:3, j = 1:smallDim, k=1:smallDim]

m = maximum(image_matrix)
n = minimum(image_matrix)

a = 255.0/(m - n)
b = -a*n

final_image = image_matrix .* a .+ b
save("rgb.png", colorview(RGB, final_image./255))