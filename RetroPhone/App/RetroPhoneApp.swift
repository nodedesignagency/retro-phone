import SwiftUI

@main
struct RetroPhoneApp: App {
    /// Owns the haptic and audio engines, so it's created once here rather than
    /// in a view that SwiftUI may initialise more than once.
    @State private var engine = RotaryDialEngine()

    var body: some Scene {
        WindowGroup {
            DialerScreen(engine: engine)
                .preferredColorScheme(.dark)
        }
    }
}
