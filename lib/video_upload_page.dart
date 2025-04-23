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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Upload Video', 
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600
          )
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Obx(() {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Video picker card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1
                    )
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.video_library, 
                          size: 48, 
                          color: Colors.grey[400]
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.selectedVideoPath.value == null 
                            ? "No video selected" 
                            : "Video ready for upload",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
                            await controller.pickVideo();
                            if (controller.selectedVideoPath.value != null) {
                              await _loadVideo(controller.selectedVideoPath.value!);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)
                            ),
                            side: BorderSide(
                              color: Colors.blue.shade400,
                              width: 1.5
                            )
                          ),
                          child: Text(
                            controller.selectedVideoPath.value == null 
                              ? "Select Video" 
                              : "Change Video",
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Video preview
                if (controller.selectedVideoPath.value != null && _videoController?.value.isInitialized == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying 
                                  ? Icons.pause 
                                  : Icons.play_arrow,
                                size: 48,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Form fields
                Text(
                  "Video Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700]
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2)
                      )
                    ]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Title",
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300)
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade400)
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14
                            ),
                          ),
                          style: const TextStyle(fontSize: 15),
                          onChanged: (val) => controller.title.value = val,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Description",
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300)
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade400)
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14
                            ),
                          ),
                          style: const TextStyle(fontSize: 15),
                          maxLines: 3,
                          onChanged: (val) => controller.description.value = val,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Upload button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value || controller.selectedVideoPath.value == null
                        ? null
                        : controller.uploadVideoToVimeo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isLoading.value)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Text(
                          controller.isLoading.value ? 'UPLOADING...' : 'UPLOAD VIDEO',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.5
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Upload progress
                if (controller.isLoading.value)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload progress',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: controller.uploadProgress.value,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue.shade600,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(controller.uploadProgress.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}