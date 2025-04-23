import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimyo/app_config/api_repo.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class VideoController extends GetxController {
  var isLoading = false.obs;
  var isVideoListPaginationLoading = false.obs;
  var videos = [].obs;
  var currentPage = 1.obs;

  var uploadProgress = 0.0.obs; // ⬅️ Observable progress
  final scrollController = ScrollController();

  var selectedVideoPath = RxnString();
  var title = ''.obs;
  var description = ''.obs;

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      selectedVideoPath.value = result.files.single.path;
    }
  }

  Future<void> uploadVideoToVimeo() async {
    if (selectedVideoPath.value == null) return;

    try {
      final file = File(selectedVideoPath.value!);
      final fileSize = await file.length();

      isLoading(true);
      uploadProgress.value = 0.0;

      final createUploadResponse = await ApiRepo.apiPost(
        'me/videos',
        {
          "upload": {
            "approach": "tus",
            "size": "$fileSize"
          },
          "name": title.value,
          "description": description.value
        },
      );

      final uploadLink = createUploadResponse?['upload']?['upload_link'];
      if (uploadLink == null) throw Exception('Upload link not found');

      final bytes = file.readAsBytesSync();
      int total = bytes.length;
      int sent = 0;
      final chunkSize = 1024 * 1024;

      while (sent < total) {
        final end = (sent + chunkSize < total) ? sent + chunkSize : total;
        final chunk = bytes.sublist(sent, end);

        final options = Options(
          headers: {
            'Content-Type': 'application/offset+octet-stream',
            'Tus-Resumable': '1.0.0',
            'Upload-Offset': '$sent',
            'Authorization': 'Bearer YOUR_VIMEO_ACCESS_TOKEN',
          },
        );

        await Dio().patch(uploadLink, data: chunk, options: options);
        sent = end;
        uploadProgress.value = sent / total;
      }

      Get.snackbar('Success', 'Video uploaded!',
          snackPosition: SnackPosition.BOTTOM);

      selectedVideoPath.value = null;
      title.value = '';
      description.value = '';
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
      debugPrint(e.toString());
    } finally {
      isLoading(false);
      uploadProgress.value = 0.0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    Future.delayed(Duration(milliseconds: 100), () {
      fetchVideos();
      setupScrollController();
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void setupScrollController() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200 &&
          !isVideoListPaginationLoading.value &&
          !isLoading.value) {
        loadMoreVideos();
      }
    });
  }

  Future<void> fetchVideos({int page = 1}) async {
    try {
      if (page == 1) isLoading(true);
      final response = await ApiRepo.apiGet('me/videos?per_page=10&page=$page');

      if (response != null) {
        if (page == 1) {
          videos.assignAll(response['data']);
        } else {
          videos.addAll(response['data']);
        }
        currentPage.value = page;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load videos', snackPosition: SnackPosition.BOTTOM);
      debugPrint(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadMoreVideos() async {
    try {
      isVideoListPaginationLoading(true);
      await fetchVideos(page: currentPage.value + 1);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isVideoListPaginationLoading(false);
    }
  }

  Future<void> refreshVideos() async {
    currentPage.value = 1;
    await fetchVideos(page: 1);
  }}
