import SwiftUI

struct AccessibilityNoticeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("⚠️ 접근성 권한 필요")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.yellow.opacity(0.9))
            Text("시스템 설정 › 개인정보 보호 및 보안 › 접근성\n→ MacTrackpadServer 추가 및 활성화")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.yellow.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 28)
    }
}
