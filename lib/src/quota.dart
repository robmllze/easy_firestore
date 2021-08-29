// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// EZ QUOTA
//
// Coded by Robert Mollentze
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

library easy_firestore;

import 'math.dart' show roundToFigures;

import 'package:prep/prep.dart' show PrepLog;

const _LOG = PrepLog.file("<#f=quota.dart>");

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const int _SPARK_QUOTA_DELETE = 20000;
const int _SPARK_QUOTA_READ = 50000;
const int _SPARK_QUOTA_WRITE = 20000;
const double _BLAZE_RATE_DELETE = 0.2 / 100000;
const double _BLAZE_RATE_READ = 0.06 / 100000;
const double _BLAZE_RATE_WRITE = 0.18 / 100000;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

_Quota quota = _Quota();

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _Quota {
  //
  //
  //

  static final _Quota _fsQuota = _Quota._();
  factory _Quota() => _fsQuota;
  void init() => null;

  //
  //
  //

  _Quota._() {
    this._tStart = DateTime.now().microsecondsSinceEpoch;
  }

  //
  //
  //

  int _tStart = 0;
  int _deletes = 0;
  int _reads = 0;
  int _writes = 0;
  int get deletes => this._deletes;
  int get reads => this._reads;
  int get writes => this._writes;

  //
  //
  //

  void _checkQuotaDeletes() {
    // TODO: Calculate average delete usage to determine _MAX.
    const double _MAX = 0.1 * _SPARK_QUOTA_DELETE;
    if (this._deletes > 0.1 * _MAX) {
      _LOG.warning(
        "Exceeded $_MAX deletes!",
        "<#l=71>",
      );
    }
  }

  void _checkQuotaReads() {
    // TODO: Calculate average read usage to determine _MAX.
    const double _MAX = 0.1 * _SPARK_QUOTA_READ;
    if (this._reads > _MAX) {
      _LOG.warning(
        "Exceeded $_MAX reads!",
        "<#l=82>",
      );
    }
  }

  void _checkQuotaWrites() {
    // TODO: Calculate average write usage to determine _MAX.
    const double _MAX = 0.1 * _SPARK_QUOTA_WRITE;
    if (this._writes > _MAX) {
      _LOG.warning(
        "Exceeded $_MAX writes!",
        "<#l=93>",
      );
    }
  }

  //
  //
  //

  void regDelete([final int delta = 1]) {
    this._deletes += delta;
    this._checkQuotaDeletes();
  }

  void regRead([final int delta = 1]) {
    this._reads += delta;
    this._checkQuotaReads();
  }

  void regWrite([final int delta = 1]) {
    this._writes += delta;
    this._checkQuotaWrites();
  }

  //
  //
  //

  void reset() {
    this._deletes = 0;
    this._reads = 0;
    this._writes = 0;
    this._tStart = DateTime.now().microsecondsSinceEpoch;
  }

  //
  //
  //

  Map<String, num> get report {
    final int _tTo = DateTime.now().microsecondsSinceEpoch;
    final int _delta = _tTo - this._tStart;
    final double _deltaAsSeconds = _delta / 1e6;
    final double _costDeletes = this.deletes * _BLAZE_RATE_DELETE;
    final double _costReads = this.reads * _BLAZE_RATE_READ;
    final double _costWrites = this.writes * _BLAZE_RATE_WRITE;
    final double _costTotal = _costDeletes + _costReads + _costWrites;
    return {
      "<t>from": this._tStart,
      "<t>to": _tTo,
      "<i>t_delta": _delta,
      "<d>cost_usd_deletes": roundToFigures(_costDeletes, 3),
      "<d>cost_usd_reads": roundToFigures(_costReads, 3),
      "<d>cost_usd_total_per_year": roundToFigures(365.25 * _costTotal, 3),
      "<d>cost_usd_total_per_year_hour":
          roundToFigures(25 * 365.25 * _costTotal, 3),
      "<d>cost_usd_total": roundToFigures(_costTotal, 3),
      "<d>cost_usd_writes": roundToFigures(_costWrites, 3),
      "<d>deletes_per_second":
          roundToFigures(this._deletes / _deltaAsSeconds, 3),
      "<d>reads_per_second": roundToFigures(this.reads / _deltaAsSeconds, 3),
      "<d>writes_per_second": roundToFigures(this.writes / _deltaAsSeconds, 3),
      "<i>deletes": this._deletes,
      "<i>reads": this.reads,
      "<i>writes": this.writes,
    };
  }
}