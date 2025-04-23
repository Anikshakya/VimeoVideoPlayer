import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimyo/controller/video_controller.dart';
import 'package:vimyo/video_details_page.dart';
import 'package:vimyo/video_upload_page.dart';
import 'package:vimyo/widgets/vimeo_video_player.dart';

class VideoListPage extends StatelessWidget {
  VideoListPage({super.key});

  final VideoController videoController = Get.put(VideoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Videos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Get.to(() => VideoUploaderPage());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: videoController.refreshVideos,
          ),
        ],
      ),
      body: Obx(() {
        if (videoController.isLoading.value && videoController.videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: videoController.refreshVideos,
          child: ListView.builder(
            controller: videoController.scrollController,
            itemCount: videoController.videos.length + 1, // +1 for loader
            itemBuilder: (context, index) {
              if (index < videoController.videos.length) {
                final video = videoController.videos[index];
                return _buildVideoItem(video, index);
              } else {
                return _buildLoader(); // Loader for pagination
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVideoItem(dynamic video, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final videoFiles = videoController.videos[index]["files"];
          if (videoFiles != null) {
            Get.to(() => VideoDetailsPage(
              videoTitle: video['name'] ?? "Test",
              videoFiles: videoFiles,
            ));
          } else {
            Get.to(() => VimeoVideoPlayerPage(
              videoUrl: video['uri'].split('/').last,
            ));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail with play button overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        video['pictures']?['sizes']?.last['link'] ?? '',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 60,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),

              // Video Info Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['name'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${video['stats']?['plays'] ?? 0} plays',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const Spacer(),
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(Duration(seconds: video['duration'] ?? 0)),
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Obx(() => Visibility(
          visible: videoController.isVideoListPaginationLoading.isTrue,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
