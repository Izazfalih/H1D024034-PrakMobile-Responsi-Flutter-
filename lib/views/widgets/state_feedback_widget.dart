import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan kondisi loading, data kosong, atau error.
class StateFeedbackWidget extends StatelessWidget {
  const StateFeedbackWidget._({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  factory StateFeedbackWidget.loading({
    String message = 'Memuat data dari Open-Meteo...',
  }) {
    return StateFeedbackWidget._(
      icon: Icons.cloud_sync_rounded,
      title: 'Mengambil Data',
      message: message,
      isLoading: true,
    );
  }

  factory StateFeedbackWidget.empty({
    IconData icon = Icons.location_off_rounded,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return StateFeedbackWidget._(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory StateFeedbackWidget.error({
    required String message,
    VoidCallback? onRetry,
  }) {
    return StateFeedbackWidget._(
      icon: Icons.wifi_off_rounded,
      title: 'Gagal Memuat Data',
      message: message,
      isError: true,
      actionLabel: onRetry != null ? 'Coba Lagi' : null,
      onAction: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: (isError
                                ? colorScheme.errorContainer
                                : colorScheme.primaryContainer)
                            .withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 30,
                        color: isError
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: Icon(
                        isError ? Icons.refresh_rounded : Icons.search_rounded,
                      ),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
