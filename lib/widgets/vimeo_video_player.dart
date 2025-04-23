import 'package:flutter/material.dart';
import 'package:vimeo_player_flutter/vimeo_player_flutter.dart';
 
class VimeoVideoPlayerPage extends StatefulWidget {
  final String videoUrl;
 
  const VimeoVideoPlayerPage({super.key, required this.videoUrl});
 
  @override
  VimeoVideoPlayerPageState createState() => VimeoVideoPlayerPageState();
}
 
class VimeoVideoPlayerPageState extends State<VimeoVideoPlayerPage> {
 
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(
          child: SizedBox(
            height: 250,
            child: VimeoPlayer(
              videoId: widget.videoUrl,
            ),
          ),
        ),
      ),
    );
  }
}