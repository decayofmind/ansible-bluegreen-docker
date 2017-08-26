colors_on () { [ "$COLORS_ON" = 1 ]; }
start_fg () { colors_on && echo -ne "\033[${1}m"; }
reset_colors () { colors_on && echo -ne '\033[0m'; }

colored () {
	start_fg $1
	shift
	echo -n "$@"
	reset_colors
}

fg_red () { colored 31 "$@"; }
fg_green () { colored 32 "$@"; }
fg_yellow () { colored 33 "$@"; }
fg_blue () { colored 34 "$@"; }
fg_magenta () { colored 35 "$@"; }
fg_cyan () { colored 36 "$@"; }

assert_success () {
	$@
	exit_code=$?
	[ "$1" = "echo_exec" ] && shift
	if [ $exit_code -ne 0 ]; then
		echo >&2 $(fg_red "FATAL: $exit_code: $@")
		exit $exit_code
	fi
}

echo_exec () {
	local retcode
	echo "\$ $(fg_cyan "$@")" >&2
	$@

	retcode=$?
	if [ $retcode -eq 0 ]; then
		fg_green "$retcode $@" >&2
	else
		fg_red "$retcode $@" >&2
	fi

	echo >&2
	return $retcode
}

repeat_char () {
	local char=$1
	local count=$2
	printf '=%.0s' $(seq 1 $count)
}

section () {
	local len=${#1}
	repeat_char = $len
	echo
	echo "$1"
	repeat_char = $len
	echo
	echo
}

is_run_by_gitlab () {
  test "x$CI_BUILD_REF_NAME" != "x"
}

exit_code_msg () {
	if [ $1 -eq 0 ]; then
		fg_green OK
	else
		fg_red FAILED
	fi
}
