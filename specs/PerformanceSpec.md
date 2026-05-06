# Performance Specification

## 1. Purpose
Define measurable performance targets and validation strategy across gameplay, persistence, and startup.

---

## 2. MVP Performance Targets
- Cold launch to usable UI: under 2 seconds on modern iPhone
- Score submit to UI confirmation: under 100 ms perceived
- Resume in-progress match: under 500 ms for typical event volume
- History list first paint: under 400 ms for typical local data

---

## 3. Hot Path Requirements
- Rule engines are pure and deterministic, no blocking IO
- Event writes are batched/atomic per turn
- History list uses summary fields and lazy loading
- Avoid heavy recompute on main thread

---

## 4. Instrumentation
- Add timing metrics for:
  - `submitTurn`
  - `resumeMatch`
  - `completeMatch`
  - `historyLoad`
- Track p50/p95 in debug diagnostics

---

## 5. Scalability Assumptions
- Support multi-year local history without visible lag
- Snapshot + event replay strategy must keep resume stable as data grows
- Aggregate caches can be rebuilt safely if stale

---

## 6. Testing
- Performance tests for scoring loops
- Persistence benchmarks with synthetic long histories
- Memory checks during extended match sessions

---

## 7. Future Targets
- Watch command round-trip responsiveness targets
- Vision pipeline frame processing budget
- Online latency and jitter budgets by region
