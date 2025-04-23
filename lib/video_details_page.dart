import 'package:flutter/material.dart';
import 'package:vimyo/widgets/custom_video_player.dart';

class VideoDetailsPage extends StatefulWidget {
  final String videoTitle;
  final dynamic videoFiles;
  const VideoDetailsPage({super.key, required this.videoTitle, this.videoFiles});

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          VimeoVideoPlayer(
            // aspectRatio: 0.5,
            videoTitle: widget.videoTitle,
            files: widget.videoFiles,
          ),
          Container(
            color: Colors.red,
            height: 900,
          )
        ],
      ),
    );
  }
}