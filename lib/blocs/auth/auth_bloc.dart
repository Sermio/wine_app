import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wine_app/blocs/auth/auth_state.dart';
import 'auth_event.dart';
import '../../services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authService.signIn(event.email, event.password);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError('Error al iniciar sesión'));
      }
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authService.signUp(event.email, event.password);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError('Error al registrarse'));
      }
    });

    on<SignOutRequested>((event, emit) async {
      await _authService.signOut();
      emit(AuthInitial());
    });
  }
}
