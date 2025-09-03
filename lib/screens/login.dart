import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email o Contraseña incorrectos')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            SafeArea(
              child: CircleAvatar(
                radius: 70,
                backgroundImage: const AssetImage('assets/images/logo.png'),
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 32),
            if (!isLogin) _styledTextField(nombreController, 'Nombre'),
            const SizedBox(height: 12),
            _styledTextField(
              emailController,
              'Email',
              inputType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: _inputDecoration('Contraseña').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: textColor,
                  ),
                  onPressed: () => setState(() {
                    showPassword = !showPassword;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submit(auth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLogin ? 'Entrar' : 'Crear cuenta',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _styledTextField(
    TextEditingController controller,
    String label, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: _inputDecoration(label),
    );
  }
}
