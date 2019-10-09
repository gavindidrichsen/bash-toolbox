include array.util.ArrayUtil

include logger.Logger

include string.util.StringUtil

include repo.Repo

@class
GitUtil(){
	@private
	_getChangeLog(){
		cd ${buildDir}

		local commits=(
			$(git log --oneline upstream/${branch}..HEAD)
		)

		local changeLog=()

		for string in ${commits[@]}; do
			if [[ ${string} =~ LRQA || ${string} =~ LPS ]]; then
				changeLog+=(${string})
			fi
		done

		ArrayUtil returnUniqueArray changeLog
	}

	cleanSource(){
		${_log} info "resetting_the_${branch}_source_directory..."

		cd ${buildDir}

		git reset --hard -q

		if [[ ${branch} =~ "-private" ]]; then
			rm -rf ${buildDir}/modules/apps
		fi

		git clean -fdqx

		${_log} info "completed"
	}

	clearIndexLock(){
		local lockFile=${buildDir}/.git/index.lock

		if [ -e ${lockFile} ]; then
			${_log} info "clearing_index_lock..."

			rm -rf ${lockFile}

			${_log} info "completed"
		fi
	}

	getCurBranch(){
		git rev-parse --abbrev-ref HEAD
	}

	getOriginSHA(){
		cd ${buildDir}

		git --git-dir=${buildDir}/.git rev-parse origin/$(StringUtil
			toLowerCase ${branch})
	}

	getSHA(){
		cd ${buildDir}

		local length=${2}

		if [[ ${length} == long ]]; then
			git log --oneline --pretty=format:%H -1
		elif [[ ${length} == short ]]; then
			git log --oneline --pretty=format:%h -1
		fi
	}

	listBranches(){
		git branch | sed s/\*/\ /g
	}

	updateFork() {
		include logger.Logger

		Logger debug "fetching upstream"
		git fetch upstream --prune

		Logger debug  "rebasing master with upstream/master"
		git checkout master
		git fetch --prune
		# git rebase origin/master # do I want this?  This will ensure any local PRs are also merged into my master
		git rebase upstream/master
		git push origin +master

		list_of_branches=$( git branch -a --sort=-committerdate | perl -nle 'print "$1$2" if /(?<=remotes\/origin\/)(gavindidrich[s]{0,1}en\/)(.*)/')
		Logger debug  "All of my 'gavindidrichsen' branches"
		echo "${list_of_branches}"

		# update all branches based off master
		master_branches=$(echo "${list_of_branches}" | grep -v "\/refresh")
		Logger debug "rebasing all my branches based off master"
		echo "${master_branches}"
		for branch in $(echo "${master_branches}"); do
			Logger info "Updating [${branch}]"
			git checkout "${branch}"
			git rebase "origin/${branch}"
			git rebase master
			git push origin "+${branch}"
		done
	}

	local branch=$(Repo getBranch ${@})
	local buildDir=$(Repo getBuildDir ${branch})

	local _log="Logger log"

	$@
}