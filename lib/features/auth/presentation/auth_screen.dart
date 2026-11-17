import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../business/presentation/business_workspace_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isRegistering = false;
  bool _isBusy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isRegistering) {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      setState(() => _errorMessage = _messageFor(error.code));
    } catch (_) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.authGenericError;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _messageFor(String code) {
    final l = AppLocalizations.of(context)!;
    switch (code) {
      case 'email-already-in-use':
        return l.authEmailExists;
      case 'invalid-email':
        return l.enterValidEmail;
      case 'weak-password':
        return l.authChooseStrongerPassword;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l.authCredentialsIncorrect;
      case 'network-request-failed':
        return l.authNetworkError;
      case 'too-many-requests':
        return l.authTooManyAttempts;
      default:
        return l.authFailed;
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.authEnterEmailFirst);
      return;
    }
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.passwordResetSent)),
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _errorMessage = _messageFor(error.code));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signedOut)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: user == null ? _buildForm() : _buildAccount(user),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.storefront_rounded, size: 52, color: AppTheme.blue),
        const SizedBox(height: 16),
        Text(
          _isRegistering ? l.authCreateBusinessAccount : l.authWelcomeBack,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRegistering
              ? l.authRegisterIntro
              : l.authSignInIntro,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey.shade600),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: l.emailAddress,
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return l.enterValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: _isRegistering
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return l.passwordMinLength;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, height: 1.35),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isBusy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.blue,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: _isBusy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isRegistering ? l.authCreateAccount : l.authSignIn),
        ),
        if (!_isRegistering)
          TextButton(
            onPressed: _isBusy ? null : _resetPassword,
            child: Text(l.forgotPassword),
          ),
        TextButton(
          onPressed: _isBusy
              ? null
              : () => setState(() {
                    _isRegistering = !_isRegistering;
                    _errorMessage = null;
                  }),
          child: Text(
            _isRegistering
                ? l.authAlreadyHaveAccount
                : l.authNewToWiseSell,
          ),
        ),
      ],
    );
  }

  Widget _buildAccount(User user) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.account_circle_rounded, size: 64, color: AppTheme.blue),
        const SizedBox(height: 16),
        Text(
          l.authSignedIn,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(user.email ?? 'WiseSell user', textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BusinessWorkspaceScreen(),
            ),
          ),
          icon: const Icon(Icons.storefront_outlined),
          label: Text(l.openBusinessWorkspace),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: Text(l.signOut),
        ),
      ],
    );
  }
}
