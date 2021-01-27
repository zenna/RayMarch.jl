using RayMarch
using RayMarch: xHat, yHat, zHat, Light, PassiveObject, Wall, Matte, Block, Sphere, Mirror, Params, Camera, takePicture
using Images 
using BenchmarkTools

dex_test_mode = true
smallDim = 100

# define colors
lightColor     = [1.0, 1.0, 1.0]
leftWallColor  = 1.5 .* [0.611, 0.0555, 0.062]
carColor       = 1.5 .* [0.611, 0.0555, 0.062]
rightWallColor = 1.5 .* [0.117, 0.4125, 0.115]
whiteWallColor = [255.0, 239.0, 196.0] / 255.0
blockColor     = [200.0, 200.0, 255.0] / 255.0
blue           = [0.0,   191.0, 255.0] / 255.0
yellow         = [255.0, 255.0, 102.0] / 255.0  

# car position
car_x, car_y, car_z = [1.0, -1.2,  1.2]

# ped position
ped_x, ped_y, ped_z = [-1.5, -1.1, 1.2]

# obstruction position
obs_x, obs_y, obs_z = [2.0, -0.5,  -4.0]

car = [PassiveObject(Block([car_x,       car_y,  car_z], [0.9, 0.7, 0.5], 0), Matte(carColor)), # car body
       PassiveObject(Block([car_x - 1.3, car_y,  car_z], [0.4, 0.3, 0.5], 0), Matte(carColor)), # hood 
       PassiveObject(Block([car_x + 1.3, car_y,  car_z], [0.4, 0.3, 0.5], 0), Matte(carColor))] # trunk

ped = [PassiveObject(Block([ped_x,              ped_y, ped_z], [0.1, 0.3, 0.1], 0), Matte(yellow)), # body
       PassiveObject(Block([ped_x - 0.05, ped_y - 0.6, ped_z], [0.045, 0.3, 0.1], 0), Matte(yellow)), # left leg
       PassiveObject(Block([ped_x + 0.05, ped_y - 0.6, ped_z], [0.045, 0.3, 0.1], 0), Matte(yellow)), # right right
      #  PassiveObject(Block([ped_x - 0.15,       ped_y, ped_z], [0.045, 0.2, 0.95], 0), Matte(yellow)), # left arm
      #  PassiveObject(Block([ped_x + 0.15,       ped_y, ped_z], [0.045, 0.2, 0.95], 0), Matte(yellow)), # right arm
       PassiveObject(Sphere([ped_x,       ped_y + 0.4, ped_z], 0.125), Matte(yellow))] # head

obstruction = [PassiveObject(Block([obs_x, obs_y, obs_z], [3.0, 1.5, 3.0], 0), Matte(blue))]

# define scene: car
theScene = [Light([-1.0, 1.9, 2.5], 0.5, lightColor),
            PassiveObject(Wall(yHat, 2.0), Matte(whiteWallColor)),
            PassiveObject(Wall(-yHat, 2.0), Matte(whiteWallColor)),
            obstruction...,
            car...,
            ped...]

# define params
defaultParams = RayMarch.Params(50, 10, true)

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