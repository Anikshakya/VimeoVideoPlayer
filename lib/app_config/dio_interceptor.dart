import 'dart:developer';
 
import 'package:dio/dio.dart';
 
class DioInterceptor extends Interceptor {
 
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    return handler.next(options);
  }
 
  @override
  Future<void> onResponse(response, ResponseInterceptorHandler handler) async {
    String apiPath = response.requestOptions.path;
    String successLog = 'SUCCESS PATH => [${response.requestOptions.method}] $apiPath';
    log('\x1B[32m$successLog\x1B[0m');
    return super.onResponse(response, handler);
  }
 
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    return handler.next(err);
  }
}