@class
JsonUtil(){
	parseArgFile() {
	@param the_json_file_containing_arguments
	local _argument_file=""

	@param an_encoded_version_of_the_json_file
	local _encoded_json=""

    # Define variables that hold the $ENCODED_ARGS that can be passed
	# to the script. An existing plain text $ARG_FilE can also be used
	_argument_file="${__dir}/bargs.json"
	ENCODED_ARGS=""
	ARG_FILE="${__dir}/args.json"
	JSON_SUM_OF_ALL_ARGS="{}"
	while (( "$#" )); do
	case "$1" in
		-e|--encoded)
		_encoded_json=$2
		shift 2
		;;
		-A|--argfile)
		_argument_file=$2
		shift 2
		;;
	esac
	done

	# either _argument_file or _encoded_json must be valid; otherwise bomb out
	if [[ ($_argument_file == "" || ! -e $_argument_file) && ($_encoded_json == "") ]]; then
		error "Either --argfile (default is ${_argument_file}) or --encoded json arguments must be set and valid"
		exit 1
	fi

	# If encoded arguments have been supplied, decode them and save to file
	if [ "X${_encoded_json}" != "X" ]; then
		info "Decoding arguments to ${_argument_file}"

		# Decode the bas64 string and write out the ARG file
		echo "${_encoded_json}" | base64 --decode | jq . > "${_argument_file}"
	fi

	# If the _argument_file has been specified and the file exists read in the arguments
	if [[ "X${_argument_file}" != "X" ]]; then
		if [[ ( -f $_argument_file ) ]]; then
		info "$(echo "Reading JSON vars from ${_argument_file}:"; cat "${_argument_file}" )"

		# combine the --flag arguments with --argsfile values (--flag's will override any values in the --argsfile)
		# and update the $_argument_file
		JSON_SUM_OF_ALL_ARGS=$(jq --sort-keys -s '.[0] * .[1]' "${_argument_file}" <(echo "${JSON_SUM_OF_ALL_ARGS}"))
		echo "${JSON_SUM_OF_ALL_ARGS}" | jq --sort-keys '.' > "${_argument_file}"

		# transform the JSON into bash key=value statements
		VARS=$(echo ${JSON_SUM_OF_ALL_ARGS} | jq -r '. | keys[] as $k | "\($k)=\"\(.[$k])\""' )
		# ensure that key's that are arrays are in the correct format (..) instead of "[..]"
		VARS=$(echo "${VARS}" | sed 's/\"\[/(/g' | sed 's/\]\"/)/g' | sed 's/,/ /g' )
		info "$(echo "Evaluating the following bash variables:"; echo "${VARS}")"

		# Evaluate all the vars in the arguments
		info "Evaluating the json arguments as bash variables"
		while read -r line; do
			eval "$line"
		done <<< "$VARS"
		else
		fatal "Unable to find specified args file: ${_argument_file}"
		fi
	fi
	}

	$@
}