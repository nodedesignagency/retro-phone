import SwiftUI

@main
struct RetroPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            DialerScreen()
                .preferredColorScheme(.dark)
        }
    }
}
