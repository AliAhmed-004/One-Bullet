# One Bullet

> Fire once. Dodge forever.

One Bullet is a minimalist 2D survival game built with Flutter and Flame. You fire a single bullet, then spend the rest of the run surviving the chaos it creates as it bounces, speeds up, and turns the arena against you.

## Highlights

- One-shot survival loop with infinite ricochet physics
- Progressive wave system that increases speed and pressure over time
- Destructible deflectors that reshape each run
- Local high-score tracking and restart-friendly game flow
- Support for Android, iOS, desktop, and web

## Gameplay

1. Aim with the rotating indicator.
2. Fire the bullet once.
3. Keep moving while it bounces around the arena.
4. Survive as long as possible before it catches you.

## Tech Stack

- Flutter
- Flame
- Hive for local score storage
- flame_audio for sound effects
- games_services for Play Games integration
- google_mobile_ads for AdMob integration
- connectivity_plus and vibration for platform-aware features

## Getting Started

### Prerequisites

- Flutter SDK 3.10+ with the matching platform toolchains installed
- Android Studio for Android builds
- Xcode for iOS and macOS builds

### Run Locally

```bash
flutter pub get
flutter run
```

### Useful Build Commands

```bash
flutter build apk --release
flutter build ios --release
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build web
```

## Platform Notes

- Android release signing uses local files under `android/key.properties` and a keystore under `android/keystore/`; keep both out of Git.
- iOS includes AdMob and tracking-related configuration in `ios/Runner/Info.plist`.
- Web metadata in `web/index.html` should be reviewed before deployment so the page title and description match the final release.
- High scores are stored locally on the device.

## Privacy

Core gameplay does not require a backend account or remote profile. If ad or platform service features are enabled in a build, document the relevant store disclosures and permission prompts before release.

## Roadmap

- Additional game modes
- Global leaderboards
- Achievement system
- Cosmetic unlocks
- Daily challenges

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
