import SwiftUI
import BBNativePlayerKit

/// Cast button that uses the player SDK's ChromeCastHelper to create the native cast button.
/// Does NOT import GoogleCast directly — avoids forcing Cast SDK initialization at app launch.
struct CastButtonView: UIViewRepresentable {
    var tintColor: UIColor = .white

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        // ChromeCastHelper handles GCKCastContext initialization and button creation.
        // If Cast SDK isn't available or no devices on network, returns nil.
        if let btn = ChromeCastHelper.shared.createChromeCastButton(frame: container.bounds) {
            btn.tintColor = tintColor
            btn.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(btn)
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
