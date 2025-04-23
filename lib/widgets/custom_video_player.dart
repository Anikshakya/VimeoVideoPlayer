import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class CustomVideoPlayer extends StatefulWidget {
  final List<dynamic> files;
  final String videoTitle;
  final double? aspectRatio;
  final BoxFit fit;
  final Color progressColor;
  final Color bufferedColor;
  final Color backgroundColor;

  const CustomVideoPlayer({
    super.key,
    required this.files,
    required this.videoTitle,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.progressColor = Colors.red,
    this.bufferedColor = Colors.grey,
    this.backgroundColor = Colors.black,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isFullScreen = false;
  bool _isMuted = false;
  bool _isBuffering = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDragging = false;
  Map<String, dynamic>? _currentQuality;
  double _playbackSpeed = 1.0;
  bool _doubleTapSeeking = false;
  Timer? _doubleTapTimer;
  bool _showDoubleTapIndicator = false;
  Duration _doubleTapSeekDuration = Duration.zero;
  bool _isDoubleTapRight = false;
  double _seekPosition = 0.0;
  bool _showSeekPreview = false;
  String _seekPreviewTime = '0:00';

  final List<double> _playbackSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  final double _seekDurationSeconds = 10.0;
  List<Map<String, dynamic>> _availableQualities = [];

  @override
  void initState() {
    super.initState();
    _parseQualities();
    _initializeVideo();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _parseQualities() {
    _availableQualities = widget.files
        .where((file) => file['type']?.startsWith('video/') ?? false)
        .map((file) => file as Map<String, dynamic>)
        .toList();

    _availableQualities.sort((a, b) => (b['width'] ?? 0).compareTo(a['width'] ?? 0));

    if (_availableQualities.isNotEmpty) {
      _currentQuality = _availableQualities.first;
    }
  }

  String _getQualityLabel(Map<String, dynamic> quality) {
    return quality['public_name'] ?? 
           quality['rendition'] ?? 
           quality['quality'] ?? 
           '${quality['height'] ?? quality['width']}p';
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (_currentQuality == null || _currentQuality!['link'] == null) {
        setState(() {
          _errorMessage = 'No valid video quality available';
          _isLoading = false;
        });
        return;
      }

      _controller = VideoPlayerController.networkUrl(Uri.parse(_currentQuality!['link'].toString()))
        ..addListener(_videoListener);

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    final controllerValue = _controller.value;
    setState(() {
      _position = controllerValue.position;
      _duration = controllerValue.duration;
      _isBuffering = controllerValue.isBuffering;
      _isPlaying = controllerValue.isPlaying;
      
      if (!_isDragging) {
        _seekPosition = _position.inMilliseconds.toDouble();
      }
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
      _showControls = true;
      _startControlsTimer();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
      _showControls = true;
      _startControlsTimer();
    });
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = true;
      _startControlsTimer();
    });
  }


  Widget _buildDoubleTapIndicator() {
    if (!_showDoubleTapIndicator) return const SizedBox();
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isDoubleTapRight ? Icons.forward_10 : Icons.replay_10,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  void _showQualityBottomSheet() {
    if (_availableQualities.isEmpty) return;

    setState(() {
      _showControls = true;
      _controlsTimer?.cancel();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._availableQualities.map((quality) {
                return ListTile(
                  title: Text(
                    _getQualityLabel(quality),
                    style: TextStyle(
                      color: _currentQuality == quality ? widget.progressColor : Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentQuality = quality;
                      _isLoading = true;
                    });
                    _controller.pause().then((_) {
                      _controller.removeListener(_videoListener);
                      _controller.dispose();
                      _initializeVideo();
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedBottomSheet() {
    setState(() {
      _showControls = true;
      _controlsTimer?.cancel();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Playback Speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._playbackSpeeds.map((speed) {
                  return ListTile(
                    title: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: _playbackSpeed == speed ? widget.progressColor : Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _playbackSpeed = speed;
                        _controller.setPlaybackSpeed(speed);
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildSeekPreview() {
    if (!_showSeekPreview) return const SizedBox();
    
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _seekPreviewTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return Stack(
      children: [
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Gradient overlay at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (isLandscape)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _toggleFullScreen(),
                  ),
                Expanded(
                  child: Text(
                    widget.videoTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.progressColor,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    thumbColor: widget.progressColor,
                    overlayColor: widget.progressColor.withOpacity(0.2),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _seekPosition.clamp(0, _duration.inMilliseconds.toDouble()),
                    min: 0,
                    max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (value) {
                      setState(() {
                        _seekPosition = value;
                        _isDragging = true;
                        _showSeekPreview = true;
                        _seekPreviewTime = _formatDuration(Duration(milliseconds: value.toInt()));
                      });
                    },
                    onChangeEnd: (value) {
                      _controller.seekTo(Duration(milliseconds: value.toInt()));
                      setState(() {
                        _isDragging = false;
                        _showSeekPreview = false;
                      });
                      _startControlsTimer();
                    },
                  ),
                ),
                
                // Bottom row controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      
                      // Current time
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      
                      const Spacer(),
                      
                      // Total duration
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Playback speed
                      IconButton(
                        icon: Text(
                          '${_playbackSpeed}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: _showSpeedBottomSheet,
                      ),
                      
                      // Quality selector
                      if (_availableQualities.length > 1)
                        IconButton(
                          icon: const Icon(Icons.hd, color: Colors.white),
                          onPressed: _showQualityBottomSheet,
                        ),
                      
                      // Volume control
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                      ),
                      
                      // Fullscreen button
                      IconButton(
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFullScreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Buffering indicator
        if (_isBuffering && _isPlaying != true)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

        // Center play/pause button
        if(_showControls == true)
          Center(
            child: InkWell(
              onTap: _togglePlayPause,
              child: SizedBox(
                height: 100,
                width: 100,
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 60, color: Colors.white.withOpacity(0.8)),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _controlsTimer?.cancel();
    _doubleTapTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(color: widget.progressColor)
        )
      );
    }

    if (_errorMessage != null) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.progressColor,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: widget.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = widget.aspectRatio ?? 
                            (_controller.value.isInitialized 
                              ? _controller.value.aspectRatio 
                              : 16/9);
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: aspectRatio,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showControls = !_showControls;
                          if (_showControls) {
                            _startControlsTimer();
                          } else {
                            _controlsTimer?.cancel();
                          }
                        });
                      },
                      onDoubleTapDown: (details) {
                        final screenWidth = constraints.maxWidth;
                        final tapPosition = details.localPosition.dx;
                        final tapPercentage = tapPosition / screenWidth;
                        if (tapPercentage < 0.35) {
                          _handleSeek(false);
                        } else if (tapPercentage > 0.65) {
                          _handleSeek(true);
                        } else {
                          _togglePlayPause();
                        }
                      },
                      child: Stack(
                        children: [
                          SizedBox.expand(
                            child: FittedBox(
                              fit: widget.fit,
                              child: SizedBox(
                                width: _controller.value.size.width,
                                height: _controller.value.size.height,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                          ),
                          if (_showControls) _buildControls(),
                          _buildDoubleTapIndicator(),
                          _buildSeekPreview(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSeek(bool forward) {
    if (_doubleTapSeeking) return;

    setState(() {
      _isDoubleTapRight = forward;
      _showDoubleTapIndicator = true;
      _doubleTapSeekDuration = Duration(seconds: _seekDurationSeconds.toInt());
    });

    if (forward) {
      _controller.seekTo(_controller.value.position + _doubleTapSeekDuration);
    } else {
      _controller.seekTo(_controller.value.position - _doubleTapSeekDuration);
    }

    _doubleTapSeeking = true;
    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(const Duration(milliseconds: 800), () {
      setState(() {
        _showDoubleTapIndicator = false;
        _doubleTapSeeking = false;
      });
    });
    
    setState(() => _showControls = true);
    _startControlsTimer();
  }
}