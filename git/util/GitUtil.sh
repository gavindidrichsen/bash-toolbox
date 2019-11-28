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
		declare _base_branch="${1:-master}"

		Logger log info "fetching upstream and origin"
		git fetch upstream --prune
		git fetch origin --prune

		# return if no differences between upstream and origin
		if (*git --no-pager diff --exit-code --quiet ${_base_branch} upstream/${_base_branch}); then
			Logger log info "no difference between ${_base_branch} upstream/${_base_branch})"
			return
		fi

		# otherwise update upstream and origin branches
		Logger log info "difference between upstream/${_base_branch} and ${_base_branch}"
		git --no-pager diff --stat ${_base_branch}..upstream/${_base_branch}

		Logger log info  "rebasing ${_base_branch} with upstream/${_base_branch}"
		git checkout ${_base_branch}
		# git rebase origin/${_base_branch} <=== NOT doing this because I always want origin/${_base_branch} to equal upstream/${_base_branch}
		git rebase upstream/${_base_branch}
		git push origin +${_base_branch}

		list_of_branches=$( git branch -a --sort=-committerdate | perl -nle 'print "$1$2" if /(?<=remotes\/origin\/)(gavindidrich[s]{0,1}en\/)(.*)/')
		# Logger log info  "All of my 'gavindidrichsen' branches"
		# echo "${list_of_branches}"

		# update all branches based off master
		pr_branches=$(echo "${list_of_branches}" | grep "/${_base_branch}/pr/")
		Logger log info "list of pr branches based off ${_base_branch}"
		echo "${pr_branches}"

		for branch in $(echo "${pr_branches}"); do
			Logger log debug "Updating [${branch}]"
			git checkout "${branch}"
			git rebase "origin/${branch}"
			git rebase ${_base_branch}
			git push origin "+${branch}"
		done

		# local _local_branches_that_can_be_deleted=''; _local_branches_that_can_be_deleted=$(git branch -vv | grep -v "\[origin\/" | awk '{print "git branch -D "$1}' | grep -v "git branch -D \*")
		# if [[ "${_local_branches_that_can_be_deleted}" != '' ]]; then
		# 	Logger log info "The following local branches have no remote equivalent so MAY be deleted"
		# 	echo "${_local_branches_that_can_be_deleted}"
		# fi
	}

	updateSumBranch() {
		declare _base_branch="${1:-master}"

		local _branch_with_pr_summation="gavindidrichsen/${_base_branch}/sum"
		local _branch_to_merge_in="${_base_branch}"

		# remove the local summing branch if it doesn't exist on remote
		if ! ( git branch -a | egrep "remotes/origin/${_branch_with_pr_summation}" ) &&
			(git rev-parse --verify --quiet "${_branch_with_pr_summation}"); then
			Logger log info "removing local summing branch since it doesn't exist on the remote"
			git branch -D "${_branch_with_pr_summation}"
		fi

		# bomb out if '.sumbranch_*' doesn't exist
		local filename=".sumbranch_${_branch_to_merge_in//\//_}"
		if ! [[ -f "${filename}" ]]; then
			Logger log info "since \"${filename}\" file doesn't exist, not creating a sum branch"
			return
		fi

		# otherwise, checkout summing branch (create it remotely and locally if it doesn't already exist)
		git checkout -B "${_branch_with_pr_summation}" "${_base_branch}"
		git fetch --prune
		
		# rebase any remote commits first
		git rebase "origin/${_branch_with_pr_summation}"

		Logger log info "sum latest changes into ${_branch_with_pr_summation}"
		local result=$( cat "${filename}")
		while read line; do
			Logger log info "merging ${line}"
			git rebase "${line}"
			git push origin "+${_branch_with_pr_summation}"
		done <<< "${result}"
	}

	local branch=$(Repo getBranch ${@})
	local buildDir=$(Repo getBuildDir ${branch})

	local _log="Logger log"

	$@
}