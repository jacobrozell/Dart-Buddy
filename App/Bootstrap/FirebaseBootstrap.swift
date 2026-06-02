import Foundation

enum FirebaseBootstrap {
    /// Skip Firebase when the bundled plist is still the checked-in placeholder (CI, fresh clones).
    static var shouldConfigure: Bool {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let appID = plist["GOOGLE_APP_ID"] as? String
        else {
            return false
        }
        return !appID.contains("REPLACE_WITH")
    }
}
