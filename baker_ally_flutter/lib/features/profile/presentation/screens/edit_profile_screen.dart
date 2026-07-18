import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/user_profile.dart';
import '../providers/profile_providers.dart';

/// `/profile/edit` (06_profile_and_account.md). Avatar changes upload +
/// PATCH immediately on pick; Full Name/Business Name/GSTIN batch into one
/// PATCH on Save. Phone is read-only -- it's the OTP login identity.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _businessName = TextEditingController();
  final _gstin = TextEditingController();

  bool _initialized = false;
  bool _uploadingAvatar = false;
  bool _saving = false;
  String? _avatarUrl;

  @override
  void dispose() {
    _fullName.dispose();
    _businessName.dispose();
    _gstin.dispose();
    super.dispose();
  }

  void _seedFrom(UserProfile profile) {
    if (_initialized) return;
    _fullName.text = profile.fullName ?? '';
    _businessName.text = profile.businessName ?? '';
    _gstin.text = profile.gstin ?? '';
    _avatarUrl = profile.avatarUrl;
    _initialized = true;
  }

  Future<void> _pickAvatar(String userId) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(userRepositoryProvider).uploadAvatar(userId, Uint8List.fromList(bytes));
      await ref.read(userRepositoryProvider).updateMe(avatarUrl: url);
      ref.invalidate(profileProvider);
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update avatar: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).updateMe(
            fullName: _fullName.text.trim(),
            businessName: _businessName.text.trim(),
            gstin: _gstin.text.trim(),
          );
      ref.invalidate(profileProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load profile: $e')),
        data: (profile) {
          _seedFrom(profile);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploadingAvatar ? null : () => _pickAvatar(profile.id),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? Text(profile.initials, style: const TextStyle(fontSize: 32))
                              : null,
                        ),
                        if (_uploadingAvatar) const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(_uploadingAvatar ? 'Uploading...' : 'Tap to change')),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessName,
                  decoration: const InputDecoration(labelText: 'Business Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gstin,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN',
                    helperText: 'Optional -- for your own records',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: profile.phone ?? '',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    helperText: 'Tied to OTP login -- not editable',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
