
class VimeoVideo {
  final String id;
  final String name;
  final String description;
  final String pictureUrl;
  final int duration;
  final String createdTime;

  VimeoVideo({
    required this.id,
    required this.name,
    required this.description,
    required this.pictureUrl,
    required this.duration,
    required this.createdTime,
  });

  factory VimeoVideo.fromJson(Map<String, dynamic> json) {
    return VimeoVideo(
      id: json['uri'].toString().split('/').last,
      name: json['name'] ?? 'Untitled',
      description: json['description'] ?? '',
      pictureUrl: json['pictures']['sizes'][3]['link'] ?? '',
      duration: json['duration'] ?? 0,
      createdTime: json['created_time'] ?? '',
    );
  }
}