/// Custom exceptions for HyperRender library
///
/// This file contains all custom exceptions used throughout HyperRender,
/// with helpful error messages and recovery suggestions.
library;

/// Base exception class for all HyperRender exceptions
abstract class HyperRenderException implements Exception {
  /// Human-readable error message
  final String message;

  /// Technical details about the error (optional)
  final String? details;

  /// Suggested recovery action (optional)
  final String? recovery;

  /// Original exception that caused this error (if any)
  final Object? cause;

  /// Stack trace of the original error (if any)
  final StackTrace? causeStackTrace;

  const HyperRenderException(
    this.message, {
    this.details,
    this.recovery,
    this.cause,
    this.causeStackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');

    if (details != null) {
      buffer.write('\n\nDetails: $details');
    }

    if (recovery != null) {
      buffer.write('\n\n💡 How to fix: $recovery');
    }

    if (cause != null) {
      buffer.write('\n\nCaused by: $cause');
    }

    return buffer.toString();
  }
}

// =============================================================================
// HTML/Content Parsing Exceptions
// =============================================================================

/// Thrown when HTML parsing fails
class HtmlParsingException extends HyperRenderException {
  /// Position in the HTML where the error occurred (if known)
  final int? position;

  /// The malformed HTML fragment (if available)
  final String? htmlFragment;

  const HtmlParsingException(
    super.message, {
    this.position,
    this.htmlFragment,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for malformed HTML
  factory HtmlParsingException.malformed({
    required String message,
    int? position,
    String? htmlFragment,
  }) {
    return HtmlParsingException(
      'Malformed HTML: $message',
      position: position,
      htmlFragment: htmlFragment,
      details: htmlFragment != null
          ? 'Fragment: ${htmlFragment.length > 100 ? "${htmlFragment.substring(0, 100)}..." : htmlFragment}'
          : null,
      recovery: 'Ensure HTML is well-formed with properly closed tags. '
          'Use an HTML validator to check your content.',
    );
  }

  /// Creates an exception for unclosed tags
  factory HtmlParsingException.unclosedTag({
    required String tagName,
    int? position,
  }) {
    return HtmlParsingException(
      'Unclosed tag: <$tagName>',
      position: position,
      details: 'The <$tagName> tag was opened but never closed.',
      recovery: 'Add closing tag </$tagName> or use self-closing syntax <$tagName />',
    );
  }

  /// Creates an exception for invalid tag nesting
  factory HtmlParsingException.invalidNesting({
    required String parentTag,
    required String childTag,
  }) {
    return HtmlParsingException(
      'Invalid tag nesting: <$childTag> inside <$parentTag>',
      details: 'The HTML specification does not allow <$childTag> to be nested inside <$parentTag>.',
      recovery: 'Restructure your HTML to follow proper nesting rules. '
          'For example, block elements like <div> cannot be inside inline elements like <span>.',
    );
  }
}

/// Thrown when Markdown parsing fails
class MarkdownParsingException extends HyperRenderException {
  /// Line number where the error occurred (if known)
  final int? lineNumber;

  const MarkdownParsingException(
    super.message, {
    this.lineNumber,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });
}

/// Thrown when Delta (Quill) parsing fails
class DeltaParsingException extends HyperRenderException {
  /// The operation index where parsing failed
  final int? operationIndex;

  const DeltaParsingException(
    super.message, {
    this.operationIndex,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for invalid Delta format
  factory DeltaParsingException.invalidFormat({
    required String message,
    int? operationIndex,
  }) {
    return DeltaParsingException(
      'Invalid Delta format: $message',
      operationIndex: operationIndex,
      recovery: 'Ensure your Delta document follows the Quill Delta specification. '
          'Visit https://quilljs.com/docs/delta/ for format details.',
    );
  }
}

// =============================================================================
// CSS Exceptions
// =============================================================================

/// Thrown when CSS parsing or application fails
class CssException extends HyperRenderException {
  /// The CSS property that caused the error (if applicable)
  final String? property;

  /// The CSS value that caused the error (if applicable)
  final String? value;

  const CssException(
    super.message, {
    this.property,
    this.value,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for invalid CSS property
  factory CssException.invalidProperty({
    required String property,
    String? value,
  }) {
    return CssException(
      'Invalid CSS property: $property',
      property: property,
      value: value,
      details: value != null ? 'Attempted value: $value' : null,
      recovery: 'Check that the property name is spelled correctly and is supported by HyperRender. '
          'See documentation for list of supported CSS properties.',
    );
  }

  /// Creates an exception for invalid CSS value
  factory CssException.invalidValue({
    required String property,
    required String value,
    String? expectedFormat,
  }) {
    return CssException(
      'Invalid CSS value for property "$property": $value',
      property: property,
      value: value,
      details: expectedFormat != null ? 'Expected format: $expectedFormat' : null,
      recovery: 'Ensure the value matches the expected format for this property. '
          'For example, colors should be in hex (#RRGGBB) or rgb(r,g,b) format.',
    );
  }

  /// Creates an exception for unsupported CSS feature
  factory CssException.unsupportedFeature({
    required String feature,
    String? alternative,
  }) {
    return CssException(
      'Unsupported CSS feature: $feature',
      details: 'This CSS feature is not currently supported by HyperRender.',
      recovery: alternative != null
          ? 'Consider using $alternative instead.'
          : 'Check the HyperRender documentation for supported CSS features and alternatives.',
    );
  }
}

// =============================================================================
// Rendering Exceptions
// =============================================================================

/// Thrown when rendering fails
class RenderException extends HyperRenderException {
  /// The node type that failed to render (if applicable)
  final String? nodeType;

  const RenderException(
    super.message, {
    this.nodeType,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for layout failures
  factory RenderException.layoutFailed({
    required String reason,
    String? nodeType,
  }) {
    return RenderException(
      'Layout failed: $reason',
      nodeType: nodeType,
      recovery: 'This may be caused by conflicting constraints or invalid layout parameters. '
          'Try simplifying your HTML structure or CSS styles.',
    );
  }

  /// Creates an exception for paint failures
  factory RenderException.paintFailed({
    required String reason,
    String? nodeType,
  }) {
    return RenderException(
      'Paint failed: $reason',
      nodeType: nodeType,
      recovery: 'This may be caused by invalid paint properties or resource issues. '
          'Check your CSS styles and ensure images are accessible.',
    );
  }

  /// Creates an exception for content too complex
  factory RenderException.contentTooComplex({
    required String reason,
    int? nodeCount,
  }) {
    return RenderException(
      'Content too complex to render: $reason',
      details: nodeCount != null ? 'Node count: $nodeCount' : null,
      recovery: 'Consider breaking the content into smaller chunks, using pagination, '
          'or simplifying the HTML structure. For extremely complex content, consider using WebView instead.',
    );
  }
}

/// Thrown when image loading fails
class ImageLoadException extends HyperRenderException {
  /// The image URL that failed to load
  final String url;

  /// HTTP status code (if applicable)
  final int? statusCode;

  const ImageLoadException(
    super.message, {
    required this.url,
    this.statusCode,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for network image loading failure
  factory ImageLoadException.networkError({
    required String url,
    int? statusCode,
    Object? cause,
  }) {
    final statusMessage = statusCode != null ? ' (HTTP $statusCode)' : '';
    return ImageLoadException(
      'Failed to load image from network$statusMessage',
      url: url,
      statusCode: statusCode,
      details: 'URL: $url',
      recovery: statusCode == 404
          ? 'The image was not found. Check that the URL is correct.'
          : statusCode == 403
              ? 'Access denied. The image may require authentication or have CORS restrictions.'
              : 'Check your internet connection and ensure the image URL is accessible. '
                  'Consider providing a fallback image using placeholderBuilder.',
      cause: cause,
    );
  }

  /// Creates an exception for invalid image format
  factory ImageLoadException.invalidFormat({
    required String url,
    String? format,
  }) {
    return ImageLoadException(
      'Invalid image format',
      url: url,
      details: format != null ? 'Format: $format' : 'URL: $url',
      recovery: 'Ensure the image is in a supported format (PNG, JPEG, GIF, WebP). '
          'The file may be corrupted or not actually an image.',
    );
  }

  /// Creates an exception for image too large
  factory ImageLoadException.tooLarge({
    required String url,
    int? sizeBytes,
  }) {
    final sizeStr = sizeBytes != null ? '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB' : 'unknown size';
    return ImageLoadException(
      'Image too large to load',
      url: url,
      details: 'Size: $sizeStr',
      recovery: 'Consider resizing the image before loading, using thumbnail versions, '
          'or implementing lazy loading for large images.',
    );
  }
}

// =============================================================================
// Configuration Exceptions
// =============================================================================

/// Thrown when HyperRender is configured incorrectly
class ConfigurationException extends HyperRenderException {
  /// The parameter that was misconfigured (if applicable)
  final String? parameter;

  const ConfigurationException(
    super.message, {
    this.parameter,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for invalid parameter value
  factory ConfigurationException.invalidParameter({
    required String parameter,
    required String reason,
    String? validValues,
  }) {
    return ConfigurationException(
      'Invalid parameter "$parameter": $reason',
      parameter: parameter,
      details: validValues != null ? 'Valid values: $validValues' : null,
      recovery: 'Check the HyperRender documentation for valid parameter values.',
    );
  }

  /// Creates an exception for missing required parameter
  factory ConfigurationException.missingRequired({
    required String parameter,
  }) {
    return ConfigurationException(
      'Missing required parameter: $parameter',
      parameter: parameter,
      recovery: 'Provide a value for the "$parameter" parameter.',
    );
  }

  /// Creates an exception for conflicting parameters
  factory ConfigurationException.conflictingParameters({
    required List<String> parameters,
    required String reason,
  }) {
    return ConfigurationException(
      'Conflicting parameters: ${parameters.join(", ")}',
      details: reason,
      recovery: 'Use only one of these parameters at a time, or adjust the configuration to avoid conflicts.',
    );
  }
}

// =============================================================================
// Sanitization Exceptions
// =============================================================================

/// Thrown when HTML sanitization encounters an issue
class SanitizationException extends HyperRenderException {
  /// The dangerous content that was detected (sanitized for logging)
  final String? dangerousContent;

  const SanitizationException(
    super.message, {
    this.dangerousContent,
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for XSS attack detected
  factory SanitizationException.xssDetected({
    required String attackType,
    String? sanitizedContent,
  }) {
    return SanitizationException(
      'Potential XSS attack detected: $attackType',
      dangerousContent: sanitizedContent,
      details: 'Dangerous content was found and removed during sanitization.',
      recovery: 'If this content is from a trusted source, you can disable sanitization. '
          'However, NEVER disable sanitization for user-generated content!',
    );
  }

  /// Creates an exception for sanitization failure
  factory SanitizationException.failed({
    required String reason,
    Object? cause,
  }) {
    return SanitizationException(
      'HTML sanitization failed: $reason',
      details: 'The HTML could not be sanitized safely.',
      recovery: 'Check that the HTML is well-formed. If the issue persists, '
          'consider using a simpler HTML structure or contact support.',
      cause: cause,
    );
  }
}

// =============================================================================
// Text Layout Exceptions
// =============================================================================

/// Thrown when text layout operations fail
class TextLayoutException extends HyperRenderException {
  const TextLayoutException(
    super.message, {
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for missing text content
  factory TextLayoutException.missingText() {
    return const TextLayoutException(
      'Text must be set before building TextPainter',
      recovery: 'Ensure text content is provided before attempting layout. '
          'This is likely an internal error - please report it.',
    );
  }

  /// Creates an exception for invalid text span
  factory TextLayoutException.invalidSpan({
    required String reason,
  }) {
    return TextLayoutException(
      'Invalid text span: $reason',
      recovery: 'Check that your HTML or text content is properly formatted. '
          'Ensure all text spans have valid properties.',
    );
  }

  /// Creates an exception for font loading failure
  factory TextLayoutException.fontLoadFailed({
    required String fontFamily,
    Object? cause,
  }) {
    return TextLayoutException(
      'Failed to load font: $fontFamily',
      details: 'The requested font could not be loaded.',
      recovery: 'Ensure the font is properly registered in your pubspec.yaml '
          'or use a fallback font. System fonts like "Roboto" or "-apple-system" are recommended.',
      cause: cause,
    );
  }
}

// =============================================================================
// Selection Exceptions
// =============================================================================

/// Thrown when text selection operations fail
class SelectionException extends HyperRenderException {
  const SelectionException(
    super.message, {
    super.details,
    super.recovery,
    super.cause,
    super.causeStackTrace,
  });

  /// Creates an exception for invalid selection range
  factory SelectionException.invalidRange({
    required int start,
    required int end,
    required int maxLength,
  }) {
    return SelectionException(
      'Invalid selection range: start=$start, end=$end, max=$maxLength',
      details: 'Selection range is out of bounds.',
      recovery: 'This is likely an internal error. Try restarting the app. '
          'If the issue persists, please report it with reproduction steps.',
    );
  }
}
