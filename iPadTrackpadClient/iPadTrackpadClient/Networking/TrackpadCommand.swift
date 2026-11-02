/// Mac 서버와 공유하는 12바이트 패킷의 명령 코드입니다.
enum TrackpadCommand: UInt16 {
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
