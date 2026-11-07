import SwiftUI

@main
struct JoyntApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
                .onAppear {
                    if ProcessInfo.processInfo.arguments.contains("-demoAuto") {
                        store.continueWithDemo()
                        if ProcessInfo.processInfo.arguments.contains("-tabPost") {
                            store.selectedTab = .post
                        } else if ProcessInfo.processInfo.arguments.contains("-tabProfile") {
                            store.selectedTab = .profile
                        } else {
                            store.selectedTab = .feed
                            store.feedKind = .forYou
                        }
                    }
                }
        }
    }
}
