struct TrackpadInteractionState {
    var isDragging = false
    var fingerCount = 0

    var icon: String {
        switch fingerCount {
        case 1:  return isDragging ? "hand.draw.fill" : "hand.point.up.left.fill"
        case 2:  return "hand.raised.fingers.spread"
        case 3:  return "hand.raised.fill"
        case 4:  return "rectangle.stack.fill"
        default: return "hand.point.up.left"
        }
    }
    var label: String {
        switch fingerCount {
        case 1:  return isDragging ? "커서 이동 중" : "탭: 클릭"
        case 2:  return "스크롤  |  좌우: 페이지  |  탭: 우클릭"
        case 3:  return isDragging ? "드래그 중 🖱" : "3손가락 드래그"
        case 4:  return "미션 컨트롤 ↑"
        default: return "손가락을 올려주세요"
        }
    }
}
