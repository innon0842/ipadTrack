import SwiftUI

struct GestureGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GestureGuideRow(gesture: "1손가락 드래그", action: "커서 이동")
            GestureGuideRow(gesture: "1손가락 탭", action: "왼쪽 클릭")
            GestureGuideRow(gesture: "2손가락 드래그", action: "스크롤")
            GestureGuideRow(gesture: "2손가락 좌/우", action: "이전/다음 페이지")
            GestureGuideRow(gesture: "2손가락 탭", action: "오른쪽 클릭")
            GestureGuideRow(gesture: "3손가락 드래그", action: "드래그 (창 이동 등)")
            GestureGuideRow(gesture: "4손가락 위", action: "미션 컨트롤")
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 28)
    }
}
