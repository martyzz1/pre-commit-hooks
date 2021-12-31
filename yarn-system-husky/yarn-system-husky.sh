#!/usr/bin/env bash
# husky

OPTIONS=()
# If arg doesn't pass [ -f ] check, then it is assumed to be an option
#
while [ $# -gt 0 ] && [ "$1" != "-" ] && [ "$1" != "--" ] && [ ! -f "$1" ]; do
	OPTIONS+=("$1")
	shift
done

FILES=()
# Assume start of file list (may still be options)
#
while [ $# -gt 0 ] && [ "$1" != "-" ] && [ "$1" != "--" ]; do
	FILES+=("$1")
	shift
done

# If '--' next, then files = options
#
if [ $# -gt 0 ]; then
	if [ "$1" == "-" ] || [ "$1" == "--" ]; then
		shift
		# Append to previous options
		#
		OPTIONS=("${OPTIONS[@]}" "${FILES[@]}")
		FILES=()
	fi
fi

# Any remaining arguments are assumed to be files
#
while [ $# -gt 0 ]; do
	FILES+=("$1")
	shift
done

for i in ${OPTIONS[@]}; do
	case $i in
		--hook-stage=*)
		hookName="${i#*=}"
		shift # past argument=value
		;;
		*)
			# unknown option
		;;
	esac
done

scriptPath="node_modules/husky/run.js"

debug() {
  if [ "${HUSKY_DEBUG}" = "true" ] || [ "${HUSKY_DEBUG}" = "1" ]; then
    echo "husky:debug $1"
  fi
}

printf -v gitParams "%s " "${FILES[@]}"
debug "=======husky========"
debug "$hookName hook started"
debug "Current working directory is '`pwd`'"
debug "gitParams $gitParams"

if [ "${HUSKY_SKIP_HOOKS}" = "true" ] || [ "${HUSKY_SKIP_HOOKS}" = "1" ]; then
  debug "HUSKY_SKIP_HOOKS is set to ${HUSKY_SKIP_HOOKS}, skipping hook"
  exit 0
fi

debug "Calling husky through Yarn"
yarn husky-run $hookName "$gitParams"
