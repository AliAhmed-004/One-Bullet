import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String _boxName = 'settings';

  static const String _soundEnabledKey = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';

  static late Box _box;

  /// Reactive settings
  static final soundEnabled = ValueNotifier<bool>(true);
  static final hapticsEnabled = ValueNotifier<bool>(true);

  /// Initialize Hive + load saved values
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);

    soundEnabled.value = _box.get(_soundEnabledKey, defaultValue: true);
    hapticsEnabled.value = _box.get(_hapticsEnabledKey, defaultValue: true);
  }

  /// Save sound toggle
  static Future<void> setSound(bool value) async {
    soundEnabled.value = value;
    await _box.put(_soundEnabledKey, value);
  }

  /// Save haptics toggle
  static Future<void> setHaptics(bool value) async {
    hapticsEnabled.value = value;
    await _box.put(_hapticsEnabledKey, value);
  }
}
