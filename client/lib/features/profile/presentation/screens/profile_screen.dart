import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/profile/data/profile_repository.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String? _avatarUrl;
  String? _username;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final userId = _userId;
      final profile = await ProfileRepository().getProfile(userId);
      if (profile != null && mounted) {
        setState(() {
          _username = profile['username'] as String?;
          _displayNameController.text = profile['display_name'] as String? ?? '';
          _bioController.text = profile['bio'] as String? ?? '';
          _avatarUrl = profile['avatar_url'] as String?;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _userId {
    return _currentUserId;
  }

  String get _currentUserId {
    return Supabase.instance.client.auth.currentUser!.id;
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _saving = true);
    try {
      final bytes = await image.readAsBytes();
      final publicUrl = await ProfileRepository().uploadAvatar(_userId, bytes);
      await ProfileRepository().updateProfile(_userId, avatarUrl: publicUrl);
      if (mounted) {
        setState(() => _avatarUrl = publicUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).avatarUploadError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ProfileRepository().updateProfile(
        _userId,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileSaveError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: _avatarUrl != null
                        ? CachedNetworkImageProvider(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickAndUploadAvatar,
                  child: Text(l10n.changeAvatar),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: TextEditingController(text: _username),
                enabled: false,
                decoration: InputDecoration(labelText: l10n.usernameLabel),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: l10n.displayNameLabel),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(labelText: l10n.bioLabel),
                maxLength: 280,
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
