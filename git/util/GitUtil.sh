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

		local _branch_with_pr_summation="gavindidrichsen/${_base_branch}/sum"
		_updateSumBranch(){
			declare _branch_to_merge_in="${1}"

			# don't merge sum branch into itself
			if [[ "${_branch_to_merge_in}"  == "${_branch_with_pr_summation}" ]]; then
				return
			fi

			# remove the local summing branch--if it exists--before creating a new remote one
			if ! ( git branch -a | egrep "remotes/origin/${_branch_with_pr_summation}" ); then
				Logger info "Removing local summing branch before creating a new remote one"
				git branch -D "${_branch_with_pr_summation}"
			fi

			# checkout summing branch (create it remotely and locally if it doesn't already exist)
			git checkout -B "${_branch_with_pr_summation}"
			git fetch --prune
			# rebase any remote commits first
			git rebase "origin/${_branch_with_pr_summation}"

			# now rebase in the local branch
			Logger debug "Merge into ${_branch_with_pr_summation} all changes from ${_branch_to_merge_in}"
			git rebase "${_branch_to_merge_in}"
			git push origin "+${_branch_with_pr_summation}"
		}

		Logger debug "fetching upstream"
		git fetch upstream --prune
		git fetch origin --prune

		Logger debug  "rebasing ${_base_branch} with upstream/${_base_branch}"
		git checkout ${_base_branch}
		# git fetch --prune
		# git rebase origin/${_base_branch} <=== NOT doing this because I always want ${_base_branch} to equal upstream/${_base_branch}
		git rebase upstream/${_base_branch}
		git push origin +${_base_branch}

		_updateSumBranch "${_base_branch}"

		list_of_branches=$( git branch -a --sort=-committerdate | perl -nle 'print "$1$2" if /(?<=remotes\/origin\/)(gavindidrich[s]{0,1}en\/)(.*)/')
		# Logger debug  "All of my 'gavindidrichsen' branches"
		# echo "${list_of_branches}"

		# update all branches based off master
		pr_branches=$(echo "${list_of_branches}" | grep "/${_base_branch}/pr/")
		Logger debug "list of pr branches based off ${_base_branch}"
		echo "${pr_branches}"

		for branch in $(echo "${pr_branches}"); do
			Logger info "Updating [${branch}]"
			git checkout "${branch}"
			git rebase "origin/${branch}"
			git rebase ${_base_branch}
			git push origin "+${branch}"

			_updateSumBranch "${branch}"
		done

		# local _local_branches_that_can_be_deleted=''; _local_branches_that_can_be_deleted=$(git branch -vv | grep -v "\[origin\/" | awk '{print "git branch -D "$1}' | grep -v "git branch -D \*")
		# if [[ "${_local_branches_that_can_be_deleted}" != '' ]]; then
		# 	Logger debug "The following local branches have no remote equivalent so MAY be deleted"
		# 	echo "${_local_branches_that_can_be_deleted}"
		# fi
	}

	local branch=$(Repo getBranch ${@})
	local buildDir=$(Repo getBuildDir ${branch})

	local _log="Logger log"

	$@
}