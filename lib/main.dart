import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wine_app/blocs/poll/poll_bloc.dart';
import 'package:wine_app/blocs/poll_detail/poll_detail_bloc.dart';
import 'package:wine_app/screens/vote_screen.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_poll_screen.dart';
import 'screens/poll_detail_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WineVotingApp());
}

class WineVotingApp extends StatelessWidget {
  const WineVotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final storageService = StorageService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: firestoreService),
        RepositoryProvider.value(value: storageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authService)),
          BlocProvider(create: (_) => PollBloc(firestoreService)),
          BlocProvider(create: (_) => PollDetailBloc(firestoreService)),
        ],
        child: MaterialApp(
          title: 'Wine Voting App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.deepPurple),
          home: const AuthGate(),
          routes: {
            '/login': (_) => LoginScreen(),
            '/register': (_) => RegisterScreen(),
            '/home': (_) => HomeScreen(),
            '/create_poll': (_) => CreatePollScreen(),
            '/detail': (_) => PollDetailScreen(),
            '/history': (_) => HistoryScreen(),
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return HomeScreen();
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
