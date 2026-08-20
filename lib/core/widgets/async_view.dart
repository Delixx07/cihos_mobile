import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Renders an [AsyncValue] with a consistent loading, error, and empty state.
///
/// Screens that each invent their own spinner and error text drift apart
/// quickly. Routing every async read through here means a patient sees the
/// same shapes everywhere, and every failure offers a way to retry — a dead
/// end with no recovery is the worst outcome on a hospital app.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyTitle = 'Belum ada data',
    this.emptyMessage,
    this.loadingHeight = 220,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  /// Re-runs the request. Usually `ref.invalidate(theProvider)`.
  final VoidCallback onRetry;

  /// Lets the caller decide what "no results" means for its own data.
  final bool Function(T data)? isEmpty;

  final String emptyTitle;
  final String? emptyMessage;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => _Loading(height: loadingHeight),
      error: (error, _) => _ErrorState(error: error, onRetry: onRetry),
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return _EmptyState(title: emptyTitle, message: emptyMessage);
        }
        return builder(data);
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.accentSoft,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // ApiException already carries a message written for patients; anything
    // else is a bug, and a stack trace helps nobody standing in a lobby.
    final message = error is ApiException
        ? (error as ApiException).message
        : 'Terjadi kesalahan. Silakan coba lagi.';
    final isOffline = error is ApiException && (error as ApiException).isNetwork;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: 40,
            color: AppColors.accentSoft.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              fontSize: 14,
              height: 1.35,
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            key: const Key('retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 40,
            color: AppColors.accentSoft.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accentSoft,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                height: 1.35,
                color: AppColors.accentSoft.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
