using raymarch
lightColor     = [0.2, 0.2, 0.2]
leftWallColor  = 1.5 .* [0.611, 0.0555, 0.062]
rightWallColor = 1.5 .* [0.117, 0.4125, 0.115]
whiteWallColor = [255.0, 239.0, 196.0] / 255.0
blockColor     = [200.0, 200.0, 255.0] / 255.0

theScene = MkScene $
    [ Light (1.9 .* yHat) 0.5 lightColor
    , PassiveObject (Wall      xHat  2.0) (Matte leftWallColor)
    , PassiveObject (Wall (neg xHat) 2.0) (Matte rightWallColor)
    , PassiveObject (Wall      yHat  2.0) (Matte whiteWallColor)
    , PassiveObject (Wall (neg yHat) 2.0) (Matte whiteWallColor)
    , PassiveObject (Wall      zHat  2.0) (Matte whiteWallColor)
    , PassiveObject (Block  [ 1.0, -1.6,  1.2] [0.6, 0.8, 0.6] 0.5) (Matte blockColor)
    , PassiveObject (Sphere [-1.0, -1.2,  0.2] 0.8) (Matte (0.7.* whiteWallColor))
    , PassiveObject (Sphere [ 2.0,  2.0, -2.0] 1.5) (Mirror)
    ]

defaultParams = { numSamples = 50
                , maxBounces = 10
                , shareSeed  = True }

defaultCamera = { numPix     = 250
                , pos        = 10.0 .* zHat
                , halfWidth  = 0.3
                , sensorDist = 1.0 }

-- We change to a small num pix here to reduce the compute needed for tests
params = defaultParams
camera = if dex_test_mode ()
           then defaultCamera |> setAt #numPix 10
           else defaultCamera

-- %time
(MkImage _ _ image) = takePicture params theScene camera
:html imshow image
