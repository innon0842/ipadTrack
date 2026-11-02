import SwiftUI

struct TrackpadView: UIViewRepresentable {
    let sender: UDPSender
    let sensitivity: Float
    var onDraggingChanged: (Bool) -> Void
    var onFingerCountChanged: (Int) -> Void

    func makeUIView(context: Context) -> TrackpadUIView {
        let v = TrackpadUIView()
        v.sender = sender; v.sensitivity = sensitivity
        v.onDraggingChanged    = onDraggingChanged
        v.onFingerCountChanged = onFingerCountChanged
        return v
    }

    func updateUIView(_ uiView: TrackpadUIView, context: Context) {
        uiView.sender = sender; uiView.sensitivity = sensitivity
        uiView.onDraggingChanged    = onDraggingChanged
        uiView.onFingerCountChanged = onFingerCountChanged
    }
}
