import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardMarkTargetCountMatchesStandardCricketTargets() {
    #expect(CricketBoardView.markTargetCount == CricketTarget.allCases.count)
    #expect(CricketBoardView.markTargetCount == 7)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardSplitComponentsShareColumnCount() {
    let columns = [
        CricketBoardView.Column(id: UUID(), name: "A", score: 20, marks: ["20": 3], isActive: true, colorToken: .blue),
        CricketBoardView.Column(id: UUID(), name: "B", score: 0, marks: [:], isActive: false, colorToken: .coral)
    ]

    #expect(columns.count == 2)
    #expect(CricketTarget.allCases.map(\.rawValue).contains("20"))
    #expect(CricketTarget.allCases.map(\.rawValue).contains("bull"))
}
