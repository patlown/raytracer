scene {
    camera {
        position : (0, 0, -20)
        direction : (0, 0, 1)
        focal_distance : 10
    }

    screen {
        height : 640
        width : 480
    }

    light {
        position : (0, 10, -10)
        color : (1, 1, 1)
    }

    sphere {
        center : (0, 0, 10)
        radius : 3
        color : (1, 0, 0)
    }

    sphere {
        center : (-2, 0, 0)
        radius : 2
        color : (0, 0, .9)
    }
}
