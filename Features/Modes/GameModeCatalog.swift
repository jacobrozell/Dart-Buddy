import Foundation
import SwiftUI

/// Single source of truth for every game mode Dart Buddy intends to offer.
///
/// This is the catalog stub described in `docs/full-game-catalog-ui.md`: all 29
/// modes (5 shipped + 24 planned) live here as data so the Modes tab, Activity
/// filters, history badges, and per-mode setup can read one list instead of each
/// hard-coding mode knowledge. Planned modes carry `status == .planned` (no
/// `MatchType`, not routable) and surface as "coming soon" until their engine
/// ships and they are promoted to `.shipped`.
///
/// Identity (icon/accent) is keyed off the catalog `id`, **not** `MatchType`,
/// so the 23 modes without a `MatchType` still get a stable look. Nothing here
/// renders yet; promoting these into UI is gated on `specs/ModesTabSpec.md`
/// (per `specs/SpecGovernance.md`). Per-mode rules: `specs/game-modes/implemented/` or `planned/`.

/// Top-level grouping a mode is browsed under in the catalog.
enum GameModeSection: String, CaseIterable, Identifiable, Hashable {
    case standard
    case party
    case coop
    case practice

    var id: String { rawValue }

    /// Localization key for the section header (resolved when the Modes tab ships).
    var titleKey: String { "modes.section.\(rawValue)" }
}

/// Whether a mode is playable today or a catalog placeholder.
enum GameModeStatus: String, Hashable {
    /// Engine + gameplay UI exist; routable via `MatchType` today.
    case shipped
    /// Catalog stub only — shown as "coming soon", Start disabled.
    case planned

    var isAvailable: Bool { self == .shipped }
}

/// Reusable gameplay screen template a mode renders with.
///
/// The catalog deliberately maps 28 modes onto a small set of layouts (see
/// `docs/full-game-catalog-ui.md` §5) so new modes mostly add an engine +
/// catalog row + template config, not a bespoke screen.
enum GameplayUITemplate: String, Hashable {
    case checkoutScore     // A — X01 family (remaining/checkout)
    case markBoard         // B — Cricket family (close/marks)
    case inningPoints      // C — Baseball / Shanghai (per-round points)
    case livesElimination  // D — Killer family (lives, knockouts)
    case sequenceProgress  // E — Around the Clock family (target race)
    case soloChallenge     // F — Bob's 27 / Halve-It (single big score)
    case phaseRace         // G — Football (phase-gated targets)
    case boardState        // H — Prisoner / Tic-Tac-Toe (spatial board)
    case roleSplit         // I — Scam / Snooker (per-player roles/phases)
}

/// Stat family a mode contributes, driving the Statistics segment and Match
/// Summary highlights. Heterogeneous modes can't share one average (see
/// `docs/full-game-catalog-ui.md` §6a), so each declares what it produces.
enum ModeStatKind: String, Hashable {
    case checkout    // averages, checkout %, highest turn
    case marks       // marks closed, points scored
    case innings     // runs per inning / round
    case lives       // kills dealt, lives remaining
    case sequence    // completion time, perfect segments
    case soloScore   // final score vs par
    case goals       // goals timeline
    case boardClaim  // grid / ring claim log
    case roleScore   // role / phase scores
    case bossRaid    // co-op boss PvE outcomes
    case coopHeist   // shared puzzle co-op (The Vault)
}

/// One mode in the catalog.
struct GameModeCatalogEntry: Identifiable, Hashable {
    /// Stable identity (e.g. `"standard.x01"`). Drives accent, badge, and filter
    /// keying so unreleased modes get a consistent look without a `MatchType`.
    let id: String
    /// English fallback display name (tests and catalog authoring).
    let name: String
    /// English fallback blurb shown under the title on a catalog card.
    let blurb: String
    let section: GameModeSection
    let status: GameModeStatus
    let minimumPlayers: Int
    /// Most modes scale to a full board of players; solo-only drills set this to 1.
    var maximumPlayers: Int = 8
    /// Non-nil only for shipped, routable modes.
    let matchType: MatchType?
    let uiTemplate: GameplayUITemplate
    let statKind: ModeStatKind
    /// SF Symbol for the mode badge (id-keyed identity).
    let iconSystemName: String

    /// Competitive matches using shared lifecycle get forfeit via MatchLifecycleChrome.
    var usesStandardMatchForfeit: Bool { matchType != nil && status == .shipped }

    var isAvailable: Bool { status.isAvailable }

    /// Whether Play setup can apply this entry on the current product surface.
    var isSelectableInPlaySetup: Bool { pendingModeSelection != nil }

    /// Solo modes skip the roster step in setup — they cap at a single player.
    /// X01 has a minimum of one but is multiplayer-capable, so it is *not* solo.
    var isSolo: Bool { maximumPlayers <= 1 }

    /// Whether the rules sheet covers this mode (`GameRulesCatalog`), including preview guides on planned co-op cards.
    var hasRulesGuide: Bool {
        if let matchType {
            return GameRulesCatalog.hasGuide(for: matchType)
        }
        return GameRulesCatalog.hasPreviewGuide(for: id)
    }
}

/// The full mode catalog. Order within a section is the display order.
enum GameModeCatalog {
    static let all: [GameModeCatalogEntry] = [
        // MARK: Standard
        GameModeCatalogEntry(
            id: "standard.x01", name: "X01", blurb: "301 · 501 · double out",
            section: .standard, status: .shipped, minimumPlayers: 1,
            matchType: .x01, uiTemplate: .checkoutScore, statKind: .checkout,
            iconSystemName: "target"
        ),
        GameModeCatalogEntry(
            id: "standard.cricket", name: "Cricket", blurb: "Cut throat · points on/off",
            section: .standard, status: .shipped, minimumPlayers: 2,
            matchType: .cricket, uiTemplate: .markBoard, statKind: .marks,
            iconSystemName: "circle.grid.3x3.fill"
        ),
        GameModeCatalogEntry(
            id: "standard.americanCricket", name: "American Cricket", blurb: "Cricket on 20→15 + bull",
            section: .standard, status: .shipped, minimumPlayers: 2,
            matchType: .americanCricket, uiTemplate: .markBoard, statKind: .marks,
            iconSystemName: "circle.grid.3x3"
        ),

        // MARK: Party
        GameModeCatalogEntry(
            id: "party.baseball", name: "Baseball", blurb: "Nine innings of points",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .baseball, uiTemplate: .inningPoints, statKind: .innings,
            iconSystemName: "baseball.fill"
        ),
        GameModeCatalogEntry(
            id: "party.killer", name: "Killer", blurb: "Become a killer, take lives",
            section: .party, status: .shipped, minimumPlayers: 3,
            matchType: .killer, uiTemplate: .livesElimination, statKind: .lives,
            iconSystemName: "bolt.fill"
        ),
        GameModeCatalogEntry(
            id: "party.shanghai", name: "Shanghai", blurb: "Seven rounds, hit the Shanghai",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .shanghai, uiTemplate: .inningPoints, statKind: .innings,
            iconSystemName: "star.fill"
        ),
        GameModeCatalogEntry(
            id: "party.mickeyMouse", name: "Mickey Mouse", blurb: "Cricket variant, descending targets",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .mickeyMouse, uiTemplate: .markBoard, statKind: .marks,
            iconSystemName: "circle.grid.2x2.fill"
        ),
        GameModeCatalogEntry(
            id: "party.mulligan", name: "Mulligan", blurb: "Random close targets each game",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .mulligan, uiTemplate: .markBoard, statKind: .marks,
            iconSystemName: "arrow.uturn.backward.circle.fill"
        ),
        GameModeCatalogEntry(
            id: "party.englishCricket", name: "English Cricket", blurb: "Batter vs bowler scoring",
            section: .party, status: .shipped, minimumPlayers: 2, maximumPlayers: 2,
            matchType: .englishCricket, uiTemplate: .checkoutScore, statKind: .checkout,
            iconSystemName: "figure.cricket"
        ),
        GameModeCatalogEntry(
            id: "party.blindKiller", name: "Blind Killer", blurb: "Killer with hidden numbers",
            section: .party, status: .planned, minimumPlayers: 3,
            matchType: nil, uiTemplate: .livesElimination, statKind: .lives,
            iconSystemName: "eye.slash.fill"
        ),
        GameModeCatalogEntry(
            id: "party.knockout", name: "Knockout", blurb: "Beat the previous score or lose a life",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .knockout, uiTemplate: .checkoutScore, statKind: .checkout,
            iconSystemName: "bolt.horizontal.fill"
        ),
        GameModeCatalogEntry(
            id: "party.suddenDeath", name: "Sudden Death", blurb: "Lowest score is eliminated",
            section: .party, status: .shipped, minimumPlayers: 3,
            matchType: .suddenDeath, uiTemplate: .checkoutScore, statKind: .checkout,
            iconSystemName: "exclamationmark.triangle.fill"
        ),
        GameModeCatalogEntry(
            id: "party.fiftyOneByFives", name: "51 By 5's", blurb: "Score must be divisible by five",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .fiftyOneByFives, uiTemplate: .checkoutScore, statKind: .checkout,
            iconSystemName: "5.circle.fill"
        ),
        GameModeCatalogEntry(
            id: "party.golf", name: "Golf", blurb: "Nine or eighteen holes, fewest strokes",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .golf, uiTemplate: .inningPoints, statKind: .innings,
            iconSystemName: "figure.golf"
        ),
        GameModeCatalogEntry(
            id: "party.football", name: "Football", blurb: "Kickoff on bull, then score goals",
            section: .party, status: .shipped, minimumPlayers: 2, maximumPlayers: 2,
            matchType: .football, uiTemplate: .phaseRace, statKind: .goals,
            iconSystemName: "soccerball"
        ),
        GameModeCatalogEntry(
            id: "party.grandNational", name: "Grand National", blurb: "Clear the fences in order",
            section: .party, status: .shipped, minimumPlayers: 2,
            matchType: .grandNational, uiTemplate: .sequenceProgress, statKind: .sequence,
            iconSystemName: "flag.checkered"
        ),
        GameModeCatalogEntry(
            id: "party.hareAndHounds", name: "Hare and Hounds", blurb: "Chase around the board",
            section: .party, status: .shipped, minimumPlayers: 2, maximumPlayers: 2,
            matchType: .hareAndHounds, uiTemplate: .sequenceProgress, statKind: .sequence,
            iconSystemName: "hare.fill"
        ),
        GameModeCatalogEntry(
            id: "party.followTheLeader", name: "Follow the Leader", blurb: "Match the leader's hit or lose a life",
            section: .party, status: .planned, minimumPlayers: 2,
            matchType: nil, uiTemplate: .livesElimination, statKind: .lives,
            iconSystemName: "arrow.turn.down.right"
        ),
        GameModeCatalogEntry(
            id: "party.loop", name: "Loop", blurb: "Beat the prior dart or drop a life",
            section: .party, status: .planned, minimumPlayers: 2,
            matchType: nil, uiTemplate: .livesElimination, statKind: .lives,
            iconSystemName: "arrow.triangle.2.circlepath"
        ),
        GameModeCatalogEntry(
            id: "party.prisoner", name: "Prisoner", blurb: "Trap darts in missed segments",
            section: .party, status: .planned, minimumPlayers: 2,
            matchType: nil, uiTemplate: .boardState, statKind: .boardClaim,
            iconSystemName: "lock.fill"
        ),
        GameModeCatalogEntry(
            id: "party.scam", name: "Scam", blurb: "Stopper blocks, scorer scores",
            section: .party, status: .planned, minimumPlayers: 2, maximumPlayers: 2,
            matchType: nil, uiTemplate: .roleSplit, statKind: .roleScore,
            iconSystemName: "theatermasks.fill"
        ),
        GameModeCatalogEntry(
            id: "party.snooker", name: "Snooker", blurb: "Reds and colours on the board",
            section: .party, status: .planned, minimumPlayers: 2, maximumPlayers: 2,
            matchType: nil, uiTemplate: .roleSplit, statKind: .roleScore,
            iconSystemName: "circle.fill"
        ),
        GameModeCatalogEntry(
            id: "party.fleet", name: "Fleet", blurb: "Hide, call, throw, sink",
            section: .party, status: .shipped, minimumPlayers: 2, maximumPlayers: 2,
            matchType: .fleet, uiTemplate: .boardState, statKind: .boardClaim,
            iconSystemName: "ferry.fill"
        ),
        GameModeCatalogEntry(
            id: "party.ticTacToe", name: "Tic-Tac-Toe", blurb: "Claim three segments in a row",
            section: .party, status: .planned, minimumPlayers: 2, maximumPlayers: 2,
            matchType: nil, uiTemplate: .boardState, statKind: .boardClaim,
            iconSystemName: "number.square.fill"
        ),

        // MARK: Co-op
        GameModeCatalogEntry(
            id: "coop.raid", name: "Raid", blurb: "Co-op boss fight — close, then finish",
            section: .coop, status: .shipped, minimumPlayers: 1, maximumPlayers: 3,
            matchType: .raid, uiTemplate: .phaseRace, statKind: .bossRaid,
            iconSystemName: "shield.lefthalf.filled"
        ),
        GameModeCatalogEntry(
            id: "coop.cerberus", name: "Cerberus", blurb: "Three heads — assign, close, survive bites",
            section: .coop, status: .planned, minimumPlayers: 1, maximumPlayers: 3,
            matchType: nil, uiTemplate: .roleSplit, statKind: .bossRaid,
            iconSystemName: "pawprint.fill"
        ),
        GameModeCatalogEntry(
            id: "coop.theVault", name: "The Vault", blurb: "Crack five locks before the alarm ends the run",
            section: .coop, status: .planned, minimumPlayers: 1, maximumPlayers: 4,
            matchType: nil, uiTemplate: .phaseRace, statKind: .coopHeist,
            iconSystemName: "lock.shield.fill"
        ),
        GameModeCatalogEntry(
            id: "coop.clearTheBoard", name: "Clear the Board", blurb: "Close every S/D/T cell — together or team vs team",
            section: .coop, status: .planned, minimumPlayers: 1, maximumPlayers: 8,
            matchType: nil, uiTemplate: .boardState, statKind: .boardClaim,
            iconSystemName: "square.grid.3x3.fill"
        ),

        // MARK: Practice
        GameModeCatalogEntry(
            id: "practice.aroundTheClock", name: "Around the Clock", blurb: "Hit 1 through 20 in order",
            section: .practice, status: .shipped, minimumPlayers: 1,
            matchType: .aroundTheClock, uiTemplate: .sequenceProgress, statKind: .sequence,
            iconSystemName: "clock.fill"
        ),
        GameModeCatalogEntry(
            id: "practice.aroundTheClock180", name: "180 Around the Clock", blurb: "Around the clock, scoring points",
            section: .practice, status: .shipped, minimumPlayers: 1,
            matchType: .aroundTheClock180, uiTemplate: .sequenceProgress, statKind: .sequence,
            iconSystemName: "clock.badge.fill"
        ),
        GameModeCatalogEntry(
            id: "practice.chaseTheDragon", name: "Chase the Dragon", blurb: "Trebles 1→20 then bull",
            section: .practice, status: .shipped, minimumPlayers: 1,
            matchType: .chaseTheDragon, uiTemplate: .sequenceProgress, statKind: .sequence,
            iconSystemName: "flame.fill"
        ),
        GameModeCatalogEntry(
            id: "practice.nineLives", name: "Nine Lives", blurb: "Three darts, three targets, nine lives",
            section: .practice, status: .shipped, minimumPlayers: 2,
            matchType: .nineLives, uiTemplate: .livesElimination, statKind: .lives,
            iconSystemName: "heart.fill"
        ),
        GameModeCatalogEntry(
            id: "practice.bobs27", name: "Bob's 27", blurb: "Doubles checkout drill",
            section: .practice, status: .planned, minimumPlayers: 1, maximumPlayers: 1,
            matchType: nil, uiTemplate: .soloChallenge, statKind: .soloScore,
            iconSystemName: "scope"
        ),
        GameModeCatalogEntry(
            id: "practice.halveIt", name: "Halve-It", blurb: "Miss the target, halve your score",
            section: .practice, status: .planned, minimumPlayers: 1, maximumPlayers: 1,
            matchType: nil, uiTemplate: .soloChallenge, statKind: .soloScore,
            iconSystemName: "divide.circle.fill"
        )
    ]

    /// Entries in a section, in display order.
    static func entries(in section: GameModeSection) -> [GameModeCatalogEntry] {
        all.filter { $0.section == section }
    }

    /// Playable-today entries for the current product surface.
    static var available: [GameModeCatalogEntry] {
        all.filter { entry in
            guard entry.isAvailable else { return false }
            if entry.section == .party, !ProductSurface.showsPartyModes { return false }
            return true
        }
    }

    /// "Coming soon" entries — the ones the "+N more coming" teaser collapses.
    static var planned: [GameModeCatalogEntry] {
        all.filter { !$0.isAvailable }
    }

    /// Number of planned modes in a section (drives the "+N more coming" teaser).
    static func comingSoonCount(in section: GameModeSection) -> Int {
        entries(in: section).filter { !$0.isAvailable }.count
    }

    /// Lean 1.0 Play setup picker exposes only core scorekeeper modes.
    private static let leanPlaySetupStandardIDs = ["standard.x01", "standard.cricket"]

    /// Sections for the in-place mode picker on Play setup (lean 1.0 shows X01 + Cricket only).
    static func playSetupPickerSections() -> [(GameModeSection, [GameModeCatalogEntry])] {
        guard ProductSurface.showsPartyModes else {
            let standard = leanPlaySetupStandardIDs.compactMap { entry(for: $0) }.filter(\.isAvailable)
            guard !standard.isEmpty else { return [] }
            return [(.standard, standard)]
        }

        return GameModeSection.allCases.compactMap { section in
            let sectionEntries = entries(in: section)
            guard !sectionEntries.isEmpty else { return nil }
            return (section, sectionEntries)
        }
    }

    /// Collapsed coming-soon count below the teaser rows in the Play setup picker.
    static func playSetupPickerMoreComingCount(
        in section: GameModeSection,
        displayedCount: Int
    ) -> Int {
        guard ProductSurface.showsPartyModes else { return 0 }
        return max(0, entries(in: section).count - displayedCount)
    }

    /// Catalog entry backing a routable match type, if any.
    static func entry(for matchType: MatchType) -> GameModeCatalogEntry? {
        all.first { $0.matchType == matchType }
    }

    static func entry(for id: String) -> GameModeCatalogEntry? {
        all.first { $0.id == id }
    }
}

extension GameModeCatalogEntry {
    var nameKey: String { "modes.catalog.\(id).name" }
    var blurbKey: String { "modes.catalog.\(id).blurb" }

    var localizedName: String { L10n.string(nameKey) }
    var localizedBlurb: String { L10n.string(blurbKey) }

    func matchesSearchQuery(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return localizedName.localizedCaseInsensitiveContains(query)
            || localizedBlurb.localizedCaseInsensitiveContains(query)
            || name.localizedCaseInsensitiveContains(query)
            || blurb.localizedCaseInsensitiveContains(query)
            || id.localizedCaseInsensitiveContains(query)
    }

    var accentColor: Color {
        if let matchType {
            return GameModeAccent.color(for: matchType)
        }
        switch section {
        case .standard: return Brand.proBot
        case .party: return Brand.orange
        case .coop: return Brand.amber
        case .practice: return Brand.green.opacity(0.85)
        }
    }

    var playerCountLabel: String {
        if isSolo {
            return L10n.string("modes.playerCount.solo")
        }
        if minimumPlayers >= maximumPlayers {
            return L10n.format("modes.playerCount.exactFormat", minimumPlayers)
        }
        // Modes accept the minimum and up; "+" avoids implying a hard upper cap.
        return L10n.format("modes.playerCount.minimumFormat", minimumPlayers)
    }

    /// Prefill payload when the user taps an available catalog card.
    var pendingModeSelection: PendingModeSelection? {
        guard isAvailable, let matchType else { return nil }
        if section == .party, !ProductSurface.showsPartyModes { return nil }
        switch section {
        case .standard:
            let mode: MatchSetupViewModel.SetupMode? = switch matchType {
            case .cricket: .cricket
            case .x01: .x01
            default: nil
            }
            return PendingModeSelection(
                setupCategory: .standard,
                mode: mode,
                partyGame: nil,
                matchType: matchType
            )
        case .party:
            let partyGame: PartyGame? = switch matchType {
            case .baseball: .baseball
            case .killer: .killer
            case .shanghai: .shanghai
            default: nil
            }
            return PendingModeSelection(
                setupCategory: .party,
                mode: nil,
                partyGame: partyGame,
                matchType: matchType
            )
        case .coop:
            return PendingModeSelection(
                setupCategory: .standard,
                mode: nil,
                partyGame: nil,
                matchType: matchType
            )
        case .practice:
            return PendingModeSelection(
                setupCategory: .standard,
                mode: nil,
                partyGame: nil,
                matchType: matchType
            )
        }
    }
}
