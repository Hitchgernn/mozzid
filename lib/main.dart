import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'presentation/providers/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Assemble the offline graph (DB, repos, mock classifier, services).
  // Swap MockSpeciesClassifier → TfliteSpeciesClassifier and NoopSyncService →
  // FirebaseSyncService inside Bootstrap.create() when those land.
  final bootstrap = await Bootstrap.create();

  runApp(
    ProviderScope(
      overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
      child: const MozzApp(),
    ),
  );
}
