import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_repository.dart';
import 'startup_gate.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FirebaseSessionRepository();
});

final startupGateProvider = Provider<StartupGate>((ref) {
  return StartupGate(ref.watch(sessionRepositoryProvider));
});
