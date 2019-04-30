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
	debug()   { ( Logger log debug "${@}" ) }
	info()    { ( Logger log info "${@}" ) }
	warning() { ( Logger log warning "${@}" ) }
	error()   { ( Logger log error "${@}" ) }
	success() { ( Logger log success "${@}" ) }
	fatal()   { ( Logger log fatal "${@}" ) }
}

main