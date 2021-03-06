include app.server.validator.AppServerValidator
include app.server.version.AppServerVersion

include file.name.util.FileNameUtil

include logger.Logger

include props.writer.PropsWriter

include repo.Repo

@class
SourceUtil(){
	clearGradleCache(){
		if [ -d ${buildDir}/.gradle/caches/ ]; then
			${_log} info "clearing_gradle_cache..."

			cd ${buildDir}/.gradle/caches/

			git clean -fdq

			${_log} info "completed"
		fi
	}

	config(){
		${_log} info "building_properties..."

		local buildDir=$(
			FileNameUtil getPath $(
				Repo getBuildDir ${branch}
			)
		)

		for prop in {app.server,build}; do
			touch ${buildDir}/${prop}.${USERNAME}.properties
		done

		local bundleDir=$(
			FileNameUtil getPath $(
				Repo getBundleDir ${branch}
			)
		)

		${writer} setAppServerProps ${branch} app.server.parent.dir ${bundleDir}
		${writer} setAppServerProps ${branch} app.server.type ${appServer}

		local appServerVersion=$(
			AppServerVersion getAppServerVersion ${appServer} ${branch}
		)

		local propName=app.server.${appServer}.version
		local propValue=${appServerVersion//[a-zA-Z-]/}

		${writer} setAppServerProps ${branch} ${propName} ${propValue}

		${writer} setBuildProps ${branch} lp.source.dir ${buildDir}

		if [[ ${branch} =~ 6.2 ]]; then
			${writer} setBuildProps ${branch} javac.compiler modern
		fi

		${_log} info "completed"
	}

	setupSDK(){
		if [[ ${branch} =~ master || ${branch} =~ 7.0.x ]]; then

			local lib="tools/sdk/dependencies/com.liferay.source.formatter/lib"

			if [ ! -e ${buildDir}/${lib} ]; then
				${_log} info "building_SDK_directory..."

				cd ${buildDir}

				ant setup-sdk

				${_log} info "completed"
			fi
		fi
	}

	local _log="Logger log"

	local appServer=$(AppServerValidator returnAppServer $@)
	local branch=$(Repo getBranch $@)

	local writer=PropsWriter

	$@
}