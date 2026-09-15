class_name NumberFormatter
extends RefCounted
## Turns BigNumber values into player-facing text: 1.23K, 4.56Qa, 7.89aa,
## 1.23e45 or 123.45e42.

enum Style { SHORT, SCIENTIFIC, ENGINEERING }

## Suffix per group of three digits; after "Dc" SHORT switches to aa, ab ... zz,
## and to scientific notation after that.
const SHORT_SUFFIXES: PackedStringArray = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
]
const _LETTERS := "abcdefghijklmnopqrstuvwxyz"


static func format(value: BigNumber, style: Style = Style.SHORT, decimals: int = 2) -> String:
	if value.is_zero():
		return "0"
	var sign_prefix := "-" if value.is_negative() else ""
	var m := absf(value.mantissa)
	var e := value.exponent

	if e < 3:
		# Small numbers are shown plainly: 0.05, 12.5, 999.99
		var plain := String.num(snappedf(m * pow(10.0, e), pow(10.0, -decimals)), decimals)
		if plain.contains("."):
			plain = plain.rstrip("0").rstrip(".")
		return sign_prefix + plain

	match style:
		Style.SCIENTIFIC:
			var rounded := _round_mantissa(m, e, decimals, 10.0, 1)
			return "%s%se%d" % [sign_prefix, _fixed(rounded[0], decimals), rounded[1]]
		Style.ENGINEERING:
			var eng := _group(m, e, decimals)
			return "%s%se%d" % [sign_prefix, _fixed(eng[0], decimals), eng[1] * 3]
		_:
			var grouped := _group(m, e, decimals)
			var suffix := short_suffix(grouped[1])
			if suffix.is_empty():
				return format(value, Style.SCIENTIFIC, decimals)
			return "%s%s%s" % [sign_prefix, _fixed(grouped[0], decimals), suffix]


## Suffix for a group index (1 = thousands). Empty when out of range.
static func short_suffix(group: int) -> String:
	if group < SHORT_SUFFIXES.size():
		return SHORT_SUFFIXES[group]
	var index := group - SHORT_SUFFIXES.size()
	if index >= _LETTERS.length() * _LETTERS.length():
		return ""
	return _LETTERS[index / _LETTERS.length()] + _LETTERS[index % _LETTERS.length()]


## Returns [scaled_value, group] with scaled_value in [1, 1000) after rounding.
static func _group(m: float, e: int, decimals: int) -> Array:
	var group := e / 3
	var scaled := snappedf(m * pow(10.0, e - group * 3), pow(10.0, -decimals))
	if scaled >= 1000.0:
		scaled /= 1000.0
		group += 1
	return [scaled, group]


static func _round_mantissa(m: float, e: int, decimals: int, limit: float, step: int) -> Array:
	var rounded := snappedf(m, pow(10.0, -decimals))
	if rounded >= limit:
		rounded /= limit
		e += step
	return [rounded, e]


static func _fixed(value: float, decimals: int) -> String:
	return String.num(value, decimals).pad_decimals(decimals)
