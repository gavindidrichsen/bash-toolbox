include logger.util.LoggerUtil

# define global helper messages
debug()   { ( Logger log debug "${@}" ) }
info()    { ( Logger log info "${@}" ) }
warning() { ( Logger log warning "${@}" ) }
error()   { ( Logger log error "${@}" ) }
success() { ( Logger log success "${@}" ) }
fatal()   { ( Logger log fatal "${@}" ) }

@class
Logger(){
	log(){
		@param the_log_level_for_the_log_message
		local logLevel=${1}; shift

		@param the_log_message
		local logMessage="${@}"

		LoggerUtil getLogMsg ${logLevel} ${logMessage}
	}

	${@}
}