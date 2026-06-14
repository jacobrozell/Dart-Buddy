import SwiftData
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .settings, .swiftdata, .regression))
func legacySettingsWithoutBotColumnsDefaultToEnabled() async throws {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let context = ModelContext(container)
    let record = SchemaV1.SettingsRecord()
    record.botStaggerEnabled = nil
    record.botDartHapticsEnabled = nil
    context.insert(record)
    try context.save()

    let repository = SwiftDataSettingsRepository(container: container)
    let settings = try await repository.fetchSettings()

    #expect(settings.botStaggerEnabled == true)
    #expect(settings.botDartHapticsEnabled == true)
}

@Test(.tags(.unit, .settings, .swiftdata, .regression))
func legacySettingsWithoutDartEntryPresentationDefaultToNumberPad() async throws {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let context = ModelContext(container)
    let record = SchemaV1.SettingsRecord()
    record.defaultDartEntryPresentationRaw = nil
    context.insert(record)
    try context.save()

    let repository = SwiftDataSettingsRepository(container: container)
    let settings = try await repository.fetchSettings()

    #expect(settings.defaultDartEntryPresentationRaw == DartEntryPresentation.numberPad.rawValue)
}
