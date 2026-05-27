// Profile setup — first-run only. Pick an avatar + display name, then land on
// /home. Frontend: avatar picker shows a stub; the avatar preview reflects the
// typed name's initial. Phase 3 uploads to Storage and writes users/{uid}.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/gang_avatar.dart';
import '../../../shared/widgets/labeled_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pickPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo picker — Phase 3')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              const HeroTitle(before: 'A face for the ', emphasis: 'gang', fontSize: 36),
              const SizedBox(height: 10),
              Text(
                "Add a photo and your name so friends know who's shooting.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      GangAvatar(name: name.isEmpty ? '?' : name, size: 112),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.ink,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cream, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: AppTheme.cream, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              LabeledField(
                label: 'Your name',
                hint: 'Aarav',
                controller: _name,
                textCapitalization: TextCapitalization.words,
              ),
              const Spacer(),
              FilledButton(
                onPressed: name.isEmpty ? null : () => context.go('/home'),
                child: const Text('Enter gang.roll'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
