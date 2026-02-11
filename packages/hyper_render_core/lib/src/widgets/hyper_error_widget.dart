import 'package:flutter/material.dart';
import '../style/design_tokens.dart';

/// Type of error for styling purposes
enum HyperErrorType {
  /// Generic error (red)
  error,

  /// Warning state (orange)
  warning,

  /// Info state (blue)
  info,

  /// Network/loading error (gray)
  network,
}

/// Beautiful error widget following Material Design 3
///
/// Displays errors with appropriate styling, icons, and optional retry button.
/// Supports multiple error types with semantic colors from DesignTokens.
///
/// ## Usage
///
/// ```dart
/// // Basic error
/// HyperErrorWidget(
///   message: 'Failed to load image',
///   icon: Icons.broken_image,
/// )
///
/// // With retry
/// HyperErrorWidget(
///   message: 'Network error',
///   icon: Icons.cloud_off,
///   onRetry: () => loadData(),
/// )
///
/// // Different error types
/// HyperErrorWidget.warning(
///   message: 'Content unavailable',
/// )
///
/// HyperErrorWidget.network(
///   message: 'Check your connection',
///   onRetry: () => retry(),
/// )
/// ```
class HyperErrorWidget extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Icon to show above message
  final IconData icon;

  /// Optional retry callback
  final VoidCallback? onRetry;

  /// Retry button label
  final String retryLabel;

  /// Error type for styling
  final HyperErrorType type;

  /// Optional width constraint
  final double? width;

  /// Optional height constraint
  final double? height;

  /// Whether to show border
  final bool showBorder;

  /// Whether to use compact layout
  final bool compact;

  const HyperErrorWidget({
    super.key,
    required this.message,
    required this.icon,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.type = HyperErrorType.error,
    this.width,
    this.height,
    this.showBorder = true,
    this.compact = false,
  });

  /// Create error widget with error styling
  const HyperErrorWidget.error({
    Key? key,
    required String message,
    IconData icon = Icons.error_outline,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    double? width,
    double? height,
    bool showBorder = true,
    bool compact = false,
  }) : this(
          key: key,
          message: message,
          icon: icon,
          onRetry: onRetry,
          retryLabel: retryLabel,
          type: HyperErrorType.error,
          width: width,
          height: height,
          showBorder: showBorder,
          compact: compact,
        );

  /// Create error widget with warning styling
  const HyperErrorWidget.warning({
    Key? key,
    required String message,
    IconData icon = Icons.warning_amber_outlined,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    double? width,
    double? height,
    bool showBorder = true,
    bool compact = false,
  }) : this(
          key: key,
          message: message,
          icon: icon,
          onRetry: onRetry,
          retryLabel: retryLabel,
          type: HyperErrorType.warning,
          width: width,
          height: height,
          showBorder: showBorder,
          compact: compact,
        );

  /// Create error widget with info styling
  const HyperErrorWidget.info({
    Key? key,
    required String message,
    IconData icon = Icons.info_outline,
    VoidCallback? onRetry,
    String retryLabel = 'Try Again',
    double? width,
    double? height,
    bool showBorder = true,
    bool compact = false,
  }) : this(
          key: key,
          message: message,
          icon: icon,
          onRetry: onRetry,
          retryLabel: retryLabel,
          type: HyperErrorType.info,
          width: width,
          height: height,
          showBorder: showBorder,
          compact: compact,
        );

  /// Create error widget for network errors
  const HyperErrorWidget.network({
    Key? key,
    String message = 'Network error',
    IconData icon = Icons.cloud_off_outlined,
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    double? width,
    double? height,
    bool showBorder = true,
    bool compact = false,
  }) : this(
          key: key,
          message: message,
          icon: icon,
          onRetry: onRetry,
          retryLabel: retryLabel,
          type: HyperErrorType.network,
          width: width,
          height: height,
          showBorder: showBorder,
          compact: compact,
        );

  /// Create error widget for image loading failures
  const HyperErrorWidget.image({
    Key? key,
    String message = 'Failed to load image',
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    double? width,
    double? height,
    bool showBorder = true,
    bool compact = false,
  }) : this(
          key: key,
          message: message,
          icon: Icons.broken_image_outlined,
          onRetry: onRetry,
          retryLabel: retryLabel,
          type: HyperErrorType.error,
          width: width,
          height: height,
          showBorder: showBorder,
          compact: compact,
        );

  /// Create error widget for video loading failures
  const HyperErrorWidget.video({
    Key? key,
    String message = 'Failed to load video',
    VoidCallback? onRetry,
    String retryLabel = 'Retry',
    double? width,
    double? height,
    bool showBorder = true,
    bool compact = false,
  }) : this(
          key: key,
          message: message,
          icon: Icons.videocam_off_outlined,
          onRetry: onRetry,
          retryLabel: retryLabel,
          type: HyperErrorType.error,
          width: width,
          height: height,
          showBorder: showBorder,
          compact: compact,
        );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(isDark);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: colors.iconColor,
          size: compact ? 32.0 : 48.0,
        ),
        SizedBox(height: compact ? DesignTokens.space1 : DesignTokens.space2),
        Text(
          message,
          style: TextStyle(
            color: colors.textColor,
            fontSize: compact ? DesignTokens.bodySmallFontSize : DesignTokens.bodyMediumFontSize,
            fontWeight: DesignTokens.bodyMediumFontWeight,
          ),
          textAlign: TextAlign.center,
          maxLines: compact ? 2 : 4,
          overflow: TextOverflow.ellipsis,
        ),
        if (onRetry != null) ...[
          SizedBox(height: compact ? DesignTokens.space1_5 : DesignTokens.space2),
          _buildRetryButton(colors),
        ],
      ],
    );

    final decoration = BoxDecoration(
      color: colors.backgroundColor,
      border: showBorder ? Border.all(color: colors.borderColor, width: 1.5) : null,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    );

    Widget widget = Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(compact ? DesignTokens.space2 : DesignTokens.space3),
      decoration: decoration,
      child: content,
    );

    // Add constraints if width/height not specified
    if (width == null || height == null) {
      widget = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: compact ? 120.0 : 200.0,
          minHeight: compact ? 80.0 : 120.0,
          maxWidth: width ?? 400.0,
        ),
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildRetryButton(_ErrorColors colors) {
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: Icon(Icons.refresh, size: compact ? 16.0 : 20.0),
      label: Text(
        retryLabel,
        style: TextStyle(fontSize: compact ? DesignTokens.labelSmallFontSize : DesignTokens.labelMediumFontSize),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.buttonColor,
        side: BorderSide(color: colors.buttonColor),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? DesignTokens.space2 : DesignTokens.space3,
          vertical: compact ? DesignTokens.space1 : DesignTokens.space1_5,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  _ErrorColors _getColors(bool isDark) {
    switch (type) {
      case HyperErrorType.error:
        return _ErrorColors(
          backgroundColor: isDark ? DesignTokens.darkErrorBackground : DesignTokens.errorBackground,
          borderColor: isDark ? DesignTokens.darkErrorColor.withValues(alpha:0.4) : DesignTokens.errorColor.withValues(alpha:0.4),
          iconColor: isDark ? DesignTokens.darkErrorColor : DesignTokens.errorColor,
          textColor: isDark ? DesignTokens.darkErrorColor : DesignTokens.errorColor,
          buttonColor: isDark ? DesignTokens.darkErrorColor : DesignTokens.errorColor,
        );

      case HyperErrorType.warning:
        return _ErrorColors(
          backgroundColor: isDark ? DesignTokens.darkWarningBackground : DesignTokens.warningBackground,
          borderColor: isDark ? DesignTokens.darkWarningColor.withValues(alpha:0.4) : DesignTokens.warningColor.withValues(alpha:0.4),
          iconColor: isDark ? DesignTokens.darkWarningColor : DesignTokens.warningColor,
          textColor: isDark ? DesignTokens.darkWarningColor : DesignTokens.warningColor,
          buttonColor: isDark ? DesignTokens.darkWarningColor : DesignTokens.warningColor,
        );

      case HyperErrorType.info:
        return _ErrorColors(
          backgroundColor: isDark ? DesignTokens.darkInfoBackground : DesignTokens.infoBackground,
          borderColor: isDark ? DesignTokens.darkInfoColor.withValues(alpha:0.4) : DesignTokens.infoColor.withValues(alpha:0.4),
          iconColor: isDark ? DesignTokens.darkInfoColor : DesignTokens.infoColor,
          textColor: isDark ? DesignTokens.darkInfoColor : DesignTokens.infoColor,
          buttonColor: isDark ? DesignTokens.darkInfoColor : DesignTokens.infoColor,
        );

      case HyperErrorType.network:
        return _ErrorColors(
          backgroundColor: isDark
              ? DesignTokens.darkQuoteBackground
              : DesignTokens.codeBackground,
          borderColor: isDark
              ? DesignTokens.darkQuoteBorder
              : DesignTokens.quoteBorder,
          iconColor: isDark
              ? DesignTokens.darkTextSecondary
              : DesignTokens.textSecondary,
          textColor: isDark
              ? DesignTokens.darkTextSecondary
              : DesignTokens.textSecondary,
          buttonColor: isDark
              ? DesignTokens.darkTextSecondary
              : DesignTokens.textSecondary,
        );
    }
  }
}

/// Internal class for error styling colors
class _ErrorColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final Color buttonColor;

  _ErrorColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.buttonColor,
  });
}

/// Compact inline error indicator
///
/// Useful for small spaces where full error widget won't fit.
///
/// ```dart
/// HyperErrorIndicator(
///   message: 'Error',
///   icon: Icons.error,
/// )
/// ```
class HyperErrorIndicator extends StatelessWidget {
  final String message;
  final IconData icon;
  final HyperErrorType type;
  final VoidCallback? onTap;

  const HyperErrorIndicator({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.type = HyperErrorType.error,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    switch (type) {
      case HyperErrorType.error:
        color = isDark ? DesignTokens.darkErrorColor : DesignTokens.errorColor;
        break;
      case HyperErrorType.warning:
        color = isDark ? DesignTokens.darkWarningColor : DesignTokens.warningColor;
        break;
      case HyperErrorType.info:
        color = isDark ? DesignTokens.darkInfoColor : DesignTokens.infoColor;
        break;
      case HyperErrorType.network:
        color = isDark ? DesignTokens.darkTextSecondary : DesignTokens.textSecondary;
        break;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.0, color: color),
        SizedBox(width: DesignTokens.space0_5),
        Flexible(
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.bodySmallFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.space0_5),
          child: content,
        ),
      );
    }

    return content;
  }
}
