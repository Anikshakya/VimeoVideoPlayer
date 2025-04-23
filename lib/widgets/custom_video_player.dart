import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VimeoVideoPlayer extends StatefulWidget {
  final List<dynamic> files;
  final String videoTitle;
  final double? aspectRatio;
  final BoxFit fit;
  final Color progressColor;
  final Color bufferedColor;
  final Color backgroundColor;

  const VimeoVideoPlayer({
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
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  late VideoPlayerController _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isPlaying = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isFullScreen = false;
  bool _isMuted = false;
  bool _isBuffering = false;
  double _volume = 1.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDragging = false;
  bool _showQualityMenu = false;
  Map<String, dynamic>? _currentQuality;
  double _playbackSpeed = 1.0;
  bool _showSpeedMenu = false;
  bool _doubleTapSeeking = false;
  Timer? _doubleTapTimer;
  bool _showDoubleTapIndicator = false;
  Duration _doubleTapSeekDuration = Duration.zero;
  bool _isDoubleTapRight = false;
  bool _showVolumeControl = false;
  double _currentVolume = 1.0;
  double _seekPosition = 0.0;
  bool _showSeekPreview = false;
  double _seekPreviewPosition = 0.0;
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

      _initializeVideoPlayerFuture = _controller.initialize().then((_) {
        if (mounted) {
          setState(() {
            _duration = _controller.value.duration;
            _isLoading = false;
            _seekPosition = 0;
          });
          _controller.play();
          _isPlaying = true;
          _startControlsTimer();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to initialize video: ${e.toString()}';
            _isLoading = false;
          });
        }
      });
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
      _volume = controllerValue.volume;
      
      // Only update seek position if not currently dragging
      if (!_isDragging) {
        _seekPosition = _position.inMilliseconds.toDouble();
      }
    });
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging && !_showQualityMenu && !_showSpeedMenu) {
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
      _currentVolume = _isMuted ? 0.0 : (_currentVolume == 0.0 ? 1.0 : _currentVolume);
      _controller.setVolume(_isMuted ? 0.0 : _currentVolume);
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

  void _handleDoubleTap(bool isRightSide) {
    if (_doubleTapSeeking) return;

    setState(() {
      _isDoubleTapRight = isRightSide;
      _showDoubleTapIndicator = true;
      _doubleTapSeekDuration = Duration(seconds: _seekDurationSeconds.toInt());
    });

    if (isRightSide) {
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

  Widget _buildQualityMenu() {
    if (_availableQualities.isEmpty) return const SizedBox();

    return Positioned(
      right: 16,
      bottom: 80,
      child: Material(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Quality', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ..._availableQualities.map((quality) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentQuality = quality;
                      _showQualityMenu = false;
                      _isLoading = true;
                    });
                    _controller.pause().then((_) {
                      _controller.removeListener(_videoListener);
                      _controller.dispose();
                      _initializeVideo();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _getQualityLabel(quality),
                      style: TextStyle(
                        color: _currentQuality == quality ? widget.progressColor : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedMenu() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Material(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ..._playbackSpeeds.map((speed) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _playbackSpeed = speed;
                      _showSpeedMenu = false;
                      _controller.setPlaybackSpeed(speed);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: _playbackSpeed == speed ? widget.progressColor : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
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
                        _seekPreviewPosition = value;
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
                        onPressed: () {
                          setState(() {
                            _showSpeedMenu = !_showSpeedMenu;
                            _showQualityMenu = false;
                            if (_showSpeedMenu) {
                              _controlsTimer?.cancel();
                            } else {
                              _startControlsTimer();
                            }
                          });
                        },
                      ),
                      
                      // Quality selector
                      if (_availableQualities.length > 1)
                        IconButton(
                          icon: const Icon(Icons.hd, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showQualityMenu = !_showQualityMenu;
                              _showSpeedMenu = false;
                              if (_showQualityMenu) {
                                _controlsTimer?.cancel();
                              } else {
                                _startControlsTimer();
                              }
                            });
                          },
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
              onTap: () async{
                _togglePlayPause();
              },
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
    return Center(child: CircularProgressIndicator(color: widget.progressColor));
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
        // Calculate aspect ratio based on video or provided value
        final aspectRatio = widget.aspectRatio ?? 
                          (_controller.value.isInitialized 
                            ? _controller.value.aspectRatio 
                            : 16/9); // Default fallback
        
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
                        _showQualityMenu = false;
                        _showSpeedMenu = false;
                        if (_showControls) {
                          _startControlsTimer();
                        } else {
                          _controlsTimer?.cancel();
                        }
                      });
                    },
                    // onHorizontalDragStart: (details) {
                    //   setState(() {
                    //     _isDragging = true;
                    //     _showControls = true;
                    //     _controlsTimer?.cancel();
                    //   });
                    // },
                    // onHorizontalDragUpdate: (details) {
                    //   final screenWidth = constraints.maxWidth;
                    //   final dragDistance = details.primaryDelta ?? 0;
                    //   final seekDistance = (_duration.inMilliseconds / screenWidth) * dragDistance;
                      
                    //   setState(() {
                    //     _seekPosition = (_seekPosition - seekDistance).clamp(0, _duration.inMilliseconds.toDouble());
                    //     _showSeekPreview = true;
                    //     _seekPreviewPosition = _seekPosition;
                    //     _seekPreviewTime = _formatDuration(Duration(milliseconds: _seekPreviewPosition.toInt()));
                    //   });
                    // },
                    // onHorizontalDragEnd: (details) {
                    //   _controller.seekTo(Duration(milliseconds: _seekPosition.toInt()));
                    //   setState(() {
                    //     _isDragging = false;
                    //     _showSeekPreview = false;
                    //   });
                    //   _startControlsTimer();
                    // },
                    // onTapDown: (details) {
                    //   // Show controls and reset timer
                    //     setState(() => _showControls = true);
                    //     _startControlsTimer();
                    //     // Middle 30% - toggle play/pause
                    //     // _togglePlayPause();
                    // },
                    onDoubleTapDown: (details) {
                      final screenWidth = constraints.maxWidth;
                      final tapPosition = details.localPosition.dx;
                      final tapPercentage = tapPosition / screenWidth;
                      if (tapPercentage < 0.35) {
                        // Left 35% - seek backward
                        _handleSeek(false);
                      } else if (tapPercentage > 0.65) {
                        // Right 35% - seek forward
                        _handleSeek(true);
                      } else {
                        // Middle 30% - toggle play/pause
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
                        if (_showQualityMenu) _buildQualityMenu(),
                        if (_showSpeedMenu) _buildSpeedMenu(),
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

// Add this new method to handle seek on tap
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
  
  // Show controls and reset timer
  setState(() => _showControls = true);
  _startControlsTimer();
}
}