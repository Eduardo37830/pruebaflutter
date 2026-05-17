import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ImageEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data as String;
    final uri = Uri.tryParse(imageUrl);

    Widget image;
    if (uri != null && (uri.hasScheme || imageUrl.startsWith('/'))) {
      image = Image.network(imageUrl, fit: BoxFit.contain);
    } else {
      image = Image.file(File(imageUrl), fit: BoxFit.contain);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 48,
            maxHeight: 400,
          ),
          child: image,
        ),
      ),
    );
  }
}
