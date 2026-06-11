# QA Sign-off (RC1)

## Candidate
- Version: `1.0.0-rc1`
- Build: `TBD`
- Device(s): `TBD - minimum 1 physical iPhone + 1 simulator`
- iOS version(s): `18.x minimum` + latest GA (verify migration on 18.x device/simulator)
- Execution owner: `TBD`
- Execution date: `TBD`

## Evidence Rules
- Mark each check as `Pass`, `Fail`, or `Blocked` (do not leave `Pending` once executed).
- For each `Fail`/`Blocked`, add a defect ID and owner in the Defects section.
- Record screenshot/video/log reference for each matrix group.

## Core Flow Matrix
- Setup -> X01 -> Summary: **Pending execution**
- Setup -> Cricket -> Summary: **Pending execution**
- Resume active match: **Pending execution**
- Undo flow (X01/Cricket): **Pending execution**
- History list/detail: **Pending execution**
- Statistics tab (filters + table): **Pending execution**
- Players archive/delete guard: **Pending execution**
- Settings reset flow: **Pending execution**

## Core Flow Execution Log
- Setup -> X01 -> Summary: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Setup -> Cricket -> Summary: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Resume active match: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Undo flow (X01/Cricket): status=`Pending`, evidence=`TBD`, notes=`TBD`
- History list/detail: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Statistics tab: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Players archive/delete guard: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Settings reset flow: status=`Pending`, evidence=`TBD`, notes=`TBD`

## Appearance and Orientation
- Portrait + Light: **Pending execution**
- Portrait + Dark: **Pending execution**
- Landscape + Light: **Pending execution**
- Landscape + Dark: **Pending execution**

## Appearance Matrix Evidence
- Portrait + Light: status=`Pending`, screenshot=`TBD`
- Portrait + Dark: status=`Pending`, screenshot=`TBD`
- Landscape + Light: status=`Pending`, screenshot=`TBD`
- Landscape + Dark: status=`Pending`, screenshot=`TBD`

## Accessibility
- VoiceOver core flow pass: **Pending execution**
- Dynamic Type critical content pass: **Pending execution**
- Non-color critical meaning pass: **Pending execution**

## Accessibility Evidence
- VoiceOver core flow pass: status=`Pending`, evidence=`TBD`
- Dynamic Type critical content pass: status=`Pending`, evidence=`TBD`
- Non-color critical meaning pass: status=`Pending`, evidence=`TBD`

## Defects
- P0:
  - Missing completed RC manual evidence for required release gates.
  - Migration recovery operational validation incomplete.
- P1:
  - Performance target measurements not yet recorded on target device.
  - Orientation and accessibility matrix evidence incomplete.
- P2:
  - None currently logged.

## Sign-off
- QA owner: `TBD`
- Date: `TBD`
- Go/No-Go: **NO-GO until all P0 closed**
