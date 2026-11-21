// Explicit REVIEW entry: exact existing candidates, never production approvals.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_alive_review_catalog.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_studio_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('MENTI_ALIVE_REVIEW')) {
    runApp(const MennyiMentApp());
    return;
  }
  runApp(
    MennyiMentApp(
      reviewHome: true,
      animationCatalog: () async => MentiStudioPlaybackCatalog(
        MentiAnimationCatalog.decode(
          await rootBundle.loadString('assets/menti_life/catalog.json'),
        ),
        MentiAliveReviewCatalog.decode(
          await rootBundle.loadString('assets/menti_alive_review/catalog.json'),
          developerPreview: true,
        ),
      ),
    ),
  );
}
