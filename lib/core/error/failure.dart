import 'package:equatable/equatable.dart';

import 'app_exception.dart';

/// A `Failure` is the value-typed, equatable representation of an error that
/// flows through providers/UI. Unlike [AppException] (thrown), [Failure] is
/// returned/held in state, which keeps widgets free of try/catch and makes
/// error states comparable for Riverpod rebuild optimization.
class Failure extends Equatable {
  const Failure(this.message, {this.kind = AppErrorKind.unknown});

  final String message;
  final AppErrorKind kind;

  bool get isOffline => kind == AppErrorKind.network;

  factory Failure.from(Object error) {
    if (error is AppException) {
      return Failure(error.message, kind: error.kind);
    }
    return Failure('Something went wrong. Please try again.', kind: AppErrorKind.unknown);
  }

  @override
  List<Object?> get props => [message, kind];
}
