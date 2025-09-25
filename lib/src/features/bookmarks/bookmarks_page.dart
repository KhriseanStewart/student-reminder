import 'package:flutter/material.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Courses")),
      body: const Center(
        child: Text("📘 Courses page (coming soon)"),
      ),
    );
  }
}