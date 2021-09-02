// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// STATUS
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

library easy_firestore;

import 'dart:async';

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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension Bool_StatusMethods on bool {
  Status get toStatus => this ? Status.TRUE : Status.FALSE;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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
