include logger.util.LoggerUtil

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