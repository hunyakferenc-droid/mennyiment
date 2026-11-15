// Explicit review build only; never the normal application entry point.
import 'package:flutter/material.dart';
import 'package:mennyiment/menti_alive_preview.dart';

void main() => runApp(
  const MentiAliveReviewApp(
    reviewEnabled: bool.fromEnvironment('MENTI_ALIVE_REVIEW'),
  ),
);
