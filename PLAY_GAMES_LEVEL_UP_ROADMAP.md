# One Bullet – Play Games Level Up Integration Guide

This document outlines a structured roadmap to complete the **Play Games Level Up Milestone: Unlock Player Milestones**.

It is divided into two main parts:

1. Implementing Achievements with Play Games Services (PGS)
2. Implementing Play Games Sidekick

The goal is to upgrade local achievements into fully synchronized Play Games achievements while meeting Google’s Level Up compliance requirements.

---

# PART 1 — Implementing Achievements with Play Games Services (PGS)

## 1. Overview

Play Games Services (PGS) provides:

* Player authentication
* Achievements
* Leaderboards
* Gamer XP progression
* Ecosystem visibility in Play Games

To meet the Level Up milestone, achievements must:

* Be defined in Play Console
* Be unlocked through PGS APIs
* Be visible in the Play Games ecosystem

---

## 2. Prerequisites

### 2.1 Play Console Setup

1. Enable Play Games Services for the game.
2. Create a Play Games project (linked to your app).
3. Configure SHA-1 signing certificate.
4. Add test accounts.

### 2.2 SDK Requirement

* Use Play Games Services v2 (latest SDK only).
* Ensure no deprecated v1 APIs are present.

---

## 3. Step-by-Step Implementation

### Step 1 — Authentication Flow

Authentication must be implemented before achievements can work.

Required Flow:

1. Attempt silent sign-in on app launch.
2. If silent sign-in fails, show manual sign-in option.
3. Store authentication state locally.
4. Gracefully handle offline mode.

Best Practice:

* Do NOT block gameplay if sign-in fails.
* Keep your existing offline-first architecture.

---

### Step 2 — Create Achievements in Play Console

Requirements:

* Minimum 10 achievements.
* At least 4 achievable within 1 hour of gameplay.

For each achievement define:

* Name
* Description
* Icon (512x512 recommended)
* Type (Standard or Incremental)
* Hidden/Visible state

After creation:

* Download achievement IDs.
* Store them in a centralized constants file.

---

### Step 3 — Map Local Achievements to PGS

You already have local achievement tracking.

Refactor the system to:

1. Keep local tracking logic.
2. On unlock, call PGS unlock API.
3. If offline, queue sync.
4. Sync when connection and authentication are available.

Architecture Suggestion:

Create an AchievementSyncService:

* unlockLocal(id)
* unlockRemote(id)
* syncPending()

This preserves offline reliability while adding cloud syncing.

---

### Step 4 — Unlock Achievements via SDK

When achievement conditions are met:

* Call unlock() for standard achievements.
* Call increment() for incremental achievements.

Ensure:

* Calls are idempotent.
* Duplicate unlock attempts do not crash.

---

### Step 5 — Testing

Use Play Console Test Accounts:

* Verify unlock appears in Play Games app.
* Confirm XP is awarded.
* Validate incremental achievements.
* Test offline → reconnect sync.

---

## 4. Recommended Achievement Structure for One Bullet (Get Suggestions)

### Early (Fast Unlocks)

* Survive 30 seconds
* Break 10 deflectors
* 

### Mid-Tier

* Survive 3 minutes

### Long-Term

* Survive 10 minutes
* Play 100 matches

Balance short-term dopamine with long-term mastery goals.

---

## 5. Compliance Checklist (Achievements)

* [ ] PGS v2 integrated
* [ ] Authentication working
* [ ] Minimum 10 achievements created
* [ ] At least 4 <1 hour achievements
* [ ] Remote unlock calls implemented
* [ ] Offline fallback logic present
* [ ] Verified in Play Games app

============================================================

# PART 2 — Implementing Play Games Sidekick

## 1. Overview

Play Games Sidekick is an in-game overlay experience provided by Google.

It allows players to:

* View achievements
* Track progress
* Access offers
* View gamer profile

This is required for the Level Up milestone.

---

## 2. Integration Concept

Sidekick is not a custom UI.
It is a Google-provided overlay.

Your responsibility:

* Enable overlay functionality.
* Provide access point in-game.
* Ensure it launches properly.

---

## 3. Implementation Steps

### Step 1 — Confirm PGS Integration

Sidekick depends on:

* Working authentication
* Proper PGS configuration

Do NOT implement Sidekick before authentication works.

---

### Step 2 — Enable Overlay Support

Using PGS v2 APIs:

* Ensure Play Games UI components are enabled.
* Add call to open achievements UI or Sidekick overlay.

Example UX Placement:

* “Achievements” button in pause menu
* Trophy icon on main menu

---

### Step 3 — UX Best Practices

* Do not auto-launch on startup.
* Do not interrupt gameplay.
* Provide intentional access.
* Keep your custom achievement popups.

Sidekick complements your UI — it does not replace it.

---

### Step 4 — Testing Sidekick

Verify:

* Overlay opens without crashing.
* Achievements display correctly.
* Player profile loads.
* Works across different Android versions.

Test on:

* Fresh install
* Returning player
* Offline launch → online reconnect

---

## 4. Compliance Checklist (Sidekick)

* [ ] Authentication implemented
* [ ] Overlay accessible from in-game UI
* [ ] Achievements visible inside overlay
* [ ] No forced sign-in
* [ ] No crashes during open/close

============================================================

# Final Architecture Recommendation

Maintain your offline-first philosophy.

Suggested layered approach:

Game Logic
↓
Local Achievement Service
↓
PGS Sync Adapter
↓
Play Games Services

This keeps:

* Reliability
* Testability
* Scalability

Later expansion options:

* Add leaderboards
* Add cloud save
* Add seasonal events tied to PGS

============================================================

# Milestone Completion Summary

To unlock "Player Milestones":

You must:

1. Implement Achievements with PGS.
2. Implement Play Games Sidekick overlay.
3. Pass testing verification in Play Console.

After completion:

* Players earn official Play Games XP.
* Achievements become cross-device.
* Game gains ecosystem credibility.

End of document.
