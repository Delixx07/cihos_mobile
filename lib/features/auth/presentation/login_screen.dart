import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hospital_logo.dart';
import '../../../core/widgets/textured_background.dart';
import '../application/auth_controller.dart';
import '../widgets/auth_card.dart';
import '../widgets/sheet_text_field.dart';

/// Sign-in — the first screen after the splash.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final signedIn = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (signedIn && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const HospitalLogo.splash(),
                    const SizedBox(height: AppSpacing.xl),
                    Form(
                      key: _formKey,
                      child: AuthCard(
                        title: 'Masuk',
                        subtitle: 'Gunakan NIK yang terdaftar di Cihos.',
                        children: [
                          SheetTextField(
                            label: 'Email',
                            hint: 'nama@email.com',
                            controller: _emailController,
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'Email wajib diisi';
                              if (!email.contains('@') ||
                                  !email.contains('.')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SheetTextField(
                            label: 'Password',
                            hint: 'Masukkan password',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (password.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              auth.error!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          AppButton.light(
                            label: 'Masuk',
                            expand: true,
                            height: 50,
                            borderRadius: 28,
                            isLoading: auth.isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            key: const Key('goToRegister'),
                            onPressed: () => context.push(AppRoutes.register),
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onAccentMuted,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(text: 'Pasien baru? '),
                                  TextSpan(
                                    text: 'Daftar di sini',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Last in the stack so the scroll view cannot swallow its taps.
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: AppBackButton(fallback: AppRoutes.onboarding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
