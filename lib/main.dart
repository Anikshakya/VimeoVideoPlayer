import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimyo/video_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vimeo Uploader and Player',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: VideoListPage(),
    );
  }
}