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


		local _branch_with_pr_summation="gavindidrichsen/master/sum"
		_updateSumBranch(){
			declare _branch_to_merge_in="${1}"

			# don't merge sum branch into itself
			if [[ "${_branch_to_merge_in}"  == "${_branch_with_pr_summation}" ]]; then
				return
			fi

			Logger debug "Merge into ${_branch_with_pr_summation} all changes from ${_branch_to_merge_in}"
			git checkout -B "${_branch_with_pr_summation}"
			git fetch --prune
			git rebase "origin/${_branch_with_pr_summation}"
			git rebase master
			git push origin "+${_branch_with_pr_summation}"
		}

		Logger debug "fetching upstream"
		git fetch upstream --prune

		Logger debug  "rebasing master with upstream/master"
		git checkout master
		git fetch --prune
		# git rebase origin/master <=== NOT doing this because I always want master to equal upstream/master
		git rebase upstream/master
		git push origin +master

		_updateSumBranch "master"

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

			_updateSumBranch "${branch}"
		done

		local _local_branches_that_can_be_deleted=''; _local_branches_that_can_be_deleted=$(git branch -vv | grep -v "\[origin\/" | awk '{print "git branch -D "$1}' | grep -v "git branch -D \*")
		if [[ "${_local_branches_that_can_be_deleted}" != '' ]]; then
			Logger debug "The following local branches have no remote equivalent"
			echo "${_local_branches_that_can_be_deleted}"
		fi
	}

	local branch=$(Repo getBranch ${@})
	local buildDir=$(Repo getBuildDir ${branch})

	local _log="Logger log"

	$@
}