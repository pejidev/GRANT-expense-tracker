import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodel/app_viewmodel.dart';
import '../model/appmodel.dart';

enum AuthMode { signIn, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  AuthMode _authMode = AuthMode.signIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = Provider.of<AppViewModel>(context, listen: false);
    try {
      await viewModel.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showErrorSnackbar('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match');
      return;
    }

    final viewModel = Provider.of<AppViewModel>(context, listen: false);
    try {
      await viewModel.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      _showErrorSnackbar('Registration failed: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegistering = _authMode == AuthMode.register;
    final viewModel = Provider.of<AppViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text(isRegistering ? 'Register' : 'Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (isRegistering) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                  value!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty ? 'Valid email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              if (isRegistering) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration:
                  const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : isRegistering ? _handleRegister : _handleSignIn,
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator()
                      : Text(isRegistering ? 'Register' : 'Sign In'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _authMode = isRegistering ? AuthMode.signIn : AuthMode.register;
                }),
                child: Text(isRegistering
                    ? 'Already have an account? Sign In'
                    : 'Need an account? Register'),
              ),
              if (viewModel.error != null)
                Text(
                  viewModel.error!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}