import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/textured_background.dart';
import '../application/auth_controller.dart';
import '../domain/user.dart';
import '../widgets/auth_artwork.dart';
import '../widgets/auth_tab_switcher.dart';
import '../widgets/auth_text_field.dart';

/// Register / Create Account screen with a 25:75 split, top tab switcher,
/// and no redundant title headings.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  String? _birthDateError;

  Gender? _gender;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;
  String? _termsError;

  @override
  void dispose() {
    _nikController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    bool hasError = false;
    if (!_formKey.currentState!.validate()) hasError = true;

    if (_birthDate == null) {
      setState(() => _birthDateError = 'Tanggal lahir wajib diisi');
      hasError = true;
    }
    if (!_agreedToTerms) {
      setState(
        () => _termsError =
            'Anda harus menyetujui Syarat & Ketentuan untuk mendaftar',
      );
      hasError = true;
    }

    if (hasError) return;

    FocusScope.of(context).unfocus();

    final registered = await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nik: _nikController.text.trim(),
          phone: _phoneController.text.trim(),
          birthDate: _birthDate!,
          gender: _gender,
        );

    if (registered && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: TexturedBackground(
        child: Stack(
          children: [
            // Top Section (25% height): Ciputra Hospital Logo & Back Button ONLY
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.28,
              child: AuthArtwork(
                height: screenHeight * 0.28,
                showBackButton: true,
                showLogo: true,
                isLargeLogo: true,
                showIllustration: false,
                onBackPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.onboarding);
                  }
                },
              ),
            ),

            // Bottom Curved White Content Card (75% height)
            Positioned.fill(
              top: screenHeight * 0.25,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A003366),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Pill Tab Switcher: Masuk | Daftar (same header navigation as login)
                        AuthTabSwitcher(
                          currentTab: AuthTabType.register,
                          loginKey: const Key('goToLogin'),
                          onTabChanged: (tab) {
                            if (tab == AuthTabType.login) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.login);
                              }
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // NIK Field
                        AuthTextField(
                          label: 'Nomor NIK',
                          hint: 'Masukkan 16 digit NIK Anda',
                          controller: _nikController,
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          errorText: auth.errorFor('nik'),
                          validator: (value) {
                            final nik = value?.trim() ?? '';
                            if (nik.isEmpty) return 'NIK wajib diisi';
                            if (nik.length != 16) return 'NIK harus 16 digit';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Password Field
                        AuthTextField(
                          label: 'Kata Sandi',
                          hint: 'Minimal 8 karakter',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          errorText: auth.errorFor('password'),
                          suffixIcon: IconButton(
                            tooltip: 'Tampilkan kata sandi',
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
                              return 'Kata sandi wajib diisi';
                            }
                            if (password.length < 8) {
                              return 'Kata sandi minimal 8 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Full Name Field
                        AuthTextField(
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama sesuai KTP',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          errorText: auth.errorFor('name'),
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'Nama lengkap wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Email Field
                        AuthTextField(
                          label: 'Email',
                          hint: 'nama@email.com',
                          controller: _emailController,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          errorText: auth.errorFor('email'),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Email wajib diisi';
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Phone Field
                        AuthTextField(
                          label: 'Nomor Handphone',
                          hint: '081234567890',
                          controller: _phoneController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          errorText: auth.errorFor('phone'),
                          validator: (value) {
                            final phone = value?.trim() ?? '';
                            if (phone.isEmpty) return 'Nomor HP wajib diisi';
                            if (phone.length < 9) return 'Nomor HP tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Birth Date & Gender Row
                        _BirthDateFieldModern(
                          value: _birthDate,
                          errorText: _birthDateError ?? auth.errorFor('dob'),
                          onChanged: (date) => setState(() {
                            _birthDate = date;
                            _birthDateError = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _GenderFieldModern(
                          value: _gender,
                          onChanged: (gender) => setState(() {
                            _gender = gender;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Confirm Password Field
                        AuthTextField(
                          label: 'Konfirmasi Kata Sandi',
                          hint: 'Ulangi kata sandi Anda',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            tooltip: 'Tampilkan kata sandi',
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          validator: (value) {
                            final confirm = value ?? '';
                            if (confirm.isNotEmpty &&
                                confirm != _passwordController.text) {
                              return 'Kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Agreement Checkbox
                        InkWell(
                          onTap: () => setState(() {
                            _agreedToTerms = !_agreedToTerms;
                            if (_agreedToTerms) _termsError = null;
                          }),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (val) => setState(() {
                                    _agreedToTerms = val ?? false;
                                    if (_agreedToTerms) _termsError = null;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi Ciputra Hospital.',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_termsError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 30),
                            child: Text(
                              _termsError!,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.danger,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        // General Error Banner (if any)
                        if (auth.error != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xxl),

                        // Big Primary Gradient Button: Daftar
                        AppButton(
                          label: 'Daftar',
                          expand: true,
                          height: 52,
                          borderRadius: 26,
                          isLoading: auth.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderFieldModern extends StatelessWidget {
  const _GenderFieldModern({
    required this.value,
    required this.onChanged,
  });

  final Gender? value;
  final ValueChanged<Gender?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Gender>(
              value: value,
              hint: Text(
                'Pilih Jenis Kelamin',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 13.5,
                ),
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textTertiary,
              ),
              dropdownColor: AppColors.white,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              onChanged: onChanged,
              items: const [
                DropdownMenuItem(
                  value: Gender.male,
                  child: Text('Laki-Laki'),
                ),
                DropdownMenuItem(
                  value: Gender.female,
                  child: Text('Perempuan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BirthDateFieldModern extends StatelessWidget {
  const _BirthDateFieldModern({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'Pilih tanggal lahir'
        : DateFormat('d MMMM yyyy', 'id_ID').format(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Lahir',
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: const Key('birthDateField'),
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(now.year - 25),
              firstDate: DateTime(now.year - 120),
              lastDate: now,
              locale: const Locale('id', 'ID'),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: errorText != null
                    ? AppColors.danger
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 19,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: value == null
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: value == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(
              errorText!,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.danger,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
