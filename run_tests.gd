extends SceneTree
## Headless test runner. From this folder:
##   godot --headless --script run_tests.gd
## Exit code 0 = all tests passed.

var _failures := 0
var _checks := 0


func _init() -> void:
	_test_normalize()
	_test_arithmetic()
	_test_compare()
	_test_parse_and_serialize()
	_test_formatter()
	print("%d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + label)


func _near(a: float, b: float, tolerance := 1e-9) -> bool:
	return absf(a - b) <= tolerance * maxf(1.0, maxf(absf(a), absf(b)))


func _test_normalize() -> void:
	var n := BigNumber.new(12345.0, 0)
	_check(_near(n.mantissa, 1.2345) and n.exponent == 4, "normalize 12345")
	n = BigNumber.new(0.00042, 0)
	_check(_near(n.mantissa, 4.2) and n.exponent == -4, "normalize 0.00042")
	n = BigNumber.new(-250.0, 10)
	_check(_near(n.mantissa, -2.5) and n.exponent == 12, "normalize negative")
	_check(BigNumber.new(0.0, 99).exponent == 0, "zero resets exponent")


func _test_arithmetic() -> void:
	var a := BigNumber.from_float(1500.0)
	var b := BigNumber.from_float(250.0)
	_check(_near(a.add(b).to_float(), 1750.0), "add")
	_check(_near(a.sub(b).to_float(), 1250.0), "sub")
	_check(_near(b.sub(a).to_float(), -1250.0), "sub to negative")
	_check(_near(a.mul(b).to_float(), 375000.0), "mul")
	_check(_near(a.div(b).to_float(), 6.0), "div")
	var huge := BigNumber.new(5.0, 400)
	_check(huge.mul(huge).exponent == 801, "mul beyond float range")
	_check(huge.add(BigNumber.from_float(1.0)).equals(huge), "add below precision")
	_check(_near(BigNumber.from_float(2.0).power(10.0).to_float(), 1024.0, 1e-6), "power")
	_check(BigNumber.new(1.0, 300).power(3.0).exponent == 900, "power huge")
	_check(_near(BigNumber.from_float(12.7).floor_value().to_float(), 12.0), "floor")
	_check(_near(BigNumber.from_float(4.0).power(0.5).floor_value().to_float(), 2.0), "floor after log-space power")
	_check(BigNumber.from_float(5.0).sub(BigNumber.from_float(5.0)).is_zero(), "sub to zero")


func _test_compare() -> void:
	var small := BigNumber.new(9.0, 10)
	var big := BigNumber.new(1.0, 11)
	_check(big.greater_than(small), "compare exponent")
	_check(small.negated().greater_than(big.negated()), "compare negatives")
	_check(BigNumber.new().less_than(small), "zero less than positive")
	_check(BigNumber.from_float(-1.0).less_than(BigNumber.new()), "negative less than zero")
	_check(BigNumber.from_float(3.0).equals(BigNumber.new(0.3, 1)), "equals")


func _test_parse_and_serialize() -> void:
	var parsed := BigNumber.from_string("1.5e300")
	_check(_near(parsed.mantissa, 1.5) and parsed.exponent == 300, "parse scientific")
	_check(_near(BigNumber.from_string(" -42.5 ").to_float(), -42.5), "parse plain")
	var restored := BigNumber.from_dict(JSON.parse_string(JSON.stringify(parsed.to_dict())))
	_check(restored.equals(parsed), "json round trip")


func _test_formatter() -> void:
	var cases := [
		[BigNumber.new(), NumberFormatter.Style.SHORT, "0"],
		[BigNumber.from_float(999.0), NumberFormatter.Style.SHORT, "999"],
		[BigNumber.from_float(12.5), NumberFormatter.Style.SHORT, "12.5"],
		[BigNumber.from_float(0.05), NumberFormatter.Style.SHORT, "0.05"],
		[BigNumber.from_float(1234.0), NumberFormatter.Style.SHORT, "1.23K"],
		[BigNumber.from_float(999999.0), NumberFormatter.Style.SHORT, "1.00M"],
		[BigNumber.new(4.56, 15), NumberFormatter.Style.SHORT, "4.56Qa"],
		[BigNumber.new(7.0, 36), NumberFormatter.Style.SHORT, "7.00aa"],
		[BigNumber.new(1.0, 39), NumberFormatter.Style.SHORT, "1.00ab"],
		[BigNumber.new(-2.5, 6), NumberFormatter.Style.SHORT, "-2.50M"],
		[BigNumber.new(1.0, 3000), NumberFormatter.Style.SHORT, "1.00e3000"],
		[BigNumber.new(1.234, 45), NumberFormatter.Style.SCIENTIFIC, "1.23e45"],
		[BigNumber.new(1.2345, 44), NumberFormatter.Style.ENGINEERING, "123.45e42"],
	]
	for case in cases:
		var text := NumberFormatter.format(case[0], case[1])
		_check(text == case[2], "format %s -> expected %s, got %s" % [case[0], case[2], text])
