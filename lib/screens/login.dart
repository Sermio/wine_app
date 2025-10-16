import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wine_app/screens/home.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/utils/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nombreController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  bool showPassword = false;
  bool rememberCredentials = false;
  bool emailError = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      // Usar SharedPreferences básico de Flutter
      const platform = MethodChannel('flutter_shared_preferences');

      final email = await platform.invokeMethod('getString', {
        'key': 'saved_email',
      });
      final password = await platform.invokeMethod('getString', {
        'key': 'saved_password',
      });

      if (email != null && password != null) {
        emailController.text = email;
        passwordController.text = password;
        if (mounted) {
          setState(() => rememberCredentials = true);
        }
        print('DEBUG: Credenciales cargadas desde SharedPreferences');
      }
    } catch (e) {
      print('Error cargando credenciales guardadas: $e');
      // Si falla, simplemente no cargamos nada
    }
  }

  Future<void> _saveCredentials() async {
    try {
      // Usar SharedPreferences básico de Flutter
      const platform = MethodChannel('flutter_shared_preferences');

      if (rememberCredentials) {
        await platform.invokeMethod('setString', {
          'key': 'saved_email',
          'value': emailController.text.trim(),
        });
        await platform.invokeMethod('setString', {
          'key': 'saved_password',
          'value': passwordController.text.trim(),
        });
        print('DEBUG: Credenciales guardadas en SharedPreferences');
      } else {
        await platform.invokeMethod('remove', {'key': 'saved_email'});
        await platform.invokeMethod('remove', {'key': 'saved_password'});
        print('DEBUG: Credenciales eliminadas de SharedPreferences');
      }
    } catch (e) {
      print('Error guardando credenciales: $e');
      // Si falla, simplemente no guardamos nada
    }
  }

  Future<void> _resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      if (mounted) {
        setState(() => emailError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, introduce tu email primero'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => emailError = false);
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha enviado un email para restablecer tu contraseña. Revisa tu bandeja de entrada y la carpeta de spam.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      print('Error al enviar email de restablecimiento: $e');

      String errorMessage = 'Error al enviar email';

      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No existe una cuenta con este email';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'El formato del email no es válido';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Demasiados intentos. Espera unos minutos';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _submit(AuthService auth) async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await auth.signIn(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        await auth.signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        final uid = auth.currentUser!.uid;
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'nombre': nombreController.text.trim(),
        });
      }

      if (auth.currentUser != null && mounted) {
        await _saveCredentials();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email o Contraseña incorrectos')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Logo con gradiente de fondo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/images/logo.png'),
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 40),

              // Formulario en card
              Card(
                elevation: 8,
                shadowColor: shadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        _modernTextField(
                          nombreController,
                          'Nombre completo',
                          Icons.person,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _modernTextField(
                        emailController,
                        'Correo electrónico',
                        Icons.email_outlined,
                        inputType: TextInputType.emailAddress,
                        errorText: emailError ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 20),
                      _modernTextField(
                        passwordController,
                        'Contraseña',
                        Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),

                      // Checkbox para recordar credenciales
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: rememberCredentials,
                              onChanged: (value) {
                                setState(
                                  () => rememberCredentials = value ?? false,
                                );
                              },
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Text(
                            'Recordar credenciales',
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _submit(auth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: primaryColor.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón "Olvidé mi contraseña" (solo en login)
              if (isLogin) ...[
                TextButton(
                  onPressed: _resetPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón cambiar modo
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? '¿No tienes cuenta? Regístrate'
                        : '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    String? errorText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword ? !showPassword : false,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: errorText != null ? Colors.red : primaryColor,
          size: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: textSecondaryColor,
                  size: 20,
                ),
                onPressed: () => setState(() {
                  showPassword = !showPassword;
                }),
              )
            : null,
        errorText: errorText,
        labelStyle: TextStyle(color: textSecondaryColor, fontSize: 14),
        floatingLabelStyle: TextStyle(color: primaryColor, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
