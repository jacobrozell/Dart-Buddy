import Foundation

/// Last-used Golf setup chip values (restored on setup `onAppear`).
enum GolfSetupPreferences {
    private static let courseLengthKey = "golfSetup.courseLength"

    static func load() -> GolfCourseLength {
        let defaults = UserDefaults.standard
        let raw = defaults.object(forKey: courseLengthKey) as? Int ?? 9
        return GolfCourseLength(rawValue: raw) ?? .nine
    }

    static func save(courseLength: GolfCourseLength) {
        UserDefaults.standard.set(courseLength.rawValue, forKey: courseLengthKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: courseLengthKey)
    }
}
