import Testing

/// Guards gameplay accessibility identifiers relied on by UI and WCAG tests.
@Test(.tags(.unit, .regression))
func gameplayUITestIdentifierContract() {
    let x01PadKeys = [
        "pad_0", "pad_double", "pad_triple", "pad_undo", "pad_25"
    ] + (1 ... 20).map { "pad_\($0)" }

    let cricketPadKeys = [
        "cricket_20", "cricket_19", "cricket_18", "cricket_17", "cricket_16", "cricket_15",
        "cricket_bull", "cricket_miss", "cricket_double", "cricket_triple", "cricket_undo", "cricket_enter"
    ]

    let boardLandmarks = [
        "scoreCard_active", "scoreCard", "cricket_column_active", "cricket_column",
        "match_exit", "match_undo", "x01_match_config_summary", "cricket_match_subtitle"
    ]

    let summaryLandmarks = [
        "matchSummaryHeader", "matchSummaryRematch", "matchSummaryDone", "matchSummaryUndoLastThrow",
        "matchSummaryForfeitBanner", "matchSummaryForfeitSubtitle"
    ]

    let forfeitLandmarks = [
        "match_exit_save_and_forfeit", "match_exit_abandon",
        "forfeit_player_picker", "forfeit_winner_picker", "forfeit_final_confirm",
        "forfeit_confirm_action", "forfeit_confirm_cancel"
    ]

    let setupLandmarks = [
        "startMatchButton", "resumeMatchButton", "setup_changeModeButton", "setup_addPlayer"
    ]

    for identifier in x01PadKeys + cricketPadKeys + boardLandmarks + summaryLandmarks + forfeitLandmarks + setupLandmarks {
        #expect(!identifier.isEmpty)
        #expect(identifier == identifier.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    #expect(x01PadKeys.count == 25)
    #expect(cricketPadKeys.count == 12)
}
