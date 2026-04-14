import 'package:despensa_inteligente/app/router.dart';
import 'package:despensa_inteligente/app/theme.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/services/auth.service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: DespensaInteligenteApp()));
}

class DespensaInteligenteApp extends ConsumerWidget {
  const DespensaInteligenteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthStateProvider);
    final usuarioAsync = ref.watch(usuarioStreamProvider);

    final router = buildRouter(
      isLoggedIn: () => authState.asData?.value != null,
      hasHogar: () {
        if (usuarioAsync.isLoading) return null;
        return usuarioAsync.asData?.value?.hogarActivo != null;
      },
    );

    return MaterialApp.router(
      title: 'DespensaInteligente',
      theme: DespensaTheme.dark(),
      routerConfig: router,
    );
  }
}
