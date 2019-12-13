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
		if (git --no-pager diff --exit-code --quiet ${_base_branch} upstream/${_base_branch}); then
			Logger log info "no difference between ${_base_branch} upstream/${_base_branch}"
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

		list_of_branches=$( git branch -a --sort=-committerdate | perl -nle 'print "$1$2" if /(?<=remotes\/origin\/)(gavindidrichsen\/)(.*)/')
		# echo "${list_of_branches}"

		# update all branches based off master
		regex_of_base_branch=$(echo "${_base_branch}" | sed 's|/|\\/|g')
		pr_branches=$(echo "${list_of_branches}" | grep "/${regex_of_base_branch}/")

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

	patch() {
        local pr_number=""
        local base_branch=""
        while [[ $# -gt 0 ]]
        do
        key="$1"

        case $key in
            --pr)
            pr_number="$2"
            shift # past argument
            shift # past value
            ;;
            --from)
            base_branch="$2"
            shift # past argument
            shift # past value
            ;;
            --onto)
            rebasing_branch="$2"
            shift # past argument
            shift # past value
            ;;
            *)    # unknown option
            shift # past argument
            ;;
        esac
        done

        Logger log debug "fetching PR ${pr_number}"
        local pr_reference_branch="pr/${base_branch}/${pr_number}"
        git fetch --force --verbose origin pull/${pr_number}/head:${pr_reference_branch}

        Logger log debug "creating the patch files for difference between ${base_branch}..${pr_reference_branch}"
        local patch_directory="${__dir}/patches/${pr_reference_branch}"
        mkdir -p ${patch_directory}
        git format-patch ${base_branch}..${pr_reference_branch} -o ${patch_directory}
        
        Logger log debug "patching PR ${pr_number} onto ${rebasing_branch}"
        git checkout ${rebasing_branch}
        git am ${patch_directory}/*.patch
    }

    rebase_branch() {
        local base_branch=""
        local new_branch_name=""
        local should_be_recreated="false"
        while [[ $# -gt 0 ]]
        do
        key="$1"

        case $key in
            --from)
            base_branch="$2"
            shift # past argument
            shift # past value
            ;;
            --called)
            new_branch_name="$2"
            shift # past argument
            shift # past value
            ;;
            --delete-and-recreate)
            should_be_recreated="true"
            shift # past argument
            ;;
            *)    # unknown option
            shift # past argument
            ;;
        esac
        done

        # either create or rebase the branch
        if (! git branch | grep "${new_branch_name}") || [[ "${should_be_recreated}" = "true" ]]; then 
            Logger log info "creating '${new_branch_name}' branch from '${base_branch}'"
            git checkout ${base_branch}
            git branch -D ${new_branch_name} || Logger log debug "${new_branch_name} already deleted"
            git checkout -b ${new_branch_name} ${base_branch}
        else
            Logger log info  "rebasing '${new_branch_name}' branch with '${base_branch}'"
            git rebase ${base_branch} ${new_branch_name} 
        fi
    }

	$@
}