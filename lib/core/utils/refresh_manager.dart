import 'package:get/get.dart';



class RefreshManager extends GetxService {
  final Map<String, DateTime> _lastRun = {};
  final Set<String> _inFlight = <String>{};

  
  Future<void> run({
    required String key,
    required Duration ttl,
    required Future<void> Function() action,
    bool force = false,
  }) async {
    
    if (_inFlight.contains(key)) return;
    final now = DateTime.now();
    final last = _lastRun[key];
    final isFresh = last != null && now.difference(last) < ttl;
    if (!force && isFresh) return;
    _inFlight.add(key);
    try {
      await action();
      _lastRun[key] = DateTime.now();
    } finally {
      _inFlight.remove(key);
    }
  }

  void invalidate(String key) => _lastRun.remove(key);
  void invalidatePrefix(String prefix) {
    final toRemove = _lastRun.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in toRemove) {
      _lastRun.remove(k);
    }
  }
}
