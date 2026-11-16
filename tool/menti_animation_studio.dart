// Isolated developer entry point. No route from the ordinary application.
import 'package:flutter/material.dart';
import 'package:mennyiment/menti_alive_preview.dart';

void main() => runApp(
  MentiAliveReviewApp(
    reviewEnabled: const bool.fromEnvironment('MENTI_ALIVE_REVIEW'),
    // Preserve the old preview for its complete real-video regression suite.
    studioMode: Uri.base.queryParameters['preview'] != 'legacy',
  ),
);
