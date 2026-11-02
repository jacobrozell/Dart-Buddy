import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func fullVisitKeepsThreeDarts() {
    let tray = [
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
    ]
    let result = X01CameraVisit.dartsToEnter(tray: tray, alreadyEntered: [], remainingScore: 501)
    #expect(result.count == 3)
}

@Test(.tags(.unit, .regression))
func checkoutOnSecondDartDropsThird() {
    let tray = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(19)),
        DartInput(multiplier: .single, segment: .oneToTwenty(12)),
    ]
    let result = X01CameraVisit.dartsToEnter(tray: tray, alreadyEntered: [], remainingScore: 117)
    #expect(result.count == 2)
}

@Test(.tags(.unit, .regression))
func bustOnFirstDartDropsRest() {
    let tray = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(1)),
    ]
    let result = X01CameraVisit.dartsToEnter(tray: tray, alreadyEntered: [], remainingScore: 50)
    #expect(result.count == 1)
}

@Test(.tags(.unit, .regression))
func alreadyEnteredDartReducesRoom() {
    let already = [DartInput(multiplier: .single, segment: .oneToTwenty(20))]
    let tray = [
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
    ]
    let result = X01CameraVisit.dartsToEnter(tray: tray, alreadyEntered: already, remainingScore: 501)
    #expect(result.count == 2)
}
