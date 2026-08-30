import 'dart:async';
import 'package:flutter/material.dart';

class InactivityLockService extends ChangeNotifier with WidgetsBindingObserver {
  static const _timeout = Duration(minutes: 2);

  Timer? _timer;
  bool _locked = false;

  bool get isLocked => _locked;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  void recordActivity() {
    if (_locked) return;
    _resetTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lock();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, _lock);
  }

  void _lock() {
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    _resetTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final inactivityLock = InactivityLockService();
