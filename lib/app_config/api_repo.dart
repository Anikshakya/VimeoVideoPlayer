import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:vimyo/app_config/dio_client.dart';

class ApiRepo{
  static apiPost(url, params) async {
    try {
      var response = await dio.post(url, data: params);
      if (response.statusCode == 200) {
        return response.data;
      }
      else {
        return null;
      }
    } on DioException  catch (e) {
      log(e.toString());
    } catch (e) {
      log(e.toString());
    }
  }
 
  static apiGet(url) async {
    try {
      var response = await dio.get(url);
      return response.data;
    } on DioException  catch (e) {
      log(e.toString());
    } catch (e) {
      log(e.toString());
    }
  }
 
  // static apiPut(apiPath,queryParameters,[apiName]) async {
  //   final AppController appCon = Get.find();
  //   try {
  //     var response = await dio.put(apiPath, data: queryParameters);
  //     if (response.statusCode == 200) {
  //       return response.data;
  //     } else {
  //       return null;
  //     }
  //   } on DioException  catch (e) {
  //     if(e.response != null) {
  //       if(e.response!.statusCode != 503) {
  //         if(e.response!.data['code'] == 423) {
  //           if(e.response!.data['errors'] != null){
  //             if(e.response!.data['errors'] is Map) {
  //               e.response!.data['errors'].forEach((key, value) {
  //                 showToast(
  //                  isSuccess: false,
  //                  message: e.response!.data['errors'][key][0]
  //                 );
  //               });
  //             } else {
  //               showErrorDialog(e.response!.data['message']);
  //             }
  //           }
  //         } else {
  //           if(e.response!.data['errors'] != null){
  //             if(e.response!.data['errors'] is Map) {
  //               e.response!.data['errors'].forEach((key, value) {
  //                 showToast(
  //                  isSuccess: false,
  //                   message : e.response!.data['errors'][key][0].toString()
  //                 );
  //               });
  //             } else {
  //               showToast(
  //                isSuccess: false,
  //                 message : e.response!.data['message'].toString()
  //               );
  //             }
  //           } else {
  //             if(e.response!.data['message'] is Map) {
  //               e.response!.data['message'].forEach((key, value) {
  //                 showToast(
  //                  isSuccess: false,
  //                   message : e.response!.data['message'][key][0]
  //                 );
  //               });
  //             } else {
  //               showToast(
  //                isSuccess: false,
  //                 message : e.response!.data['message']
  //               );
  //             }
  //           }
  //         }
  //       }
  //       appCon.online.value = true;
  //     } else {
  //       appCon.online.value = false;
  //     }
  //   } catch (e) {
  //     log(e.toString());
  //   }
  // }
 
  static apiPatch(String apiPath, dynamic queryParameters, {Options? options}) async {
    try {
      var response = await dio.patch(apiPath, data: queryParameters,options: options,);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        log('${response.data}');
      }
    } on DioException catch (e) {
      log('DioException: ${e.toString()}');
    } catch (e) {
      log('Exception: ${e.toString()}');
    }
  }
 
  // static apiDelete(apiPath,[apiName]) async {
  //   final AppController appCon = Get.find();
  //   try {
  //     var response = await dio.delete(apiPath);
  //     if (response.statusCode == 200) {
  //       appCon.online.value = true;
  //       return response.data;
  //     } else {
  //       return null;
  //     }
  //   } on DioException  catch (e) {
  //     if(e.response != null) {
  //       if(e.response!.statusCode != 503) {
  //         if(e.response!.data['code'] == 423) {
  //           if(e.response!.data['errors'] != null){
  //             if(e.response!.data['errors'] is Map) {
  //               e.response!.data['errors'].forEach((key, value) {
  //                 showToast(
  //                  isSuccess: false,
  //                  message: e.response!.data['errors'][key][0]
  //                 );
  //               });
  //             } else {
  //               showErrorDialog(e.response!.data['message']);
  //             }
  //           }
  //         } else {
  //           if(e.response!.data['errors'] != null){
  //             if(e.response!.data['errors'] is Map) {
  //               e.response!.data['errors'].forEach((key, value) {
  //                 showToast(
  //                  isSuccess: false,
  //                   message : e.response!.data['errors'][key][0].toString()
  //                 );
  //               });
  //             } else {
  //               showToast(
  //                isSuccess: false,
  //                 message : e.response!.data['message'].toString()
  //               );
  //             }
  //           } else {
  //             if(e.response!.data['message'] is Map) {
  //               e.response!.data['message'].forEach((key, value) {
  //                 showToast(
  //                  isSuccess: false,
  //                   message : e.response!.data['message'][key][0]
  //                 );
  //               });
  //             } else {
  //               showToast(
  //                isSuccess: false,
  //                 message : e.response!.data['message']
  //               );
  //             }
  //           }
  //         }
  //       }
  //       appCon.online.value = true;
  //     } else {
  //       appCon.online.value = false;
  //     }
  //   } catch (e) {
  //     log(e.toString());
  //   }
  // }
}