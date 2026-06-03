import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class StyledRange {
  const StyledRange({
    required this.start,
    required this.end,
    required this.style,
    this.priority = 0,
    this.recognizerKey,
    this.data,
  }) : assert(start >= 0),
       assert(end >= start);

  final int start;
  final int end;
  final TextStyle style;

  final int priority;

  final Object? recognizerKey;

  final Object? data;

  int get length => end - start;
  bool get isEmpty => end == start;

  StyledRange copyWith({
    int? start,
    int? end,
    TextStyle? style,
    int? priority,
    Object? recognizerKey,
    Object? data,
  }) {
    return StyledRange(
      start: start ?? this.start,
      end: end ?? this.end,
      style: style ?? this.style,
      priority: priority ?? this.priority,
      recognizerKey: recognizerKey ?? this.recognizerKey,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StyledRange &&
        other.start == start &&
        other.end == end &&
        other.style == style &&
        other.priority == priority &&
        other.recognizerKey == recognizerKey &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(start, end, style, priority, recognizerKey, data);

  @override
  String toString() => 'StyledRange($start..$end, p=$priority)';
}
