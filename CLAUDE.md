# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

iOS + watchOS phrase/translation app (German↔English vocabulary "wordbooks"). Built with SwiftUI and The Composable Architecture (TCA). Bundle id `co.lithobyte.Wordbook`.

## Build & test

Xcode project: `Wordbook.xcodeproj` (no workspace). Targets:
- `Wordbook` — iOS app (deployment target 17.0)
- `WordbookAW Watch App` — paired watchOS app
- `WordbookWidgetExtension` — home-screen widget
- `ComplicationExtension` — watch complication
- `WordbookTests`, `WordbookUITests`, `WordbookAW Watch AppTests`, `WordbookAW Watch AppUITests`

Build / test from CLI (replace destination as needed):

```
xcodebuild -project Wordbook.xcodeproj -scheme Wordbook -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1' -skipMacroValidation build
xcodebuild -project Wordbook.xcodeproj -scheme Wordbook -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1' -skipMacroValidation test
```

`-skipMacroValidation` is required from the CLI — TCA / swift-syntax macro plugins aren't trusted unless you've opened the project in Xcode and accepted the prompts. Always invoke with `-scheme` (not `-target`); per-target builds don't resolve the SwiftPM graph correctly here.

Single test: append `-only-testing:WordbookTests/LoginTests/testExample`.

## Dependencies

SwiftPM (resolved by Xcode):
- `swift-composable-architecture` — pinned to branch `observation-beta` (uses `@ObservableState`, `@Reducer`, `@Presents`, `BindableAction`, `_printChanges()`).
- `funnet` (LithoByte) — pinned to branch `feature/es/async`. Provides `FunNetCore`, `FunNetTCA`, `FunNetErrorHandling` for networking + the `NetCallReducer` used inside `Env`.

Both are tracked by branch, not version — be aware that running package updates can pull breaking changes.

## Architecture

Standard TCA: every screen has a `*Reducer.swift` (state + actions + body) and a `*View.swift` consuming `StoreOf<Reducer>`. Composition uses `Scope`, `ifLet(\.$presented, action: \.path)`, and `BindingReducer`.

Important pieces:

- **`WordbookApp.swift`** — app entry. Currently shows `AddableListView` directly (auth flow reducers exist — `Splash`, `Landing`, `Login`, `SignUp`, `ForgotPassword`, `ResetPassword` — but are commented out of the main scene).
- **`AddableListReducer` (`Wordbook/Phrases/`)** — the generic list-with-add/edit/details/search/sort screen. Parameterized over `phraseToItemState` and `phraseToSearchableString` closures so it can host any list of `Phrase`-shaped data. This is the current root view.
- **`Env.swift`** — global `Current = Env(...)` singleton holds `URLSession`, base URL, and snake_case JSON coders. `netState(from:)` builds `NetCallReducer.State` for API calls. Replace `baseUrl` to point at a real backend (currently a placeholder Heroku URL).
- **Persistence** — `loadData` / `save` / `saveUnique` in `Wordbook/Old/PhraseListReducer.swift` write `[Phrase]` to `UserDefaults` keyed by string (default `"phrases"`). The `Wordbook/Old/` directory still contains live, used code despite the name — don't assume "Old" means dead.
- **Watch sync** — `WatchConnectivityClient` (TCA `DependencyKey`) wraps `WCSession` and exposes an `AsyncThrowingStream` of incoming messages. `AddableListReducer` ships `state.allPhrases` to the paired device on `didAppear`/`saveNew`/`saveEdit`, and re-loads from UserDefaults when the watch pushes phrases back. The `WordbookAW Watch App` target has its own mirror reducers (`PhrasesReducer`, `AddPhraseReducer`).
- **`SpeechClient`** — `DependencyKey` wrapping `SFSpeechRecognizer` + `AVAudioEngine`, exposed as an `AsyncThrowingStream<String, Error>` of partial transcriptions. Locale switches via the static `SpeechClient.language` (`.english` / `.german`). `previewValue` simulates streaming text for SwiftUI previews.
- **Models** — `Phrase` (`id` is the source-language string, `translation` is the target; equality + hash on `id` only). `Worterbuch` is a named collection of phrases, identified by a `key` string used as the UserDefaults bucket.

## Conventions worth knowing

- TCA `_printChanges()` is left wired up on several reducers in `WordbookApp.swift` — keep it off in production builds you ship.
- `Phrase` equality ignores `translation` and `createdAt`. Code that dedupes via `Set<Phrase>` or `IdentifiedArray` will silently drop edits to those fields — use explicit replace-by-index (see `AddableListReducer.saveEdit`) when updating.
- API JSON uses `convertToSnakeCase` / `convertFromSnakeCase` (see `apiEncoder()` / `apiDecoder()` in `Env.swift`). Don't hand-roll `CodingKeys` for snake_case mapping.
- Mixed CasePathing styles in the codebase: newer reducers use key-path syntax (`action: \.add`), older ones use `/Action.add`. Both work with the pinned TCA branch.
