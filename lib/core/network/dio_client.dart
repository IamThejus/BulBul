import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../error/app_exception.dart';

/// Thin factory + interceptor wrapper around [Dio]. We keep a single shared
/// instance (created in the DI layer) configured with sane timeouts, a UA the
/// public APIs ask for, and an interceptor that converts every transport error
/// into a normalized [AppException] before it leaves the network layer.
class DioClient {
  DioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'User-Agent': ApiConstants.userAgent,
          'Accept': 'application/json',
        },
        // We validate status codes ourselves so 3xx/4xx surface as bad responses.
        validateStatus: (code) => code != null && code >= 200 && code < 300,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          // Re-wrap as AppException so callers can `catch (AppException)`.
          final mapped = AppException.fromDio(e);
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: mapped,
              type: e.type,
              response: e.response,
            ),
          );
        },
      ),
    );

    return dio;
  }
}

/// Convenience extension so services can run a request and get back a normalized
/// [AppException] on failure without repeating try/catch boilerplate everywhere.
extension DioSafeCall on Dio {
  Future<Response<T>> safe<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final err = e.error;
      throw err is AppException ? err : AppException.fromDio(e);
    } catch (e) {
      throw AppException('Unexpected error: $e', cause: e);
    }
  }
}
