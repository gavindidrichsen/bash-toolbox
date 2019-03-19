include array.validator.ArrayValidator

include app.server.validator.AppServerValidator
include app.server.version.AppServerVersion

include git.util.GitUtil

include logger.Logger

include string.util.StringUtil

include repo.Repo

@class
JiraCommentUtil(){
	@private
	_getEnv(){
		local appServerVersion=$(AppServerVersion
			getAppServerVersion ${1} ${2})

		local environment=(
			$(StringUtil capitalize ${1})
			${appServerVersion}
			+_MySQL
		)

		if [[ ${branch} == master* || ${branch} == 7.2.x* ]]; then
			environment+=(8.0)
		else
			environment+=(5.7)
		fi

		local gitId=$(cat ${bundleDir}/.githash)

		StringUtil replace $(StringUtil join environment _) _ space
		echo "Portal *${branch}* GIT ID: ${gitId}"
	}

	fixed(){
		echo "*Fixed on:*"
	}

	nlr(){
		echo "*No Longer Reproducible on:*"
	}

	repro(){
		echo "*Reproduced on:*"
	}

	tested(){
		echo "*Tested on:*"
	}

	local _log="Logger log"

	local args=($@)
	local appServer=$(AppServerValidator returnAppServer ${args[@]})
	local branch=$(Repo getBranch ${args[@]})
	local bundleDir=$(Repo getBundleDir ${branch})

	if [[ $(ArrayValidator hasEntry args nightly) ]]; then
		local nightly=true
	fi

	while [[ ${1} == ${branch} || ${1} == ${appServer} || ${1} == nightly ]]; do
		shift
	done

	if [[ ${branch} == master ]]; then
		local branch=$(StringUtil capitalize ${branch})
	fi

	$@
	_getEnv ${appServer} ${branch}
}