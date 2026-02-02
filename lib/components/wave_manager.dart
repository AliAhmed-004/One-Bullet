import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// Configuration for a single wave.
class WaveConfig {
  const WaveConfig({
    required this.waveNumber,
    required this.duration,
    required this.startSpeed,
    required this.endSpeed,
    this.deflectorSpawnInterval,
  });

  /// The wave number (1-indexed).
  final int waveNumber;

  /// Duration of this wave in seconds.
  final double duration;

  /// Bullet speed at the start of this wave.
  final double startSpeed;

  /// Bullet speed at the end of this wave (ramps up to this).
  final double endSpeed;

  /// Interval in seconds between deflector spawns (null = no spawning).
  final double? deflectorSpawnInterval;
}

/// Manages wave progression and bullet speed scaling.
///
/// Each wave has a duration and a speed range. The bullet speed
/// ramps smoothly from startSpeed to endSpeed during the wave.
class WaveManager extends Component {
  WaveManager({
    required this.onWaveChange,
    required this.onSpeedChange,
    required this.onSpawnDeflectors,
  });

  /// Callback when wave number changes.
  final void Function(int newWave, bool isWarning) onWaveChange;

  /// Callback when bullet speed should update.
  final void Function(double newSpeed) onSpeedChange;

  /// Callback to spawn deflectors at wave start.
  final void Function(int count) onSpawnDeflectors;

  /// Wave configurations (Wave 1-6 for testing).
  static const List<WaveConfig> waves = [
    // Wave 1: Warm-up phase, comfortable speed
    WaveConfig(waveNumber: 1, duration: 15.0, startSpeed: 350, endSpeed: 400),

    // Wave 2: Slight increase
    WaveConfig(waveNumber: 2, duration: 18.0, startSpeed: 400, endSpeed: 450, deflectorSpawnInterval: 5.0),

    // Wave 3: Getting challenging + deflectors start spawning every 5 seconds
    WaveConfig(
      waveNumber: 3,
      duration: 20.0,
      startSpeed: 450,
      endSpeed: 500,
      deflectorSpawnInterval: 8.0,
    ),

    // Wave 4: Fast 
    WaveConfig(
      waveNumber: 4,
      duration: 22.0,
      startSpeed: 500,
      endSpeed: 550,
      deflectorSpawnInterval: 5.0,
    ),

    // Wave 5: Very fast, deflectors every 5 seconds
    WaveConfig(
      waveNumber: 5,
      duration: 25.0,
      startSpeed: 550,
      endSpeed: 650,
      deflectorSpawnInterval: 5.0,
    ),

    // Wave 6: Maximum speed, deflectors every 3 seconds
    WaveConfig(
      waveNumber: 6,
      duration: double.infinity,
      startSpeed: 650,
      endSpeed: 720,
      deflectorSpawnInterval: 3.0,
    ),
  ];

  /// Current wave index (0-indexed).
  int _currentWaveIndex = 0;

  /// Time elapsed in the current wave.
  double _waveElapsed = 0;

  /// Time since last deflector spawn.
  double _deflectorSpawnTimer = 0;

  /// Whether the wave system is active (bullet has been fired).
  bool _isActive = false;

  /// Time before wave end to show warning flash (seconds).
  static const double warningTime = 3.0;

  /// Whether warning has been shown for current wave.
  bool _warningShown = false;

  /// Current wave number (1-indexed, for display).
  final ValueNotifier<int> currentWave = ValueNotifier(1);

  /// Current bullet speed.
  final ValueNotifier<double> currentSpeed = ValueNotifier(350);

  /// Whether a wave transition warning is active.
  final ValueNotifier<bool> isWarningActive = ValueNotifier(false);

  /// Gets the current wave configuration.
  WaveConfig get _currentConfig => waves[_currentWaveIndex];

  /// Starts the wave system (call when bullet is fired).
  void start() {
    _isActive = true;
    _currentWaveIndex = 0;
    _waveElapsed = 0;
    _deflectorSpawnTimer = 0;
    _warningShown = false;
    currentWave.value = 1;
    currentSpeed.value = _currentConfig.startSpeed;
    isWarningActive.value = false;

    // Notify initial wave
    onWaveChange(1, false);
    onSpeedChange(_currentConfig.startSpeed);
  }

  /// Resets the wave manager to initial state.
  void reset() {
    _isActive = false;
    _currentWaveIndex = 0;
    _waveElapsed = 0;
    _deflectorSpawnTimer = 0;
    _warningShown = false;
    currentWave.value = 1;
    currentSpeed.value = waves[0].startSpeed;
    isWarningActive.value = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isActive) return;

    _waveElapsed += dt;

    final config = _currentConfig;

    // Check for wave transition warning
    if (!_warningShown && config.duration != double.infinity) {
      final timeRemaining = config.duration - _waveElapsed;
      if (timeRemaining <= warningTime) {
        _warningShown = true;
        isWarningActive.value = true;
        onWaveChange(config.waveNumber, true);
      }
    }

    // Check for wave transition
    if (_waveElapsed >= config.duration &&
        _currentWaveIndex < waves.length - 1) {
      _advanceWave();
    }

    // Handle deflector spawning
    _updateDeflectorSpawning(dt);

    // Calculate and apply current speed
    _updateSpeed();
  }

  /// Handles interval-based deflector spawning.
  void _updateDeflectorSpawning(double dt) {
    final interval = _currentConfig.deflectorSpawnInterval;
    if (interval == null) return;

    _deflectorSpawnTimer += dt;

    if (_deflectorSpawnTimer >= interval) {
      _deflectorSpawnTimer -= interval;
      onSpawnDeflectors(1);
    }
  }

  /// Advances to the next wave.
  void _advanceWave() {
    _currentWaveIndex++;
    _waveElapsed = 0;
    _deflectorSpawnTimer = 0; // Reset deflector timer for new wave
    _warningShown = false;
    isWarningActive.value = false;
    currentWave.value = _currentConfig.waveNumber;
    onWaveChange(_currentConfig.waveNumber, false);
  }

  /// Updates the bullet speed based on wave progress.
  void _updateSpeed() {
    final config = _currentConfig;

    // Calculate progress through current wave (0.0 to 1.0)
    double progress;
    if (config.duration == double.infinity) {
      // Final wave: keep ramping slowly
      progress = (_waveElapsed / 60.0).clamp(0.0, 1.0);
    } else {
      progress = (_waveElapsed / config.duration).clamp(0.0, 1.0);
    }

    // Smooth easing for speed ramp (ease-in-out)
    final easedProgress = _easeInOutCubic(progress);

    // Interpolate speed
    final newSpeed =
        config.startSpeed +
        (config.endSpeed - config.startSpeed) * easedProgress;

    if ((newSpeed - currentSpeed.value).abs() > 0.5) {
      currentSpeed.value = newSpeed;
      onSpeedChange(newSpeed);
    }
  }

  /// Cubic ease-in-out function for smooth speed transitions.
  double _easeInOutCubic(double t) {
    return t < 0.5
        ? 4 * t * t * t
        : 1 - (-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2) / 2;
  }
}
