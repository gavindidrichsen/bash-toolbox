BaseVars(){

	@private
	_getPath(){
		local path=${1}

		if [[ $(uname) =~ NT ]]; then
			local _drive=${path:1:1}
			local drive=${_drive^}
			local headlessPath=${path/\/[a-z]/}

			echo ${drive}:${headlessPath}
		else
			echo ${path}
		fi
	}

	@private
	_returnBuildDir(){
		_getPath /d/$(_returnPrivacy $@)/$(returnBranch $@)-portal
	}

	@private
	_returnBundleDir(){
		_getPath /d/$(_returnPrivacy $@)/$(returnBranch $@)-bundles
	}

	@private
	_returnPrivacy(){
		if [[ $(isPrivate $@) ]]; then
			echo private
		else
			echo public
		fi
	}

	@private
	_returnPrivateBuildDir(){
		_getPath /d/$(_returnPrivacy $@)/$(returnPrivateBranch $@)/portal
	}

	@private
	_returnPrivateBundleDir(){
		_getPath /d/$(_returnPrivacy $@)/$(returnPrivateBranch $@)/bundles
	}

	isPrivate(){
		if [[ $@ == *ee-* || $@ == *-private* ]]; then
			echo true
		fi
	}

	returnBranch(){
		case $@ in
			*ee-6.1.30*) echo ee-6.1.30;;
			*ee-6.1.x*) echo ee-6.1.x;;
			*ee-6.2.x*) echo ee-6.2.x;;
			*ee-6.2.10*) echo ee-6.2.10;;
			*ee-7.0.x*) echo ee-7.0.x;;
			*6.1.x*) echo 6.1.x;;
			*6.2.x*) echo 6.2.x;;
			*master*) echo master;;
			*7.0.x*) echo 7.0.x;;
			*) echo master;;
		esac
	}

	returnBuildDir(){
		if [[ $@ =~ private ]]; then
			_returnPrivateBuildDir $@
		else
			_returnBuildDir $@
		fi
	}

	returnBundleDir(){
		if [[ $@ =~ private ]]; then
			_returnPrivateBundleDir $@
		else
			_returnBundleDir $@
		fi
	}

	returnPrivateBranch(){
		case ${@} in
			*7.0.x-private*) echo 7.0.x-private;;
			*master-private*) echo master-private;;
			*) echo 7.0.x-private;;
		esac
	}

	$@
}