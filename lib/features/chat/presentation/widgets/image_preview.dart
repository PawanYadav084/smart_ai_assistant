import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final File? image;
  final VoidCallback onRemove;
  final bool isUploading;

  const ImagePreview({
    super.key,
    required this.image,
    required this.onRemove,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          if (isUploading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),

          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  image!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}