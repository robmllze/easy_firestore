// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// UTILS
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

library easy_firestore;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prep/prep.dart' show PrepLog;

import 'math.dart';
import 'misc.dart';
import 'quota.dart';
import 'status.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const _LOG = PrepLog.file("<#f=utils.dart>");
const _TIMEOUT_TRANSACTION_DEFAULT = 30;

final _fs = FirebaseFirestore.instance;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// MEASURE
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ResultTestSpeed {
  final double mbpsUpload;
  final double mbpsDownload;
  final double mbpsDelete;
  final double mbpsAverageUploadDownload;
  final double mbpsAverage;
  ResultTestSpeed({
    required this.mbpsUpload,
    required this.mbpsDownload,
    required this.mbpsDelete,
    required this.mbpsAverage,
    required this.mbpsAverageUploadDownload,
  });
  Map<String, double> toMapExact() => {
        "mbps_upload": mbpsUpload,
        "mbps_download": mbpsDownload,
        "mbps_delete": mbpsDelete,
        "mbps_average_upload_download": mbpsAverageUploadDownload,
        "mbps_average": mbpsAverage,
      };
  static _round(double x) => roundAt(roundToFigures(x, 3), 6);
  Map<String, double> toMap() => {
        "mbps_upload": _round(mbpsUpload),
        "mbps_download": _round(mbpsDownload),
        "mbps_delete": _round(mbpsDelete),
        "mbps_average_upload_download": _round(mbpsAverageUploadDownload),
        "mbps_average": _round(mbpsAverage),
      };
}

//
//
//

/// Returns Firebase connection speed information, or null if timed out or if
/// an error occurred. The accuracy and performance can be changed by changing
/// `dummySize`, the size of the dummy data to test in bytes.
///
/// Firestore doesn't allow handling more than 1048487 bytes at a time so
/// `dummySize` cannot exceed this limit.
///
/// NB: Be mindful of Firebase data charges.
Future<ResultTestSpeed?> testSpeed([
  final int dummySize = 1048487,
  final timeout = const Duration(seconds: 10),
]) {
  assert(dummySize > 0);
  assert(!timeout.isNegative);
  final _dummy = "#" * dummySize;
  final _ref = _fs.collection("#").doc(generateUuid());
  final _tStart = Timestamp.now().microsecondsSinceEpoch;
  quota.regDelete();
  quota.regRead();
  quota.regWrite();
  return Future<ResultTestSpeed?>(() async {
    return await _ref
        .set({"#": _dummy}, SetOptions(merge: true)).then((_) async {
      final _tUploaded = Timestamp.now().microsecondsSinceEpoch;
      return await _ref.get().then((__doc) async {
        if (__doc.exists) {
          final _tDownload = Timestamp.now().microsecondsSinceEpoch;
          return await _ref.delete().then((_) {
            final _tDeleted = Timestamp.now().microsecondsSinceEpoch;
            final _rateUpload = 8.0 * dummySize / (_tUploaded - _tStart);
            final _rateDownload = 8.0 * dummySize / (_tDownload - _tUploaded);
            final _rateDeleted = 8.0 * dummySize / (_tDeleted - _tDownload);
            final _rateAverageUploadDownload =
                0.5 * (_rateUpload + _rateDownload);
            final _rateAverage =
                0.5 * (_rateDeleted + _rateAverageUploadDownload);
            return ResultTestSpeed(
              mbpsUpload: _rateUpload,
              mbpsDownload: _rateDownload,
              mbpsDelete: _rateDeleted,
              mbpsAverageUploadDownload: _rateAverageUploadDownload,
              mbpsAverage: _rateAverage,
            );
          });
        }
        return null;
      });
    }).catchError((e) {
      _LOG.error(
        "Failed to test speed: $e.",
        "<#l=115>",
      );
    });
  }).timeout(
    timeout,
    onTimeout: () {
      _LOG.error(
        "speed test timed out.",
        "<#l=123>",
      );
    },
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// CHECK
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Status> check() {
  final _ref = _fs.collection("#").doc(generateUuid());
  quota.regDelete();
  quota.regRead();
  quota.regWrite();
  return _ref
      .set({}, SetOptions(merge: true))
      .then((_) => _ref.get().then((__doc) {
            if (__doc.exists) {
              _ref.delete();
              return Status.TRUE;
            }
            return Status.FALSE;
          }))
      .catchError((_) => Status.ERROR);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// GET
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Map<String, dynamic>?> getDoc(
  final String nameColl,
  final String nameDoc, {
  final Map<String, dynamic>? Function()? onErr,
}) {
  quota.regRead();
  return _fs.collection(nameColl).doc(nameDoc).get().then((__doc) {
    if (__doc.exists) {
      final _data = __doc.data();
      if (_data == null) {
        _LOG.alert(
          "Empty doc.",
          "<#l=170>",
        );
      }
      return _data;
    } else {
      throw "No doc.";
    }
  }).catchError((e) {
    _LOG.error(
      "Failed to get doc $nameColl/$nameDoc: $e",
      "<#l=180>",
    );
    return onErr?.call() ?? null;
  });
}

//
//
//

Future<Map<String, dynamic>?> getDocTr(
  final String nameColl,
  final String nameDoc, {
  final Map<String, dynamic>? Function()? onErr,
}) {
  final _doc = _fs.collection(nameColl).doc(nameDoc);
  quota.regRead();
  return _fs
      .runTransaction(
          (__tr) async => await __tr.get(_doc).then((__doc) {
                if (__doc.exists) {
                  final _data = __doc.data();
                  if (_data == null) {
                    _LOG.alert(
                      "Empty doc.",
                      "<#l=205>",
                    );
                  }
                  return _data;
                } else {
                  throw "No doc.";
                }
              }),
          timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT))
      .catchError((e) {
    _LOG.error(
      "Failed to get doc $nameColl/$nameDoc: $e",
      "<#l=217>",
    );
    return onErr?.call() ?? null;
  });
}

//
//
//

Future<Map<String, dynamic>?> getDoc1(
  final String nameColl,
  final String nameDoc, {
  final bool transaction = false,
  final Map<String, dynamic>? Function()? onErr,
}) =>
    transaction
        ? getDocTr(
            nameColl,
            nameDoc,
            onErr: onErr,
          )
        : getDoc(
            nameColl,
            nameDoc,
            onErr: onErr,
          );

//
//
//

Future<dynamic> getField(
  final String nameColl,
  final String nameDoc,
  final String nameField, {
  final dynamic Function()? onErr,
}) {
  return getDoc(
    nameColl,
    nameDoc,
    onErr: () => DOC_ERROR,
  ).then((__data) {
    if (__data == DOC_ERROR) return onErr?.call() ?? null;
    if (__data != null) {
      final _field = __data[nameField];
      if (_field == null) {
        _LOG.alert(
          "Empty field.",
          "<#l=266>",
        );
      }
      return _field;
    }
    return null;
  });
}

//
//
//

Future<dynamic> getFieldTr(
  final String nameColl,
  final String nameDoc,
  final String nameField, {
  final dynamic Function()? onErr,
}) {
  return getDocTr(
    nameColl,
    nameDoc,
    onErr: () => DOC_ERROR,
  ).then((__data) {
    if (__data == DOC_ERROR) return onErr?.call() ?? null;
    if (__data != null) {
      final _field = __data[nameField];
      if (_field == null) {
        _LOG.alert(
          "Empty field.",
          "<#l=296>",
        );
      }
      return _field;
    }
    return null;
  });
}

//
//
//

Future<dynamic> getField1(
  final String nameColl,
  final String nameDoc,
  final String nameField, {
  final bool transaction = false,
  final dynamic Function()? onErr,
}) =>
    transaction
        ? getFieldTr(
            nameColl,
            nameDoc,
            nameField,
            onErr: onErr,
          )
        : getField(
            nameColl,
            nameDoc,
            nameField,
            onErr: onErr,
          );

//
//
//

Future<List<QueryDocumentSnapshot>?> getDocs(
  final String nameColl,
) {
  quota.regRead();
  return _fs.collection(nameColl).get().then((__query) {
    if (__query.size != 0) {
      return __query.docs;
    } else {
      _LOG.error(
        "Failed to get docs. Empty coll.",
        "<#l=344>",
      );
      return null;
    }
  }).catchError((e) {
    _LOG.error(
      "Failed to get docs at $nameColl: $e",
      "<#l=351>",
    );
    return null;
  });
}

//
//
//

Future<List<String>?> getNamesDocs(
  final String nameColl,
) {
  return getDocs(nameColl).then((__queryDocs) {
    if (__queryDocs != null) {
      final _namesDocs = <String>[];
      __queryDocs.forEach((_queryDoc) {
        _namesDocs.add(_queryDoc.id);
      });
      return _namesDocs;
    }
    return null;
  });
}

//
//
//

Future<int?> getCountDocs(
  final String nameColl,
) {
  return getDocs(nameColl).then((__queryDocs) {
    if (__queryDocs != null) {
      return __queryDocs.length;
    }
    return null;
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// SET
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Status> setDoc(
  final String nameColl,
  final String nameDoc,
  final Map<String, dynamic> data, {
  final bool merge = true,
  final bool overwrite = true,
}) {
  quota.regWrite();
  final _doc = _fs.collection(nameColl).doc(nameDoc);
  return Future<Status>(
    () async => overwrite || await _doc.get().then((__doc) => !__doc.exists)
        ? await _doc
            .set(data, SetOptions(merge: merge))
            .then((_) => Status.TRUE)
            .catchError((e) {
            _LOG.error(
              "Failed to set doc $nameColl/$nameDoc: $e",
              "<#l=414>",
            );
            return Status.ERROR;
          })
        : Status.UNCHANGED,
  );
}

//
//
//

Future<Status> setDocTr(
  final String nameColl,
  final String nameDoc,
  final Map<String, dynamic> value, {
  final bool merge = true,
  final bool overwrite = true,
}) {
  quota.regWrite();
  final _doc = _fs.collection(nameColl).doc(nameDoc);
  return _fs.runTransaction((__tr) async {
    if (overwrite ||
        await __tr.get(_doc).then((__doc) {
          return !__doc.exists;
        }).whenComplete(() => quota.regRead())) {
      __tr.set(_doc, value, SetOptions(merge: merge));
      return Status.TRUE;
    }
    return Status.UNCHANGED;
  }, timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT)).catchError((e) {
    _LOG.error(
      "Failed to set doc $nameColl/$nameDoc: $e",
      "<#l=447>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> setDoc1(
  final String nameColl,
  final String nameDoc,
  final Map<String, dynamic> value, {
  final bool merge = true,
  final bool overwrite = true,
  final bool transaction = false,
}) =>
    transaction
        ? setDocTr(
            nameColl,
            nameDoc,
            value,
            merge: merge,
            overwrite: overwrite,
          )
        : setDoc(
            nameColl,
            nameDoc,
            value,
            merge: merge,
            overwrite: overwrite,
          );

//
//
//

Future<Status> setField1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final dynamic valueField, {
  final bool merge = true,
  final bool overwrite = true,
  final bool transaction = false,
}) =>
    transaction
        ? setDocTr(
            nameColl,
            nameDoc,
            {nameField: valueField},
            merge: merge,
            overwrite: overwrite,
          )
        : setDoc(
            nameColl,
            nameDoc,
            {nameField: valueField},
            merge: merge,
            overwrite: overwrite,
          );

//
//
//

Future<Status> setDocEmpty(
  final String nameColl,
  final String nameDoc,
  final Map<String, dynamic> value, {
  final bool merge = true,
  final bool overwrite = true,
  final bool transaction = false,
}) =>
    transaction
        ? setDocTr(
            nameColl,
            nameDoc,
            DOC_EMPTY,
            merge: false,
            overwrite: overwrite,
          )
        : setDoc(
            nameColl,
            nameDoc,
            DOC_EMPTY,
            merge: false,
            overwrite: overwrite,
          );

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// BATCH
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ElDoc {
  final String nameColl;
  final String nameDoc;
  final Map<String, dynamic>? value;
  ElDoc({
    required this.nameColl,
    required this.nameDoc,
    this.value,
  });
}

//
//
//

class ElField {
  final String nameColl;
  final String nameDoc;
  final String nameField;
  final dynamic valueField;
  ElField({
    required this.nameColl,
    required this.nameDoc,
    required this.nameField,
    this.valueField,
  });
}

//
//
//

Future<Status> setBatch(final List<ElDoc> all) {
  final _batch = _fs.batch();
  all.forEach((__el) => _batch.set(
      _fs.collection(__el.nameColl).doc(__el.nameDoc),
      __el.value,
      SetOptions(merge: true)));
  quota.regWrite(all.length);
  return _batch.commit().then((_) => Status.TRUE).catchError((e) {
    _LOG.error(
      "Failed to set batch: $e",
      "<#l=586>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> deleteBatch(final List<ElDoc> all) {
  final WriteBatch _batch = _fs.batch();
  all.forEach((__el) => _batch.delete(
        _fs.collection(__el.nameColl).doc(__el.nameDoc),
      ));
  quota.regDelete(all.length);
  return _batch.commit().then((_) => Status.TRUE).catchError((e) {
    _LOG.error(
      "Failed to delete batch: $e",
      "<#l=605>",
    );
    return Status.ERROR;
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// COPY
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Status> copyDoc1(
  final String nameCollSrc,
  final String nameDocSrc,
  final String nameCollDst,
  final String nameDocDst, {
  bool transaction = false,
}) {
  return getDoc1(
    nameCollSrc,
    nameDocSrc,
    transaction: transaction,
  ).then((__value) async {
    return (__value != null).toStatus &
        () => setDoc1(
              nameCollDst,
              nameDocDst,
              __value!,
              transaction: transaction,
            );
  });
}

//
//
//

Future<Status> copyField1(
  final String nameCollSrc,
  final String nameDocSrc,
  final String nameFieldsrc,
  final String nameCollDst,
  final String nameDocDst,
  final String nameFieldDst, {
  bool transaction = false,
}) {
  return getField1(
    nameCollSrc,
    nameDocSrc,
    nameFieldsrc,
    transaction: transaction,
    onErr: () => Status.ERROR,
  ).then((__value) async {
    if (__value != Status.ERROR) {
      return await setField1(
        nameCollDst,
        nameDocDst,
        nameFieldDst,
        __value,
        transaction: transaction,
      );
    }
    return Status.ERROR;
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// FIELD OPERATIONS
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Status> increment(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final num valueDelta,
) =>
    setField1(
      nameColl,
      nameDoc,
      nameField,
      FieldValue.increment(valueDelta),
      merge: true,
      transaction: false,
    );

//
//
//

Future<Status> multiply1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final num valueFieldFactor, {
  final num valueFieldDefault = 1.0,
  final bool create = true,
  final bool transaction = false,
}) =>
    getSetField1(
      nameColl,
      nameDoc,
      nameField,
      (__value) =>
          __value is num ? __value * valueFieldFactor : valueFieldDefault,
      create: create,
      merge: true,
      transaction: transaction,
    );

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Status> fieldListAdd1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final List items, {
  final bool exportAsUnique = false,
  final bool transaction = false,
}) {
  return getSetField1(
    nameColl,
    nameDoc,
    nameField,
    (__value) {
      if (__value is List) {
        __value.addAll(items);
      } else if (__value == null) {
        __value = items;
      } else {
        _LOG.error(
          "Failed to add item(s). Field value not a list or null.",
          "<#l=739>",
        );
        __value = null;
      }
      return exportAsUnique ? __value?.toset() : __value;
    },
    transaction: transaction,
  );
}

//
//
//

Future<Status> fieldListRemoveFirst1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final List items, {
  final bool exportAsUnique = false,
  final bool transaction = false,
}) {
  return getSetField1(
    nameColl,
    nameDoc,
    nameField,
    (__value) {
      if (__value is List) {
        for (final el in items) {
          __value.remove(el);
        }
      } else if (__value != null) {
        _LOG.error(
          "Failed to remove item(s). Field value not a list or null.",
          "<#l=773>",
        );
        __value = null;
      }
      return exportAsUnique ? __value?.toset() : __value;
    },
    transaction: transaction,
  );
}

//
//
//

Future<Status> fieldListRemoveAll1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final List items, {
  final bool exportAsUnique = false,
  final bool transaction = false,
}) {
  return getSetField1(
    nameColl,
    nameDoc,
    nameField,
    (__value) {
      if (__value is List) {
        for (final el in items) {
          while (__value.remove(el)) {}
        }
      } else if (__value != null) {
        _LOG.error(
          "Failed to remove item(s). Field value not a list or null.",
          "<#l=807>",
        );
        __value = null;
      }
      return exportAsUnique ? __value?.toset() : __value;
    },
    transaction: transaction,
  );
}

//
//
//

Future<Status> fieldListContains1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final List items, {
  final bool transaction = false,
}) {
  return getField1(
    nameColl,
    nameDoc,
    nameField,
    transaction: transaction,
  ).then((__value) {
    if (__value is List) {
      for (final el in items) {
        if (__value.contains(el)) {
          return Status.TRUE;
        }
      }
    }
    if (__value != null) {
      _LOG.error(
        "Failed to check containment of item(s). "
            "Field value not a list or null.",
        "<#l=845>",
      );
      return Status.ERROR;
    }
    return Status.FALSE;
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// GET AND SET
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef GetSetDocFn = FutureOr<Map<String, dynamic>?> Function(
    Map<String, dynamic>?);

typedef GetSetFieldFn = FutureOr<dynamic> Function(dynamic);

//
//
//

Future<Status> getSetDoc(
  final String nameColl,
  final String nameDoc,
  final GetSetDocFn getSet, {
  final bool create = false,
  final bool merge = true,
}) {
  return getDoc(nameColl, nameDoc).then((__old) async {
    if (!create && __old == null) return Status.FALSE;
    final _new = await getSet(__old);
    return _new != null
        ? (await setDoc(
            nameColl,
            nameDoc,
            _new,
            merge: merge,
            overwrite: true,
          ))
        : Status.FALSE;
  });
}

//
//
//

Future<Status> getSetField(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final GetSetFieldFn getSet, {
  final bool create = false,
  final bool merge = true,
}) {
  return getField(nameColl, nameDoc, nameField).then((__old) async {
    if (!create && __old == null) return Status.FALSE;
    final _new = await getSet(__old);
    return _new != null
        ? (await setField1(
            nameColl,
            nameDoc,
            nameField,
            _new,
            merge: merge,
          ))
        : Status.FALSE;
  });
}

//
//
//

Future<Status> getSetDocTr(
  final String nameColl,
  final String nameDoc,
  final GetSetDocFn getSet, {
  final bool create = false,
  final bool merge = true,
}) {
  final _doc = _fs.collection(nameColl).doc(nameDoc);
  quota.regRead();
  quota.regWrite();
  return _fs
      .runTransaction(
          (__tr) async => await __tr.get(_doc).then((final __doc) async {
                if (!create && !__doc.exists) return Status.FALSE;
                final _old = __doc.data();
                final _new = await getSet(_old);
                if (_new != null) {
                  __tr.set(_doc, _new, SetOptions(merge: merge));
                  return Status.TRUE;
                }
                return Status.FALSE;
              }),
          timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT))
      .catchError((e) {
    _LOG.error(
      "Failed to get and set doc $nameColl/$nameDoc: $e",
      "<#l=947>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> getSetDoc1(
  final String nameColl,
  final String nameDoc,
  final GetSetDocFn getSet, {
  final bool create = false,
  final bool merge = true,
  final bool transaction = false,
}) =>
    transaction
        ? getSetDocTr(
            nameColl,
            nameDoc,
            getSet,
            create: create,
            merge: merge,
          )
        : getSetDoc(
            nameColl,
            nameDoc,
            getSet,
            create: create,
            merge: merge,
          );

//
//
//

Future<Status> getSetFieldTr(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final GetSetFieldFn getSet, {
  final bool create = false,
  final bool merge = true,
}) {
  final _doc = _fs.collection(nameColl).doc(nameDoc);
  quota.regRead();
  quota.regWrite();
  return _fs
      .runTransaction(
          (__tr) async => await __tr.get(_doc).then((__doc) async {
                final _old = __doc.data()?[nameField];
                if (!create && _old == null) return Status.FALSE;
                final _new = await getSet(_old);
                if (_new != null) {
                  __tr.set(_doc, {nameField: _new}, SetOptions(merge: merge));
                  return Status.TRUE;
                }
                return Status.FALSE;
              }),
          timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT))
      .catchError((e) {
    _LOG.error(
      "Failed to get and set field $nameColl/$nameDoc/$nameField: $e",
      "<#l=1012>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> getSetField1(
  final String nameColl,
  final String nameDoc,
  final String nameField,
  final GetSetFieldFn getSet, {
  final bool create = false,
  final bool merge = true,
  final bool transaction = false,
}) =>
    transaction
        ? getSetFieldTr(
            nameColl,
            nameDoc,
            nameField,
            getSet,
            create: create,
            merge: merge,
          )
        : getSetField(
            nameColl,
            nameDoc,
            nameField,
            getSet,
            create: create,
            merge: merge,
          );

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// DELETE
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Deletes a document on Firebase via a transaction.
Future<Status> deleteDocTr(
  final String nameColl,
  final String nameDoc,
) {
  final _doc = _fs.collection(nameColl).doc(nameDoc);
  return _fs.runTransaction((__tr) async {
    __tr.delete(_doc);
    return Status.TRUE;
  }, timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT)).catchError((e) {
    _LOG.error(
      "Failed to delete doc $nameColl/$nameDoc: $e",
      "<#l=1067>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> deleteField(
  final String nameColl,
  final String nameDoc,
  final String nameField,
) =>
    setField1(
      nameColl,
      nameDoc,
      nameField,
      FieldValue.delete(),
      transaction: false,
    );

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//
// EXISTS
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Future<Status> existsColl(
  final String nameColl,
) {
  quota.regRead();
  return _fs
      .collection(nameColl)
      .get()
      .then((__query) => __query.size > 0 ? Status.TRUE : Status.FALSE)
      .catchError((e) {
    _LOG.error(
      "Failed to check existence at $nameColl: $e",
      "<#l=1107>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> existsDoc(
  final String nameColl,
  final String nameDoc,
) {
  quota.regRead();
  return _fs
      .collection(nameColl)
      .doc(nameDoc)
      .get()
      .then((__doc) => __doc.exists ? Status.TRUE : Status.FALSE)
      .catchError((e) {
    _LOG.error(
      "Failed to check existence. $nameColl/$nameDoc: $e",
      "<#l=1130>",
    );
    return Status.ERROR;
  });
}
//
//
//

Future<Status> existsDocTr(
  final String nameColl,
  final String nameDoc,
) {
  quota.regRead();
  return _fs
      .runTransaction(
          (__tr) async => await __tr
              .get(_fs.collection(nameColl).doc(nameDoc))
              .then((__doc) => __doc.exists ? Status.TRUE : Status.FALSE),
          timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT))
      .catchError((e) {
    _LOG.error(
      "Failed to check existence of doc $nameColl/$nameDoc: $e",
      "<#l=1153>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> existsDoc1(
  final String nameColl,
  final String nameDoc, {
  final bool transaction = false,
}) =>
    transaction
        ? existsDocTr(
            nameColl,
            nameDoc,
          )
        : existsDoc(
            nameColl,
            nameDoc,
          );

//
//
//

Future<Status> existsField(
  final String nameColl,
  final String nameDoc,
  final String nameField,
) {
  quota.regRead();
  return _fs
      .collection(nameColl)
      .doc(nameDoc)
      .get()
      .then((__doc) =>
          __doc.data()?[nameField] != null ? Status.TRUE : Status.FALSE)
      .catchError((e) {
    _LOG.error(
      "Failed to check existence of field $nameColl/$nameDoc/$nameField: $e",
      "<#l=1197>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> existsFieldTr(
  final String nameColl,
  final String nameDoc,
  final String nameField,
) {
  final _firestore = _fs;
  quota.regRead();
  return _firestore
      .runTransaction(
          (__tr) async => await __tr
              .get(_firestore.collection(nameColl).doc(nameDoc))
              .then((__doc) => __doc.data()?[nameField] != null
                  ? Status.TRUE
                  : Status.FALSE),
          timeout: Duration(seconds: _TIMEOUT_TRANSACTION_DEFAULT))
      .catchError((e) {
    _LOG.error(
      "Failed to check existence of field $nameColl/$nameDoc/$nameField: $e",
      "<#l=1224>",
    );
    return Status.ERROR;
  });
}

//
//
//

Future<Status> existsField1(
  final String nameColl,
  final String nameDoc,
  final String nameField, {
  final bool transaction = false,
}) =>
    transaction
        ? existsFieldTr(
            nameColl,
            nameDoc,
            nameField,
          )
        : existsField(
            nameColl,
            nameDoc,
            nameField,
          );
