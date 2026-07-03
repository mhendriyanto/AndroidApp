import 'dart:io';

import 'package:flutter/material.dart';

import '../models/snap_item.dart';

class MiniShot extends StatelessWidget {
  final MockType type;
  final String? imagePath;
  const MiniShot({required this.type, this.imagePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ImagePreview(imagePath: imagePath, fallback: MiniMock(type: type)),
    );
  }
}

class SmallSquareMock extends StatelessWidget {
  final MockType type;
  final String? imagePath;
  const SmallSquareMock({required this.type, this.imagePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 112,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child:
            ImagePreview(imagePath: imagePath, fallback: MiniMock(type: type)));
  }
}

class ImagePreview extends StatelessWidget {
  final String? imagePath;
  final Widget fallback;
  const ImagePreview(
      {required this.imagePath, required this.fallback, super.key});

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class MiniMock extends StatelessWidget {
  final MockType type;
  const MiniMock({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    final blockColor = switch (type) {
      MockType.receipt => const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF0F172A), Color(0xFFF1F5F9)],
          stops: [0, .36, .36]),
      MockType.chat => const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFCFFAFE), Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      MockType.chart => const LinearGradient(
          colors: [Color(0xFFBAE6FD), Color(0xFFECFEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      MockType.travel => const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            height: 8,
            decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999))),
        const SizedBox(height: 7),
        Expanded(
            child: Container(
                decoration: BoxDecoration(
                    gradient: blockColor,
                    borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 7),
        Container(
            width: 48,
            height: 7,
            decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999))),
      ],
    );
  }
}
