import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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

/// New-patient sign-up.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  /// Chosen through a date picker rather than typed, so the value sent to the
  /// server is always a valid date.
  DateTime? _birthDate;
  String? _birthDateError;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      setState(() => _birthDateError = 'Tanggal lahir wajib diisi');
      return;
    }
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
        );

    if (registered && mounted) context.go(AppRoutes.home);
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
                        title: 'Pendaftaran Pasien Baru',
                        subtitle: 'Lengkapi data untuk membuat akun.',
                        children: [
                          SheetTextField(
                            label: 'Masukkan nomor NIK KK/KTP',
                            hint: '468972645897649586',
                            controller: _nikController,
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            validator: (value) {
                              final nik = value?.trim() ?? '';
                              if (nik.isEmpty) return 'NIK wajib diisi';
                              if (nik.length != 16) return 'NIK harus 16 digit';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SheetTextField(
                            label: 'Masukkan Password',
                            hint: '••••••••••••',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
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
                          const SizedBox(height: AppSpacing.lg),
                          SheetTextField(
                            label: 'Masukkan Nama Lengkap',
                            hint: 'Admin',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SheetTextField(
                            label: 'Masukkan Email',
                            hint: 'nama@email.com',
                            controller: _emailController,
                            prefixIcon: Icons.mail_outline,
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
                            label: 'Masukkan Nomor HP',
                            hint: '081234567890',
                            controller: _phoneController,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator: (value) {
                              final phone = value?.trim() ?? '';
                              if (phone.isEmpty) {
                                return 'Nomor HP wajib diisi';
                              }
                              if (phone.length < 9) {
                                return 'Nomor HP tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _BirthDateField(
                            value: _birthDate,
                            errorText: _birthDateError,
                            onChanged: (date) => setState(() {
                              _birthDate = date;
                              _birthDateError = null;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppButton.light(
                            label: 'Daftar',
                            expand: true,
                            isLoading: auth.isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            key: const Key('goToLogin'),
                            onPressed: () => context.pop(),
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onAccentMuted,
                                ),
                                children: [
                                  const TextSpan(text: 'Sudah punya akun? '),
                                  TextSpan(
                                    text: 'Masuk',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
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
                child: AppBackButton(fallback: AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date of birth, chosen from a picker so the value is always a real date.
class _BirthDateField extends StatelessWidget {
  const _BirthDateField({
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
        ? 'Pilih Tanggal Lahir'
        : DateFormat('d MMMM yyyy', 'id_ID').format(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            key: const Key('birthDateField'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
              height: AppSizes.fieldHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(
                    Icons.cake_outlined,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.inputText.copyWith(
                        color: value == null
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 12),
            child: Text(
              errorText!,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                color: AppColors.danger,
              ),
            ),
          ),
      ],
    );
  }
}
