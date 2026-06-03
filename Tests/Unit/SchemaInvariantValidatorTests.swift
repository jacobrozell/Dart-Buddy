import Testing
@testable import DartBuddy

@Test(.tags(.migration, .swiftdata, .critical, .regression))
func contiguousEventIndexValidatorAcceptsSequentialIndexes() {
    #expect(SchemaInvariantValidator.hasContiguousEventIndexes([0, 1, 2, 3]))
    #expect(SchemaInvariantValidator.hasContiguousEventIndexes([3, 2, 1, 0]))
}

@Test(.tags(.migration, .swiftdata, .critical, .regression))
func contiguousEventIndexValidatorRejectsGaps() {
    #expect(!SchemaInvariantValidator.hasContiguousEventIndexes([0, 1, 3]))
}
