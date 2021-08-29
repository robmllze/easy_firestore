// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// MISC
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

library easy_firestore;

import 'dart:async';

import 'package:uuid/uuid.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// UUID
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Generates a UUID or Unique User ID consisting only of numbers and letters.
String generateUuid() => Uuid().v4().replaceAll("-", "");

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// STATE
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

enum State {
  // Function ended as intended with TRUE (equal to bool: true)
  TRUE,
  // Function ended as intended with FALSE (equal to bool: false)
  FALSE,
  // Function made no changes (equal to bool: true)
  UNCHANGED,
  // Function did not end as intended (equal to bool: false)
  ERROR
}

// ─────────────────────────────────────────────────────────────────────────────

extension State_Methods on State {
  //
  //
  //

  String asString() => this.toString().split(".")[1];

  //
  //
  //

  bool toBool() {
    final String _stringValue = this.asString();
    return (_stringValue == "TRUE" || _stringValue == "UNCHANGED")
        ? true
        : false;
  }

  //
  //
  //

  State fromBool(final bool value) => value ? State.TRUE : State.FALSE;

  //
  //
  //

  FutureOr<State> and(final FutureOr<State> Function()? other) {
    if (this == State.ERROR) return State.ERROR;
    if (this == State.FALSE) return State.FALSE;
    final FutureOr<State>? _other = other?.call();
    if (_other == State.ERROR) return State.ERROR;
    if (_other == State.FALSE) return State.FALSE;
    if (this == State.UNCHANGED && _other == State.UNCHANGED)
      return State.UNCHANGED;
    return State.TRUE;
  }

  FutureOr<State> operator &(final FutureOr<State> Function()? other) =>
      this.and(other);

  //
  //
  //

  FutureOr<State> or(final FutureOr<State> Function()? other) {
    if (this == State.TRUE) return State.TRUE;
    if (other?.call() == State.TRUE) return State.TRUE;
    return State.FALSE;
  }

  FutureOr<State> operator |(final FutureOr<State> Function()? other) =>
      this.or(other);
}

// ─────────────────────────────────────────────────────────────────────────────

extension Bool_StateMethods on bool {
  State get toState => this ? State.TRUE : State.FALSE;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// KEY ERROR
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A string used signal an error.
const String KEY_ERROR = "'`ERROR`'";

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// DOC ERROR
//
// Error handling scheme for functions returning Maps or dynamics.
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const Map<String, dynamic> DOC_ERROR = const {KEY_ERROR: null};
const Map<String, dynamic> DOC_EMPTY = const {};

//
//
//

Map<String, dynamic> docError([e]) => {KEY_ERROR: e};

//
//
//

bool isDocError(final dynamic docError, [e]) =>
    docError is Map<String, dynamic> &&
    docError.keys.first == KEY_ERROR &&
    (e == null || e == docError.values.first);

//
//
//

dynamic getDocErrorE(final dynamic docError) =>
    docError is Map<String, dynamic> && docError.values.first;