
import 'package:dio/dio.dart';
import 'package:vimyo/app_config/dio_interceptor.dart';
import 'package:vimyo/constant.dart';
 
final dio = Dio(
  BaseOptions(
    baseUrl: "https://api.vimeo.com/",
    receiveDataWhenStatusError: true,
    headers: {
        'Authorization': 'bearer $accessToken',
        'Content-Type': 'application/json',
    },
 
  ),
)..interceptors.add(DioInterceptor());
 
 
 
 