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
                    let args = ProcessInfo.processInfo.arguments
                    let env = ProcessInfo.processInfo.environment
                    let demo = args.contains("-demoAuto") || env["JOYNT_DEMO"] == "1"
                    if demo {
                        store.continueWithDemo()
                    }
                    switch env["JOYNT_TAB"] ?? "" {
                    case "post":
                        store.selectedTab = .post
                    case "profile":
                        store.selectedTab = .profile
                    case "feed":
                        store.selectedTab = .feed
                        store.feedKind = .forYou
                    default:
                        if args.contains("-tabPost") {
                            store.selectedTab = .post
                        } else if args.contains("-tabProfile") {
                            store.selectedTab = .profile
                        } else if demo {
                            store.selectedTab = .feed
                            store.feedKind = .forYou
                        }
                    }
                }
                .onOpenURL { url in
                    store.applyDeepLink(url)
                }
        }
    }
}
