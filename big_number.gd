class_name BigNumber
extends RefCounted
## Number of arbitrary magnitude stored as mantissa * 10^exponent.
##
## The mantissa is kept in [1, 10) (or (-10, -1] for negatives) and the exponent
## is a 64-bit int, so values far beyond float range (1e308) stay exact enough
## for idle-game economies. All operations return new instances.

const _LN10 := 2.302585092994046
## Beyond this exponent gap the smaller operand is below float precision.
const _MAX_PRECISION_GAP := 17

var mantissa: float = 0.0
var exponent: int = 0


func _init(p_mantissa: float = 0.0, p_exponent: int = 0) -> void:
	mantissa = p_mantissa
	exponent = p_exponent
	_normalize()


static func from_float(value: float) -> BigNumber:
	return BigNumber.new(value, 0)


## Parses "1234.5", "1.5e300" or "-2.25E12". Invalid text returns zero.
static func from_string(text: String) -> BigNumber:
	var clean := text.strip_edges().to_lower()
	var parts := clean.split("e")
	if parts.size() == 1 and parts[0].is_valid_float():
		return BigNumber.new(parts[0].to_float(), 0)
	if parts.size() == 2 and parts[0].is_valid_float() and parts[1].is_valid_int():
		return BigNumber.new(parts[0].to_float(), parts[1].to_int())
	push_warning("BigNumber: cannot parse '%s', using 0" % text)
	return BigNumber.new()


static func from_dict(data: Dictionary) -> BigNumber:
	return BigNumber.new(float(data.get("m", 0.0)), int(data.get("e", 0)))


func to_dict() -> Dictionary:
	return {"m": mantissa, "e": exponent}


func copy() -> BigNumber:
	return BigNumber.new(mantissa, exponent)


func is_zero() -> bool:
	return mantissa == 0.0


func is_negative() -> bool:
	return mantissa < 0.0


func negated() -> BigNumber:
	return BigNumber.new(-mantissa, exponent)


func abs_value() -> BigNumber:
	return BigNumber.new(absf(mantissa), exponent)


## Returns +inf/-inf when the value does not fit in a float.
func to_float() -> float:
	if exponent > 308:
		return INF if mantissa > 0.0 else -INF
	if exponent < -324:
		return 0.0
	return mantissa * pow(10.0, exponent)


## log10 of the absolute value. Zero returns -INF.
func log10() -> float:
	if is_zero():
		return -INF
	return log(absf(mantissa)) / _LN10 + exponent


func add(other: BigNumber) -> BigNumber:
	if is_zero():
		return other.copy()
	if other.is_zero():
		return copy()
	var gap := exponent - other.exponent
	if gap > _MAX_PRECISION_GAP:
		return copy()
	if gap < -_MAX_PRECISION_GAP:
		return other.copy()
	if gap >= 0:
		return BigNumber.new(mantissa + other.mantissa * pow(10.0, -gap), exponent)
	return BigNumber.new(other.mantissa + mantissa * pow(10.0, gap), other.exponent)


func sub(other: BigNumber) -> BigNumber:
	return add(other.negated())


func mul(other: BigNumber) -> BigNumber:
	return BigNumber.new(mantissa * other.mantissa, exponent + other.exponent)


func mul_float(factor: float) -> BigNumber:
	return BigNumber.new(mantissa * factor, exponent)


func div(other: BigNumber) -> BigNumber:
	if other.is_zero():
		push_error("BigNumber: division by zero")
		return BigNumber.new()
	return BigNumber.new(mantissa / other.mantissa, exponent - other.exponent)


## Raises a non-negative value to any real power (works in log space).
func power(p: float) -> BigNumber:
	if is_zero():
		return BigNumber.new(1.0 if p == 0.0 else 0.0, 0)
	if is_negative():
		push_error("BigNumber: power() of a negative number is not supported")
		return BigNumber.new()
	return BigNumber.from_log10(log10() * p)


## Builds 10^value, e.g. from_log10(3.5) = 3162.27...
static func from_log10(value: float) -> BigNumber:
	var whole := floori(value)
	return BigNumber.new(pow(10.0, value - whole), whole)


## Returns -1, 0 or 1.
func compare(other: BigNumber) -> int:
	var sign_a := signi(int(signf(mantissa)))
	var sign_b := signi(int(signf(other.mantissa)))
	if sign_a != sign_b:
		return 1 if sign_a > sign_b else -1
	if sign_a == 0:
		return 0
	if exponent != other.exponent:
		return (1 if exponent > other.exponent else -1) * sign_a
	if is_equal_approx(mantissa, other.mantissa):
		return 0
	return 1 if mantissa > other.mantissa else -1


func greater_than(other: BigNumber) -> bool:
	return compare(other) > 0


func greater_or_equal(other: BigNumber) -> bool:
	return compare(other) >= 0


func less_than(other: BigNumber) -> bool:
	return compare(other) < 0


func equals(other: BigNumber) -> bool:
	return compare(other) == 0


func floor_value() -> BigNumber:
	if exponent >= _MAX_PRECISION_GAP:
		return copy()
	if exponent < 0:
		return BigNumber.new(-1.0 if is_negative() else 0.0, 0)
	var value := mantissa * pow(10.0, exponent)
	# Log-space math (power, from_log10) lands on 1.9999999 instead of 2.
	var nearest := roundf(value)
	if absf(value - nearest) <= 1e-9 * maxf(1.0, absf(value)):
		return BigNumber.new(nearest, 0)
	return BigNumber.new(floorf(value), 0)


func _to_string() -> String:
	return "%se%d" % [String.num(mantissa, 6), exponent]


func _normalize() -> void:
	if mantissa == 0.0 or is_nan(mantissa):
		mantissa = 0.0
		exponent = 0
		return
	if is_inf(mantissa):
		push_error("BigNumber: infinite mantissa, clamping to 9.99e308")
		mantissa = 9.99 if mantissa > 0.0 else -9.99
		exponent += 308
		return
	var shift := floori(log(absf(mantissa)) / _LN10)
	if shift != 0:
		mantissa /= pow(10.0, shift)
		exponent += shift
	# Guard against float rounding at the edges of [1, 10).
	if absf(mantissa) >= 10.0:
		mantissa /= 10.0
		exponent += 1
	elif absf(mantissa) < 1.0:
		mantissa *= 10.0
		exponent -= 1
