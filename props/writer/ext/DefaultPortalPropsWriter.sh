include file.name.util.FileNameUtil
include file.writer.FileWriter

include props.writer.util.PropsWriterUtil

include repo.Repo

@class
DefaultPortalPropsWriter(){
	@private
	_writeProps(){
		local file=${2}

		local keyValuePairs=($(readvar ${1}))

		for keyValuePair in ${keyValuePairs[@]}; do
			local key=${keyValuePair%%=*}

			local value=${keyValuePair/${key}=/}

			PropsWriterUtil setProps ${file} ${key} ${value}

			FileWriter append ${file}
		done
	}

	writeBaseProps(){
		local propsKeyValueList=(
			liferay.home=$(FileNameUtil getHybridPath ${bundleDir})
			plugin.notifications.enabled=false
			index.on.startup=false
			browser.launcher.url=
			setup.wizard.enabled=false
			mail.session.jndi.name=
			tunnel.servlet.hosts.allowed=
			auth.verifier.TunnelAuthVerifier.hosts.allowed=
			javascript.fast.load=false
			minifier.enabled=false
		)

		_writeProps propsKeyValueList ${propsFile}
	}

	writeClusterProps(){
		local port=11311

		if [[ ${2} && ! ${2//[0-9]/} ]]; then
			local port=$((port+${2}))
		fi

		local propsKeyValueList=(
			cluster.link.autodetect.address=
			cluster.link.enabled=true
			dl.store.impl=com.liferay.portal.db.DBStore
			web.server.display.node=true
			module.framework.properties.osgi.console=localhost:${port}
		)

		_writeProps propsKeyValueList ${propsFile}
	}

	writeDatabaseProps(){
		local databaseName=lportal${branch//[-.]/}

		local propsKeyValueList=(
			jdbc.default.jndi.name=
			jdbc.default.driverClassName=com.mysql.jdbc.Driver
			jdbc.default.url=jdbc:mysql://localhost/${databaseName}?useUnicode=true\&characterEncoding=UTF-8\&useFastDateParsing=false
			jdbc.default.username=
			jdbc.default.password=
		)

		_writeProps propsKeyValueList ${propsFile}
	}

	local branch=$(Repo getBranch ${2})

	local bundleDir=$(Repo getBundleDir ${branch})

	local propsFile=${bundleDir}/portal-ext.properties

	$@
}