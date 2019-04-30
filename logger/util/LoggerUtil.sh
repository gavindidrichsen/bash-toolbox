include array.util.ArrayUtil

include calendar.util.CalendarUtil

include math.util.MathUtil

include string.util.StringUtil

@class
LoggerUtil(){
	@deprecated @private
	_formatLogLevel(){
		local logLevel=${1}
		local validLogLevels=(debug error info success)

		local maxLength=$(ArrayUtil returnMaxLength validLogLevels)

		while [[ $(StringUtil length ${logLevel}) -lt ${maxLength} ]]; do

			if [[ $(MathUtil isEven $(StringUtil length ${logLevel})) ]]; then
				local logLevel=$(StringUtil append _ ${logLevel})
			else
				local logLevel=$(StringUtil append ${logLevel} _)
			fi
		done

		StringUtil toUpperCase ${logLevel}
	}

	getLogMsg(){
		local color=null
		local logLevel=$(StringUtil toUpperCase ${1}); shift
		local message="$@"

		if [[ ( ${logLevel} == ERROR) || (${logLevel} == FATAL) ]]; then
			local color=red
		elif [[ ${logLevel} == DEBUG ]]; then
			local color=yellow
		elif [[ ${logLevel} == SUCCESS ]]; then
			local color=green
		fi
		
		echo -e "[$(CalendarUtil getTimestamp log)] [${logLevel}] $( colorme ${color} "${message}" )"

		if [[ ${logLevel} == FATAL ]]; then exit 1; fi
	}

	$@
}