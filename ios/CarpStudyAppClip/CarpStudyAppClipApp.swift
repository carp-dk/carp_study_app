import SwiftUI
import AppClipUI

@main
struct CarpStudyAppClipApp: App {
    var body: some Scene {
        AppClipScene(
            configuration: .init(
                appName: "CARP Studies",
                subtitle: "Participate in health research",
                appStoreURL: URL(string: "https://apps.apple.com/us/app/carp-studies/id1569798025")!,
                appGroupID: "group.dk.carp",
                storageKey: "inviteURL"
            )
        )
    }
}
