import Foundation

enum X01CameraVisit {
    static func visitEnds(_ darts: [DartInput], remainingScore: Int) -> Bool {
        darts.count >= 3 || darts.reduce(0) { $0 + $1.points } >= remainingScore
    }

    /// Darts from the tray to append, stopping at the dart that ends the visit.
    static func dartsToEnter(
        tray: [DartInput],
        alreadyEntered: [DartInput],
        remainingScore: Int
    ) -> [DartInput] {
        var accepted: [DartInput] = []
        for dart in tray {
            if visitEnds(alreadyEntered + accepted, remainingScore: remainingScore) { break }
            accepted.append(dart)
        }
        return accepted
    }
}
