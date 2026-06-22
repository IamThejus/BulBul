import 'dart:async';

import 'package:flutter/foundation.dart';

/// A tiny debouncer used by the search field: each [run] resets a timer, so the
/// supplied [action] only fires once the user pauses typing for [delay]. This
/// is what keeps Bulbul from hammering Open Library on every keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending action without firing it.
  void cancel() => _timer?.cancel();

  bool get isActive => _timer?.isActive ?? false;

  void dispose() => _timer?.cancel();
}
