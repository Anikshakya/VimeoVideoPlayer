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
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
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
            itemCount: videoController.videos.length + 1,
            itemBuilder: (context, index) {
              if (index < videoController.videos.length) {
                final video = videoController.videos[index];
                return _buildVideoItem(video, index);
              } else {
                return _buildLoader();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildVideoItem(dynamic video, int index) {
    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                video['pictures']?['sizes']?.last['link'] ?? '',
                width: 150,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 150,
                    height: 90,
                    color: Colors.grey.shade300,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            /// Video Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['name'] ?? 'No title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'My Channel • ${video['stats']?['plays'] ?? 0} views',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(Duration(seconds: video['duration'] ?? 0)),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
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
