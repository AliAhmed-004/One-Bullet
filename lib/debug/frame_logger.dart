
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in frame timing logger for profiling on a device.
///
/// Enable with `--dart-define=PERF_LOG=true` (use a `--profile` build).
/// Every few seconds it prints a line tagged `PERF` with the build and raster
/// times of the frames since the last report:
///
///   adb logcat -s flutter | grep PERF
class FrameLogger {
  FrameLogger._();

  static const bool enabled = bool.fromEnvironment('PERF_LOG');

  /// With PERF_GOD the player cannot die, so long late-wave runs can be timed.
  static const bool godMode = enabled && bool.fromEnvironment('PERF_GOD');

  /// PERF_NOSOUND skips all SFX; PERF_NOBLEND drops additive blending and the bullet halo.
  static const bool noSound = enabled && bool.fromEnvironment('PERF_NOSOUND');
  static const bool noBlend = enabled && bool.fromEnvironment('PERF_NOBLEND');

  /// Extra text (wave, deflector count) appended to each report.
  static String Function()? context;

  static const Duration _interval = Duration(seconds: 5);

  static final List<FrameTiming> _frames = [];
  static DateTime _lastReport = DateTime.now();

  static void install() {
    if (!enabled) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);

    final now = DateTime.now();
    if (now.difference(_lastReport) < _interval) return;
    _lastReport = now;

    final build = _sortedMs(_frames.map((f) => f.buildDuration));
    final raster = _sortedMs(_frames.map((f) => f.rasterDuration));
    final total = _sortedMs(_frames.map((f) => f.totalSpan));
    final n = _frames.length;
    final fps = n / _interval.inSeconds;
    final slow = total.where((t) => t > 16.7).length;
    final bad = total.where((t) => t > 33.4).length;

    debugPrint(
      'PERF frames=$n fps=${fps.toStringAsFixed(0)} '
      'build(p50/p99/max)=${_fmt(build)} raster=${_fmt(raster)} '
      'total=${_fmt(total)} >16ms=$slow >33ms=$bad ${context?.call() ?? ''}',
    );
    _frames.clear();
  }

  static List<double> _sortedMs(Iterable<Duration> ds) =>
      ds.map((d) => d.inMicroseconds / 1000).toList()..sort();

  static String _fmt(List<double> v) {
    if (v.isEmpty) return '-';
    String f(double x) => x.toStringAsFixed(1);
    return '${f(v[v.length ~/ 2])}/${f(v[(v.length * 0.99).floor().clamp(0, v.length - 1)])}/${f(v.last)}';
  }
}
