import 'package:flutter/material.dart';
import 'package:vimyo/widgets/custom_video_player.dart';

class VideoDetailsPage extends StatefulWidget {
  final String videoTitle;
  final dynamic videoFiles;
  const VideoDetailsPage({
    super.key,
    required this.videoTitle,
    this.videoFiles,
  });

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  bool _showFullDescription = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomVideoPlayer(
              videoTitle: widget.videoTitle,
              files: widget.videoFiles,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title
                  Text(
                    widget.videoTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
      
                  /// Views and date
                  const Text(
                    '1.2M views · 2 weeks ago',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
      
                  /// Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _ActionButton(icon: Icons.thumb_up_alt_outlined, label: '12K'),
                      _ActionButton(icon: Icons.thumb_down_alt_outlined, label: 'Dislike'),
                      _ActionButton(icon: Icons.share, label: 'Share'),
                      _ActionButton(icon: Icons.download, label: 'Save'),
                    ],
                  ),
                  const Divider(height: 30),
      
                  /// Channel info
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Channel Name', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('1.5M subscribers', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'SUBSCRIBE',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
      
                  /// Description
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFullDescription = !_showFullDescription;
                      });
                    },
                    child: Text(
                      _showFullDescription
                          ? 'This is the full description of the video. It contains more information, links, and timestamps to help the viewer.'
                          : 'This is the short description of the video...',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
