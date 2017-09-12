include array.util.ArrayUtil
include array.validator.ArrayValidator

include file.name.util.FileNameUtil

include string.util.StringUtil
include string.validator.StringValidator

include system.validator.SystemValidator

FileUtil(){
	construct(){
		local _path=$(FileNameUtil getPath nix ${1})

		for directory in $(StringUtil replace _path / space); do
			local dir=${dir}/${directory}

			if [ ! -e ${dir} ]; then
				mkdir ${dir}
			fi

			cd ${dir}
		done

		echo ${_path}
	}

	getContent(){
		cat ${1}
	}

	getCurFile(){
		local thisFile=${0//*\//}

		if [[ ${1} == true ]]; then
			echo ${thisFile}
		elif [[ ${1} == false ]]; then
			StringUtil strip thisFile .sh
		fi
	}

	makeFile(){
		local fileName=$(FileNameUtil getPath nix ${1})
		local _fileNameArray=($(StringUtil split fileName /))
		local fileNameArray=($(ArrayUtil trim _fileNameArray 1))
		local filePath=$(construct /$(StringUtil replace fileNameArray space /))

		for cmd in {touch,echo}; do
			${cmd} ${filePath}/${_fileNameArray[-1]}
		done
	}

	open(){
		if [[ $(SystemValidator isLinux) ]]; then
			local cmd=open
		elif [[ $(SystemValidator isWindows) ]]; then
			local cmd=start
		fi

		${cmd} ${1}
	}

	$@
}