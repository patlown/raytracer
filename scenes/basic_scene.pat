scene {
    camera {
        position : (0, 0, -20)
        direction : (0, 0, 1)
        focal_distance : 10
    }

    screen {
        width : 480
        height : 640
    }

    light {
        position : (0, 0, 20)
        color : (1, 1, 1)
    }

    sphere {
        center : (0, 0, 0)
        radius : 5
        material {
            color : (1, 0, 0)
            reflectivity : 0.5
        }
    }
}
