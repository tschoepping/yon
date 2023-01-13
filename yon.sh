#!/bin/sh

########################################################################
# Copyright (c) 2023 T. Schöpping                                      #
#                                                                      #
# This file is provided under the MIT License with Exception           #
########################################################################

# Ask user for confirmation (yes or no) and store answer in shell variable 'YON'.
# Usage: yon [options] [--] <question string>"
yon() {
	# variable defauls
	retval=0
	printhelp=0
	printversion=0
	defaultanswer=''
	timeout=''
	defaultontimeout=0
	attempts=0
	returnvariable=''
	prompt=""

	# parse options
	if ! parsed=$(getopt --options=hvd:t:ea:r: --longoptions=help,version,default:,timeout:,default-on-timeout,attempts:,return-variable: -- "$@"); then
		retval=1
	fi
	eval set -- "$parsed"

	# evaluate options
	while true; do
		case "$1" in
			-h|--help)
				# set flag
				printhelp=1
				shift 1
				;;
			-v|--version)
				printversion=1
				shift 1
				;;
			-d|--default)
				# check for valid option argument and parse it
				case "$2" in
					y|Y|yes|Yes|YES) defaultanswer='y' ;;
					n|N|no|No|NO) defaultanswer='n' ;;
					*) retval=1 ;;
				esac
				shift 2
				;;
			-t|--timeout)
				# check for valid option argument (positive float)
				if expr "$2" : "^\([0-9]\+\)\?\(\.[0-9]\+\)\?$" > /dev/null; then
					timeout="$2"
				else
					retval=1
				fi
				shift 2
				;;
			-e|--default-on-timeout)
				# set flag
				defaultontimeout=1
				shift 1
				;;
			-a|--attempts)
				# check for valid option argument (positive integer)
				if expr "$2" : "^[0-9]\+$" > /dev/null && [ "$2" -gt 0 ]; then
					attempts=$2
				else
					retval=1
				fi
				shift 2
				;;
			-r|--return-variable)
				# save an clear return variable
				returnvariable=$2
				export "$returnvariable"=
				shift 2
				;;
			--)
				# all options parsed, break the loop
				shift 1
				break
				;;
			*)
				# this must never occur
				return 255
				;;
		esac
	done

	# check help and version flags
	if [ $printhelp -eq 0 ] && [ $printversion -eq 0 ]; then
		# check for at least one (remaining) argument
		if [ $# -gt 0 ]; then
			# set prompt
			prompt=$*
		else
			retval=1
		fi
	fi

	# check dependencies
	if [ $defaultontimeout -eq 1 ] && [ -z $defaultanswer ]; then
		retval=1
	fi

	# check for errors so far
	if [ $retval -ne 0 ]; then
		echo "yon: invalid option(s)"
		echo "Try 'yon --help' for more information."
		return $retval
	fi

	# check help flag
	if [ $printhelp -ne 0 ]; then
		echo "Usage: yon [options] [--] <question string>"
		echo ""
		echo "Ask user for confirmation (yes or no) and store answer in shell variable 'YON'."
		echo ""
		echo "Options:"
		echo " -a, --attempts <val>"
		echo "    Maximum number of attempts to ask the user for a valid answer."
		echo "    <val> msut be a positive integer value > 0."
		echo "    In case the user does not provide a valid answer, error code 3 is returned."
		echo "    If not specified, an infinite number of attempts are made."
		echo " -d, --default <val>"
		echo "    Specify an assumed answer in case the user does just hit enter."
		echo "    If this option is not provided, no default answer is assumed."
		echo "    Allowed values for <val> are:"
		echo "      y, Y, yes, Yes, YES       assume confirmation"
		echo "      n, N, no, No, NO          assume rejection"
		echo " -e, --default-on-timeout"
		echo "    Assume the default answer (cf. -d/--default) on timeout."
		echo "    Requires -d/--default option."
		echo "    Has no effect if no timeout is specified (cf. -t/--timeout)."
		echo " -h, --help"
		echo "    Display this help text and exit."
		echo " -r, --return-variable <varname>"
		echo "    Store the answer flag ('y' or 'n') in the variable <varname>."
		echo "    In contrast to the 'YON' shell variable, <varname> is reset to '' with each call of yon."
		echo " -t, --timeout <val>"
		echo "    Fractional number of seconds when the function will time out."
		echo "    <val> must be a flating point value >= 0."
		echo "    Behaviour on timeout depends on the -e/--default-on-timeout flag:"
		echo "      If the flag is specified, the default answer (cf. -d/--default) is assumed."
		echo "      Otherwise, error code 2 is returned."
		echo " -v, --version"
		echo "    Display version information and exit."
		echo ""
		echo "Exit Status:"
		echo "  0   User answered properly or the default answer was assumed on timeout."
		echo "      Shell variable 'YON' is set to either 'y' or 'n'."
		echo "  1   Some given options or arguments were invalid."
		echo "  2   A timeout occurred, but no default answer was assumed."
		echo "  3   The user did not provide a valid answer."
		return $retval
	fi

	# check version flag
	if [ $printversion -ne 0 ]; then
		echo "yon version 1.0.0"
		return $retval
	fi

	# prepare prompt
	case $defaultanswer in
		y) prompt="$prompt [Y/n]: " ;;
		n) prompt="$prompt [y/N]: " ;;
		*) prompt="$prompt [y/n]: " ;;
	esac

	# print prompt until valid answer or timeout
	attempt=0
	while true; do
		attempt=$(echo "$attempt + 1;" | bc)

		# ask user and read answer
		printf "%s" "$prompt"
		saved_tty_settings=$(stty -g)
		if [ -z "$timeout" ]; then
			stty -icanon min 1
		else
			# round timeout to 1/10 second
			timeout=$(echo "scale=1; ($timeout + 0.05) / 1;" | bc)
			stty -icanon min 0 time "$(echo "scale=0; $timeout / 0.1;" | bc)"
		fi
		starttime=$(date +%s%N)
		answer=$(dd bs=1 count=1 2>/dev/null)
		endtime=$(date +%s%N)
		stty "$saved_tty_settings"
		if [ -n "$answer" ]; then
			echo ""
		fi

		# check for timeout
		if [ -n "$timeout" ]; then
			dtime=$(echo "scale=3; ($endtime - $starttime) / 10^9;" | bc)
			if [ "$(echo "if ($dtime >= $timeout) 2 else 0;" | bc)" -eq 0 ]; then
				retval=0
			else
				echo ""
				retval=2
			fi
			if [ $retval -eq 2 ] && [ $defaultontimeout -ne 0 ]; then
				answer=$defaultanswer
				retval=0
			fi
		fi

		# return on error
		if [ $retval -ne 0 ]; then
			return $retval
		fi

		# evaluate answer
		if [ -z "$answer" ] && [ -n "$defaultanswer" ]; then
			answer=$defaultanswer
		fi
		case $answer in
			y|Y)
				# user confirmed
				export YON='y'
				if [ -n "$returnvariable" ]; then
					export "$returnvariable"='y'
				fi
				return $retval
				;;
			n|N)
				# user declined
				export YON='n'
				if [ -n "$returnvariable" ]; then
					export "$returnvariable"='n'
				fi
				return $retval
				;;
			*)
				# neither, attempt again or return
				if [ "$attempts" -eq 0 ] || [ "$attempt" -lt "$attempts" ]; then
					continue
				else
					retval=3
					return $retval
				fi
		esac
	done

	return $retval
}
