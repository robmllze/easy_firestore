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
// Status
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

enum Status {
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

extension Status_Methods on Status {
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

  Status fromBool(final bool value) => value ? Status.TRUE : Status.FALSE;

  //
  //
  //

  FutureOr<Status> and(final FutureOr<Status> Function()? other) {
    if (this == Status.ERROR) return Status.ERROR;
    if (this == Status.FALSE) return Status.FALSE;
    final FutureOr<Status>? _other = other?.call();
    if (_other == Status.ERROR) return Status.ERROR;
    if (_other == Status.FALSE) return Status.FALSE;
    if (this == Status.UNCHANGED && _other == Status.UNCHANGED)
      return Status.UNCHANGED;
    return Status.TRUE;
  }

  FutureOr<Status> operator &(final FutureOr<Status> Function()? other) =>
      this.and(other);

  //
  //
  //

  FutureOr<Status> or(final FutureOr<Status> Function()? other) {
    if (this == Status.TRUE) return Status.TRUE;
    if (other?.call() == Status.TRUE) return Status.TRUE;
    return Status.FALSE;
  }

  FutureOr<Status> operator |(final FutureOr<Status> Function()? other) =>
      this.or(other);
}

// ─────────────────────────────────────────────────────────────────────────────

extension Bool_StatusMethods on bool {
  Status get toStatus => this ? Status.TRUE : Status.FALSE;
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
