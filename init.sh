main(){
	local __files=(
		colorme.sh
		include.sh
		markups.sh
		nullify.sh
		readvar.sh
	)

	for file in ${__files[@]}; do
		source ${projectDir}/bash-toolbox/lib/${file}
	done

	: '
	Log info(), warning(), error(), etc from a subshell so that this
	can be used within functions that return output.  In other words
	the subshell ensures that the info,warning,error message does not dirty
	the function output, the "echo"
	'
	include logger.Logger
	debug()   { ( set +x; Logger log debug "${@}" ) }
	info()    { ( set +x; Logger log info "${@}" ) }
	warning() { ( set +x; Logger log warning "${@}" ) }
	error()   { ( set +x; Logger log error "${@}" ) }
	success() { ( set +x; Logger log success "${@}" ) }
	fatal()   { ( set +x; Logger log fatal "${@}" ) }
}

main