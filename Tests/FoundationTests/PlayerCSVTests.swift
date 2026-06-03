import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .regression))
func playerCSVTemplateRoundTripsThroughParser() throws {
    let template = PlayerCSV.template()
    let rows = try PlayerCSV.parse(template)
    #expect(rows.count == 2)
    #expect(rows[0].name == "Jane Smith")
    #expect(rows[0].isBot == false)
    #expect(rows[0].notes == "Lefty, prefers double 16")
    #expect(rows[1].name == "Practice Bot")
    #expect(rows[1].isBot == true)
    #expect(rows[1].botDifficultyRaw == "medium")
}

@Test(.tags(.unit, .regression))
func playerCSVParsesQuotedFieldsWithCommasAndNewlines() throws {
    let csv = """
    name,isBot,notes
    "Doe, John",false,"Line one
    line two"
    """
    let rows = try PlayerCSV.parse(csv)
    #expect(rows.count == 1)
    #expect(rows[0].name == "Doe, John")
    #expect(rows[0].notes == "Line one\nline two")
}

@Test(.tags(.unit, .regression))
func playerCSVHonorsHeaderColumnOrderAndExtraColumns() throws {
    let csv = """
    notes,name,unused,isBot
    Hello,Alice,xyz,yes
    """
    let rows = try PlayerCSV.parse(csv)
    #expect(rows.count == 1)
    #expect(rows[0].name == "Alice")
    #expect(rows[0].notes == "Hello")
    #expect(rows[0].isBot == true)
}

@Test(.tags(.unit, .regression))
func playerCSVSkipsRowsWithoutNameAndBlankLines() throws {
    let csv = """
    name,notes
    Alice,first
    ,orphan note

    Bob,second
    """
    let rows = try PlayerCSV.parse(csv)
    #expect(rows.map(\.name) == ["Alice", "Bob"])
}

@Test(.tags(.unit, .regression))
func playerCSVThrowsWhenNameColumnMissing() {
    let csv = "id,notes\n1,hello"
    #expect(throws: PlayerCSV.ParseError.missingNameColumn) {
        _ = try PlayerCSV.parse(csv)
    }
}

@Test(.tags(.unit, .regression))
func playerCSVExportEscapesAndRoundTrips() throws {
    let player = PlayerSummary(
        id: UUID(),
        name: "Smith, Jane",
        isArchived: false,
        isBot: false,
        avatarStyleRaw: "star",
        preferredColorToken: "blue",
        notes: "Says \"nice\"",
        createdAt: Date(),
        updatedAt: Date()
    )
    let csv = PlayerCSV.export([player])
    let rows = try PlayerCSV.parse(csv)
    #expect(rows.count == 1)
    #expect(rows[0].name == "Smith, Jane")
    #expect(rows[0].avatarStyleRaw == "star")
    #expect(rows[0].colorTokenRaw == "blue")
    #expect(rows[0].notes == "Says \"nice\"")
}
