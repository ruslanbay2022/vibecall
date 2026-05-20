import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String? _usernameError;
  bool _checkingUsername = false;
  Timer? _debounceTimer;
  bool _submitting = false;

  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _debounceTimer?.cancel();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final value = _usernameController.text.trim().toLowerCase();
      if (value.isEmpty) {
        if (mounted) setState(() => _checkingUsername = false);
        return;
      }
      if (!_usernameRegex.hasMatch(value)) {
        if (mounted) {
          setState(() {
            _checkingUsername = false;
            _usernameError = null;
          });
        }
        return;
      }
      _checkUsername(value);
    });
  }

  Future<void> _checkUsername(String username) async {
    if (!mounted) return;
    setState(() => _checkingUsername = true);
    try {
      final available = await Supabase.instance.client.rpc(
        'username_available',
        params: {'p_username': username},
      );
      if (mounted) {
        setState(() {
          _checkingUsername = false;
          _usernameError = (available == true) ? null : l10n.usernameTaken;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingUsername = false);
      }
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.usernameRequired;
    }
    if (!_usernameRegex.hasMatch(value.toLowerCase())) {
      return l10n.usernameFormat;
    }
    return _usernameError;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim().toLowerCase(),
        'display_name': _displayNameController.text.trim(),
      }).eq('id', userId);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.onboardingError(e.toString()))),
        );
      }
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.usernameLabel,
                    suffixIcon: _checkingUsername
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateUsername,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(labelText: l10n.displayNameLabel),
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
