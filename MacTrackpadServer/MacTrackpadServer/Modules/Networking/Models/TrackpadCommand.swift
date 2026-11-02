nonisolated enum TrackpadCommand: UInt16, Sendable {
    case mouseMove   = 1
    case scroll      = 2
    case leftDown    = 3
    case leftUp      = 4
    case rightClick  = 5
    case pageBack    = 6
    case pageForward = 7
    case drag        = 8
    case dragEnd     = 9
    case missionCtrl = 10
}
