import 'package:dio/dio.dart';

/// A normalized exception type. Services translate raw [DioException]s and other
/// low-level errors into an [AppException] carrying a human-friendly [message]
/// and a [kind] the UI can branch on (e.g. show an offline view + retry).
class AppException implements Exception {
  const AppException(this.message, {this.kind = AppErrorKind.unknown, this.cause});

  final String message;
  final AppErrorKind kind;
  final Object? cause;

  bool get isOffline => kind == AppErrorKind.network;

  @override
  String toString() => 'AppException($kind): $message';

  /// Maps a [DioException] onto a friendly [AppException]. Keeps all the
  /// network-failure branching in one tested place.
  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          'The connection timed out. Check your network and try again.',
          kind: AppErrorKind.timeout,
        );
      case DioExceptionType.connectionError:
        return const AppException(
          "You're offline. Connect to the internet and try again.",
          kind: AppErrorKind.network,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) {
          return const AppException(
            "We couldn't find that — it may no longer be available.",
            kind: AppErrorKind.notFound,
          );
        }
        return AppException(
          'The server responded with an error${code != null ? ' ($code)' : ''}.',
          kind: AppErrorKind.server,
        );
      case DioExceptionType.cancel:
        return const AppException('Request cancelled.', kind: AppErrorKind.cancelled);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (e.error is AppException) return e.error as AppException;
        return AppException(
          'Something went wrong. Please try again.',
          kind: AppErrorKind.unknown,
          cause: e,
        );
    }
  }
}

enum AppErrorKind { network, timeout, server, notFound, cancelled, unknown }
