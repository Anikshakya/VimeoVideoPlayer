import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimyo/controller/video_controller.dart';
import 'package:video_player/video_player.dart';

class VideoUploaderPage extends StatefulWidget {
  const VideoUploaderPage({super.key});

  @override
  State<VideoUploaderPage> createState() => _VideoUploaderPageState();
}

class _VideoUploaderPageState extends State<VideoUploaderPage> {
  final VideoController controller = Get.put(VideoController());
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController?.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await controller.pickVideo();
                    if (controller.selectedVideoPath.value != null) {
                      await _loadVideo(controller.selectedVideoPath.value!);
                    }
                  },
                  child: const Text("Pick Video"),
                ),
                const SizedBox(height: 16),
                if (controller.selectedVideoPath.value != null && _videoController?.value.isInitialized == true)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: "Title", filled: true),
                  onChanged: (val) => controller.title.value = val,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: "Description", filled: true),
                  maxLines: 3,
                  onChanged: (val) => controller.description.value = val,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: controller.isLoading.value || controller.selectedVideoPath.value == null
                      ? null
                      : controller.uploadVideoToVimeo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('UPLOAD VIDEO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                if (controller.isLoading.value)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Uploading...', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: controller.uploadProgress.value,
                        backgroundColor: Colors.grey[800],
                        color: Colors.red,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(controller.uploadProgress.value * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                else
                  const Text('No upload in progress', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
