@class
JsonUtil(){
	common::parseArgFile() {
	# either ARG_FILE or ENCODED_ARGS must be valid; otherwise bomb out
	if [[ ($ARG_FILE == "" || ! -e $ARG_FILE) && ($ENCODED_ARGS == "") ]]; then
		error "Either --argfile (default is ${ARG_FILE}) or --encoded json arguments must be set and valid"
		exit 1
	fi

	# If encoded arguments have been supplied, decode them and save to file
	if [ "X${ENCODED_ARGS}" != "X" ]; then
		info "Decoding arguments to ${ARG_FILE}"

		# Decode the bas64 string and write out the ARG file
		echo "${ENCODED_ARGS}" | base64 --decode | jq . > "${ARG_FILE}"
	fi

	# If the ARG_FILE has been specified and the file exists read in the arguments
	if [[ "X${ARG_FILE}" != "X" ]]; then
		if [[ ( -f $ARG_FILE ) ]]; then
		info "$(echo "Reading JSON vars from ${ARG_FILE}:"; cat "${ARG_FILE}" )"

		# combine the --flag arguments with --argsfile values (--flag's will override any values in the --argsfile)
		# and update the $ARG_FILE
		JSON_SUM_OF_ALL_ARGS=$(jq --sort-keys -s '.[0] * .[1]' "${ARG_FILE}" <(echo "${JSON_SUM_OF_ALL_ARGS}"))
		echo "${JSON_SUM_OF_ALL_ARGS}" | jq --sort-keys '.' > "${ARG_FILE}"

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
		fatal "Unable to find specified args file: ${ARG_FILE}"
		fi
	fi
	}

	$@
}