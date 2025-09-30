import 'package:despensa_inteligente/services/auth.service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart'; // Generado por flutterfire configure
import 'features/auth/presentation/login_screen.dart'; // Nuestra pantalla inicial

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DespensaInteligenteApp()));
}

class DespensaInteligenteApp extends StatelessWidget {
  const DespensaInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos GoRouter para una navegación robusta si lo deseas,
    // pero para el MVP usaremos solo navegación básica al inicio.
    return MaterialApp(
      title: 'DespensaInteligente',
      theme: ThemeData(
        // Configuración de nuestro tema con Bricolage Grotesque y colores
        primaryColor: const Color(0xffcde600), // Nuestro acento
        fontFamily: 'Bricolage Grotesque',
        // Estética dark mode inicial
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xffcde600),
          background: Colors.black,
          onPrimary: Colors.black,
        ),
      ),
      home: const AuthWrapper(), // Widget que decide si ir a Login o Dashboard
    );
  }
}

// Un widget simple que maneja el flujo inicial
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el estado de autenticación (que crearemos en auth_service.dart)
    final userStream = ref.watch(firebaseAuthStateProvider);

    return userStream.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen(); // Si no hay usuario, vamos al Login
        }
        // Si hay usuario, vamos al Dashboard (que crearás tú)
        return const DashboardScreen();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => const Center(child: Text("Error de autenticación")),
    );
  }
}
