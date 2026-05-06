# Repository Specification

## 1. Purpose
Define repository interfaces, responsibilities, and contracts between features/domain and persistence.

---

## 2. Repository Interfaces

## `PlayerRepository`
- CRUD, archive/unarchive
- Uniqueness validation
- Guarded delete behavior

## `MatchRepository`
- Create/start/update/complete match
- Append events
- Save/load snapshots
- Load active match and history pages

## `MatchCommandService` (recommended boundary)
- Accept platform-neutral commands (`SubmitTurn`, `UndoLastTurn`, `RequestState`)
- Validate and route commands through domain engines
- Emit typed outcomes for any client (`iPhone UI`, future `WatchConnectivity` adapter)

## `StatsRepository`
- Query raw events
- Compute/store aggregate cache
- Rebuild cache from source events

## `SettingsRepository`
- Read/write preferences
- Seed defaults
- Reset settings

---

## 3. Contract Rules
- Repositories expose domain-friendly DTOs, not SwiftData models.
- Return typed errors (`validation`, `conflict`, `persistenceFailure`).
- Writes are atomic per intent where practical.
- Domain rules must execute before persistence writes.
- Client transport layers (future watch) must call command/service boundaries, not repositories directly.

---

## 4. Threading/Concurrency
- Repository API is async-safe.
- Use actor isolation or serial write coordination to prevent race conditions.
- UI calls repository through ViewModel task boundaries.

---

## 5. Testing
- Contract tests per repository
- In-memory persistence test doubles for feature tests
- Failure-path tests (decode errors, write failures)
