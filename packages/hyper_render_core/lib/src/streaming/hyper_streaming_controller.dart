import 'dart:async';
import 'package:flutter/foundation.dart';

/// Status of an active [HyperStreamingController].
enum HyperStreamingStatus {
  /// The stream has not started or has been reset.
  idle,

  /// Tokens/chunks are actively being streamed.
  streaming,

  /// The stream completed successfully.
  completed,

  /// An error occurred during streaming.
  error,
}

/// Immutable snapshot of the streaming state at a specific point in time.
@immutable
class HyperStreamingState {
  /// Full accumulated text received so far.
  final String text;

  /// Current streaming status.
  final HyperStreamingStatus status;

  /// Error object if [status] is [HyperStreamingStatus.error].
  final Object? error;

  /// Total number of chunks/tokens appended.
  final int tokenCount;

  /// Timestamp when streaming started.
  final DateTime? startedAt;

  /// Timestamp when streaming finished.
  final DateTime? completedAt;

  /// Creates a streaming state snapshot.
  const HyperStreamingState({
    required this.text,
    required this.status,
    this.error,
    this.tokenCount = 0,
    this.startedAt,
    this.completedAt,
  });

  /// Initial idle state with empty content.
  static const HyperStreamingState initial = HyperStreamingState(
    text: '',
    status: HyperStreamingStatus.idle,
  );

  /// Whether tokens are actively streaming.
  bool get isStreaming => status == HyperStreamingStatus.streaming;

  /// Whether streaming has finished.
  bool get isCompleted => status == HyperStreamingStatus.completed;

  /// Whether an error occurred.
  bool get hasError => status == HyperStreamingStatus.error;

  /// Total elapsed duration of streaming.
  Duration get duration {
    if (startedAt == null) return Duration.zero;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  /// Average streaming speed in tokens per second (TPS).
  double get tokensPerSecond {
    final sec = duration.inMilliseconds / 1000.0;
    if (sec <= 0.001 || tokenCount == 0) return 0.0;
    return tokenCount / sec;
  }

  /// Copies this state with updated values.
  HyperStreamingState copyWith({
    String? text,
    HyperStreamingStatus? status,
    Object? error,
    int? tokenCount,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return HyperStreamingState(
      text: text ?? this.text,
      status: status ?? this.status,
      error: error ?? this.error,
      tokenCount: tokenCount ?? this.tokenCount,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HyperStreamingState &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          status == other.status &&
          error == other.error &&
          tokenCount == other.tokenCount &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(
        text,
        status,
        error,
        tokenCount,
        startedAt,
        completedAt,
      );

  @override
  String toString() =>
      'HyperStreamingState(text.len: ${text.length}, status: $status, tokens: $tokenCount, speed: ${tokensPerSecond.toStringAsFixed(1)} tps)';
}

/// High-performance controller for AI and LLM token streaming in HyperRender.
///
/// Batches incoming token chunks with frame-aligned throttling (default 16ms / ~60 FPS)
/// to prevent excessive re-parsing and UI jank during rapid SSE/WebSocket bursts.
///
/// ### Example
/// ```dart
/// final controller = HyperStreamingController();
///
/// // Option 1: Append tokens manually
/// controller.append('Hello, ');
/// controller.append('world! ');
/// controller.complete();
///
/// // Option 2: Bind directly to a Dart Stream
/// controller.bindStream(geminiApiClient.generateContentStream('...'));
///
/// // Option 3: Bind custom SDK streams
/// controller.bindCustomStream(chatCompletionStream, (chunk) => chunk.choices.first.delta.content ?? '');
/// ```
class HyperStreamingController extends ValueNotifier<HyperStreamingState> {
  /// Minimum time window between UI state notifications to prevent frame drops.
  final Duration throttleDuration;

  final StringBuffer _buffer = StringBuffer();
  StreamSubscription<dynamic>? _streamSubscription;
  Timer? _throttleTimer;
  bool _hasPendingNotify = false;
  int _tokenCount = 0;
  DateTime? _startedAt;
  DateTime? _completedAt;

  /// Creates a streaming controller.
  HyperStreamingController({
    this.throttleDuration = const Duration(milliseconds: 16),
    String initialText = '',
  }) : super(initialText.isEmpty
            ? HyperStreamingState.initial
            : HyperStreamingState(
                text: initialText,
                status: HyperStreamingStatus.idle,
              )) {
    if (initialText.isNotEmpty) {
      _buffer.write(initialText);
    }
  }

  /// Current accumulated text.
  String get text => _buffer.toString();

  /// Current streaming status.
  HyperStreamingStatus get status => value.status;

  /// Whether the stream is actively receiving tokens.
  bool get isStreaming => value.isStreaming;

  /// Whether the stream has completed.
  bool get isCompleted => value.isCompleted;

  /// Current average throughput in tokens per second.
  double get tokensPerSecond => value.tokensPerSecond;

  /// Appends a new string chunk or token to the stream.
  void append(String chunk) {
    if (value.isCompleted) {
      throw StateError(
          'Cannot append tokens to a completed streaming controller. Call reset() first.');
    }

    _startedAt ??= DateTime.now();

    _buffer.write(chunk);
    _tokenCount++;
    _scheduleThrottledNotify(HyperStreamingStatus.streaming);
  }

  /// Alias for [append].
  void appendToken(String token) => append(token);

  /// Binds this controller directly to a `Stream<String>`.
  ///
  /// Automatically listens to chunks, catches errors, and calls [complete]
  /// upon stream completion.
  StreamSubscription<String> bindStream(Stream<String> stream) {
    _streamSubscription?.cancel();
    _startedAt ??= DateTime.now();

    final sub = stream.listen(
      (chunk) => append(chunk),
      onError: (err) => error(err),
      onDone: () => complete(),
      cancelOnError: true,
    );
    _streamSubscription = sub;

    return sub;
  }

  /// Binds this controller to any arbitrary typed `Stream<T>` by providing a [mapper] function.
  ///
  /// Useful for OpenAI, Gemini, or Claude Dart SDK stream responses.
  StreamSubscription<T> bindCustomStream<T>(
    Stream<T> stream,
    String Function(T item) mapper,
  ) {
    _streamSubscription?.cancel();
    _startedAt ??= DateTime.now();

    final sub = stream.listen(
      (item) {
        final chunk = mapper(item);
        if (chunk.isNotEmpty) {
          append(chunk);
        }
      },
      onError: (err) => error(err),
      onDone: () => complete(),
      cancelOnError: true,
    );
    _streamSubscription = sub;

    return sub;
  }

  /// Pauses listening to the underlying bound stream.
  void pause() {
    _streamSubscription?.pause();
  }

  /// Resumes listening to the underlying bound stream.
  void resume() {
    _streamSubscription?.resume();
  }

  /// Cancels the underlying bound stream subscription without clearing received tokens.
  void cancel() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
  }

  /// Marks the stream as completed.
  ///
  /// Flushes any pending buffered tokens immediately without waiting for the
  /// throttle timer.
  void complete() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _completedAt = DateTime.now();

    value = HyperStreamingState(
      text: _buffer.toString(),
      status: HyperStreamingStatus.completed,
      tokenCount: _tokenCount,
      startedAt: _startedAt,
      completedAt: _completedAt,
    );
  }

  /// Marks the stream with an error.
  void error(Object errorObject) {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _completedAt = DateTime.now();

    value = HyperStreamingState(
      text: _buffer.toString(),
      status: HyperStreamingStatus.error,
      error: errorObject,
      tokenCount: _tokenCount,
      startedAt: _startedAt,
      completedAt: _completedAt,
    );
  }

  /// Resets the controller back to [HyperStreamingStatus.idle] state.
  void reset({String initialText = ''}) {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _buffer.clear();
    _tokenCount = 0;
    _startedAt = null;
    _completedAt = null;

    if (initialText.isNotEmpty) {
      _buffer.write(initialText);
    }

    value = initialText.isEmpty
        ? HyperStreamingState.initial
        : HyperStreamingState(
            text: initialText,
            status: HyperStreamingStatus.idle,
          );
  }

  void _scheduleThrottledNotify(HyperStreamingStatus targetStatus) {
    if (throttleDuration == Duration.zero) {
      _flushNotify(targetStatus);
      return;
    }

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _flushNotify(targetStatus);
      _throttleTimer = Timer(throttleDuration, () {
        if (_hasPendingNotify) {
          _hasPendingNotify = false;
          _flushNotify(targetStatus);
        }
      });
    } else {
      _hasPendingNotify = true;
    }
  }

  void _flushNotify(HyperStreamingStatus targetStatus) {
    value = HyperStreamingState(
      text: _buffer.toString(),
      status: targetStatus,
      tokenCount: _tokenCount,
      startedAt: _startedAt,
      completedAt: _completedAt,
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _throttleTimer?.cancel();
    super.dispose();
  }
}
