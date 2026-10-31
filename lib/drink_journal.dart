/// The existing JSON schema is retained. Unknown legacy fields are round-tripped.
class Drink {
  final String name;
  final int ml;
  final double percent;
  final DateTime time;
  double? priceFt;
  double? _originalPrice;
  Map<String, dynamic>? _source;
  bool _priceEdited = false;

  Drink(this.name, this.ml, this.percent, {DateTime? time, this.priceFt})
    : time = time ?? DateTime.now();

  double get alcoholGrams => ml * percent / 100 * 0.789;

  Map<String, dynamic> toJson() {
    final result = _source == null
        ? <String, dynamic>{
            'name': name,
            'ml': ml,
            'percent': percent,
            'time': time.toIso8601String(),
            if (priceFt != null) 'priceFt': priceFt,
          }
        : Map<String, dynamic>.from(_source!);
    if (_source != null && (_priceEdited || priceFt != _originalPrice)) {
      if (priceFt == null) {
        result.remove('priceFt');
      } else {
        result['priceFt'] = priceFt;
      }
    }
    return result;
  }

  Drink withPrice(double? value) {
    final result = Drink(name, ml, percent, time: time, priceFt: priceFt);
    result._source = _source == null ? null : Map.from(_source!);
    result._originalPrice = _originalPrice;
    result.priceFt = value;
    result._priceEdited = true;
    return result;
  }

  factory Drink.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final ml = json['ml'];
    final percent = json['percent'];
    final rawTime = json['time'];
    if (name is! String ||
        name.trim().isEmpty ||
        ml is! num ||
        !ml.isFinite ||
        ml != ml.roundToDouble() ||
        ml < 1 ||
        ml > 10000 ||
        percent is! num ||
        !percent.isFinite ||
        percent < 0 ||
        percent > 100 ||
        rawTime is! String) {
      throw const FormatException('Invalid journal record');
    }
    final time = DateTime.tryParse(rawTime);
    // DateTime.parse normalizes dates such as February 31; do not silently do so.
    final date = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:[.,]\d+)?(?:Z|[+-](\d{2}):?(\d{2}))?$',
    ).firstMatch(rawTime);
    if (time == null ||
        date == null ||
        int.parse(date[4]!) > 23 ||
        int.parse(date[5]!) > 59 ||
        int.parse(date[6]!) > 59 ||
        (date[7] != null && int.parse(date[7]!) > 23) ||
        (date[8] != null && int.parse(date[8]!) > 59)) {
      throw const FormatException('Invalid journal date');
    }
    final year = int.parse(date[1]!);
    final month = int.parse(date[2]!);
    final day = int.parse(date[3]!);
    final calendar = DateTime(year, month, day);
    if (calendar.year != year ||
        calendar.month != month ||
        calendar.day != day) {
      throw const FormatException('Invalid journal calendar date');
    }
    final rawPrice = json['priceFt'];
    // Invalid historic prices are displayed as unknown, but preserved verbatim.
    final price =
        rawPrice is num &&
            rawPrice.isFinite &&
            rawPrice >= 0 &&
            rawPrice <= 10000000
        ? rawPrice.toDouble()
        : null;
    final result = Drink(
      name,
      ml.toInt(),
      percent.toDouble(),
      time: time,
      priceFt: price,
    );
    result._source = Map<String, dynamic>.from(json);
    result._originalPrice = price;
    return result;
  }
}
