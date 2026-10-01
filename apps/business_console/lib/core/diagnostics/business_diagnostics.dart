import 'dart:collection';

enum BusinessDiagnosticCode {
  flutterFrameworkError,
  platformUncaughtError,
  zoneUncaughtError,
}

enum BusinessDiagnosticSource {
  flutterFramework,
  platformDispatcher,
  guardedZone,
}

typedef BusinessDiagnosticClock = DateTime Function();

class BusinessDiagnosticEvent {
  const BusinessDiagnosticEvent({
    required this.sequence,
    required this.code,
    required this.source,
    required this.occurredAtUtc,
  });

  final int sequence;
  final BusinessDiagnosticCode code;
  final BusinessDiagnosticSource source;
  final DateTime occurredAtUtc;

  Map<String, Object> toSafeMap() => <String, Object>{
    'sequence': sequence,
    'code': code.name,
    'source': source.name,
    'occurredAtUtc': occurredAtUtc.toIso8601String(),
  };
}

/// Privacy-safe, memory-only diagnostics for Phase 11 preproduction evidence.
///
/// It intentionally excludes exception messages, stack traces, user-entered
/// content, tenant payloads, credentials, payment data, traveler data and
/// network telemetry.
class BusinessDiagnostics {
  BusinessDiagnostics({
    this.capacity = defaultCapacity,
    BusinessDiagnosticClock? clock,
  }) : _clock = clock ?? _utcNow {
    if (capacity <= 0 || capacity > maximumCapacity) {
      throw ArgumentError.value(
        capacity,
        'capacity',
        'must be between 1 and $maximumCapacity',
      );
    }
  }

  static const int defaultCapacity = 64;
  static const int maximumCapacity = 256;

  static const bool persistsDiagnostics = false;
  static const bool externalTelemetryEnabled = false;

  static final BusinessDiagnostics instance = BusinessDiagnostics();

  final int capacity;
  final BusinessDiagnosticClock _clock;
  final ListQueue<BusinessDiagnosticEvent> _events =
      ListQueue<BusinessDiagnosticEvent>();

  int _nextSequence = 1;

  void record({
    required BusinessDiagnosticCode code,
    required BusinessDiagnosticSource source,
  }) {
    if (_events.length == capacity) {
      _events.removeFirst();
    }

    _events.addLast(
      BusinessDiagnosticEvent(
        sequence: _nextSequence++,
        code: code,
        source: source,
        occurredAtUtc: _clock().toUtc(),
      ),
    );
  }

  List<BusinessDiagnosticEvent> snapshot() =>
      List<BusinessDiagnosticEvent>.unmodifiable(_events);

  void clear() {
    _events.clear();
  }

  static DateTime _utcNow() => DateTime.now().toUtc();
}
