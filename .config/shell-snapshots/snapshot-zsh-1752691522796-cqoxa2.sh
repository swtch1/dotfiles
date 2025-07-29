# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
VCS_INFO_formats () {
	setopt localoptions noksharrays NO_shwordsplit
	local msg tmp
	local -i i
	local -A hook_com
	hook_com=(action "$1" action_orig "$1" branch "$2" branch_orig "$2" base "$3" base_orig "$3" staged "$4" staged_orig "$4" unstaged "$5" unstaged_orig "$5" revision "$6" revision_orig "$6" misc "$7" misc_orig "$7" vcs "${vcs}" vcs_orig "${vcs}") 
	hook_com[base-name]="${${hook_com[base]}:t}" 
	hook_com[base-name_orig]="${hook_com[base-name]}" 
	hook_com[subdir]="$(VCS_INFO_reposub ${hook_com[base]})" 
	hook_com[subdir_orig]="${hook_com[subdir]}" 
	: vcs_info-patch-9b9840f2-91e5-4471-af84-9e9a0dc68c1b
	for tmp in base base-name branch misc revision subdir
	do
		hook_com[$tmp]="${hook_com[$tmp]//\%/%%}" 
	done
	VCS_INFO_hook 'post-backend'
	if [[ -n ${hook_com[action]} ]]
	then
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" actionformats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b|%a]%u%c-' 
	else
		zstyle -a ":vcs_info:${vcs}:${usercontext}:${rrn}" formats msgs
		(( ${#msgs} < 1 )) && msgs[1]=' (%s)-[%b]%u%c-' 
	fi
	if [[ -n ${hook_com[staged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" stagedstr tmp
		[[ -z ${tmp} ]] && hook_com[staged]='S'  || hook_com[staged]=${tmp} 
	fi
	if [[ -n ${hook_com[unstaged]} ]]
	then
		zstyle -s ":vcs_info:${vcs}:${usercontext}:${rrn}" unstagedstr tmp
		[[ -z ${tmp} ]] && hook_com[unstaged]='U'  || hook_com[unstaged]=${tmp} 
	fi
	if [[ ${quiltmode} != 'standalone' ]] && VCS_INFO_hook "pre-addon-quilt"
	then
		local REPLY
		VCS_INFO_quilt addon
		hook_com[quilt]="${REPLY}" 
		unset REPLY
	elif [[ ${quiltmode} == 'standalone' ]]
	then
		hook_com[quilt]=${hook_com[misc]} 
	fi
	(( ${#msgs} > maxexports )) && msgs[$(( maxexports + 1 )),-1]=() 
	for i in {1..${#msgs}}
	do
		if VCS_INFO_hook "set-message" $(( $i - 1 )) "${msgs[$i]}"
		then
			zformat -f msg ${msgs[$i]} a:${hook_com[action]} b:${hook_com[branch]} c:${hook_com[staged]} i:${hook_com[revision]} m:${hook_com[misc]} r:${hook_com[base-name]} s:${hook_com[vcs]} u:${hook_com[unstaged]} Q:${hook_com[quilt]} R:${hook_com[base]} S:${hook_com[subdir]}
			msgs[$i]=${msg} 
		else
			msgs[$i]=${hook_com[message]} 
		fi
	done
	hook_com=() 
	backend_misc=() 
	return 0
}
acp () {
	if [[ -z "$1" ]]
	then
		unset AWS_DEFAULT_PROFILE AWS_PROFILE AWS_EB_PROFILE
		unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
		echo AWS profile cleared.
		return
	fi
	local -a available_profiles
	available_profiles=($(aws_profiles)) 
	if [[ -z "${available_profiles[(r)$1]}" ]]
	then
		echo "${fg[red]}Profile '$1' not found in '${AWS_CONFIG_FILE:-$HOME/.aws/config}'" >&2
		echo "Available profiles: ${(j:, :)available_profiles:-no profiles found}${reset_color}" >&2
		return 1
	fi
	local profile="$1" 
	local mfa_token="$2" 
	local aws_access_key_id="$(aws configure get aws_access_key_id --profile $profile)" 
	local aws_secret_access_key="$(aws configure get aws_secret_access_key --profile $profile)" 
	local aws_session_token="$(aws configure get aws_session_token --profile $profile)" 
	local mfa_serial="$(aws configure get mfa_serial --profile $profile)" 
	local sess_duration="$(aws configure get duration_seconds --profile $profile)" 
	if [[ -n "$mfa_serial" ]]
	then
		local -a mfa_opt
		if [[ -z "$mfa_token" ]]
		then
			echo -n "Please enter your MFA token for $mfa_serial: "
			read -r mfa_token
		fi
		if [[ -z "$sess_duration" ]]
		then
			echo -n "Please enter the session duration in seconds (900-43200; default: 3600, which is the default maximum for a role): "
			read -r sess_duration
		fi
		mfa_opt=(--serial-number "$mfa_serial" --token-code "$mfa_token" --duration-seconds "${sess_duration:-3600}") 
	fi
	local role_arn="$(aws configure get role_arn --profile $profile)" 
	local sess_name="$(aws configure get role_session_name --profile $profile)" 
	if [[ -n "$role_arn" ]]
	then
		aws_command=(aws sts assume-role --role-arn "$role_arn" "${mfa_opt[@]}") 
		local external_id="$(aws configure get external_id --profile $profile)" 
		if [[ -n "$external_id" ]]
		then
			aws_command+=(--external-id "$external_id") 
		fi
		local source_profile="$(aws configure get source_profile --profile $profile)" 
		if [[ -z "$sess_name" ]]
		then
			sess_name="${source_profile:-profile}" 
		fi
		aws_command+=(--profile="${source_profile:-profile}" --role-session-name "${sess_name}") 
		echo "Assuming role $role_arn using profile ${source_profile:-profile}"
	else
		aws_command=(aws sts get-session-token --profile="$profile" "${mfa_opt[@]}") 
		echo "Obtaining session token for profile $profile"
	fi
	aws_command+=(--query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' --output text) 
	local -a credentials
	credentials=(${(ps:\t:)"$(${aws_command[@]})"}) 
	if [[ -n "$credentials" ]]
	then
		aws_access_key_id="${credentials[1]}" 
		aws_secret_access_key="${credentials[2]}" 
		aws_session_token="${credentials[3]}" 
	fi
	if [[ -n "${aws_access_key_id}" && -n "$aws_secret_access_key" ]]
	then
		export AWS_DEFAULT_PROFILE="$profile" 
		export AWS_PROFILE="$profile" 
		export AWS_EB_PROFILE="$profile" 
		export AWS_ACCESS_KEY_ID="$aws_access_key_id" 
		export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key" 
		if [[ -n "$aws_session_token" ]]
		then
			export AWS_SESSION_TOKEN="$aws_session_token" 
		else
			unset AWS_SESSION_TOKEN
		fi
		echo "Switched to AWS Profile: $profile"
	fi
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
agg () {
	ag --skip-vcs-ignores --follow --ignore node_modules --go $@
}
agp () {
	echo $AWS_PROFILE
}
agr () {
	echo $AWS_REGION
}
alias_value () {
	(( $+aliases[$1] )) && echo $aliases[$1]
}
analyze_report () {
	rpt_id=$1 
	speedmgmt queue send raw --queue-url https://sqs.us-east-1.amazonaws.com/094668123143/dev-sstenant-external-api-gateway --message '{"msgType":"event","version":"0.0.1","name":"sigReport","type":"STRING","stringVal":{"val":"trafficReplayStarted"},"tags":{"source":"jmt-test","tenantId":"63b7c67e-233d-4e9e-a9aa-62db482be7ac","testReportId":"'$rpt_id'"}}'
}
asp () {
	if [[ -z "$1" ]]
	then
		unset AWS_DEFAULT_PROFILE AWS_PROFILE AWS_EB_PROFILE AWS_PROFILE_REGION
		_aws_clear_state
		echo AWS profile cleared.
		return
	fi
	local -a available_profiles
	available_profiles=($(aws_profiles)) 
	if [[ -z "${available_profiles[(r)$1]}" ]]
	then
		echo "${fg[red]}Profile '$1' not found in '${AWS_CONFIG_FILE:-$HOME/.aws/config}'" >&2
		echo "Available profiles: ${(j:, :)available_profiles:-no profiles found}${reset_color}" >&2
		return 1
	fi
	export AWS_DEFAULT_PROFILE=$1 
	export AWS_PROFILE=$1 
	export AWS_EB_PROFILE=$1 
	export AWS_PROFILE_REGION=$(aws configure get region) 
	_aws_update_state
	if [[ "$2" == "login" ]]
	then
		if [[ -n "$3" ]]
		then
			aws sso login --sso-session $3
		else
			aws sso login
		fi
	elif [[ "$2" == "logout" ]]
	then
		aws sso logout
	fi
}
asr () {
	if [[ -z "$1" ]]
	then
		unset AWS_DEFAULT_REGION AWS_REGION
		_aws_update_state
		echo AWS region cleared.
		return
	fi
	local -a available_regions
	available_regions=($(aws_regions)) 
	if [[ -z "${available_regions[(r)$1]}" ]]
	then
		echo "${fg[red]}Available regions: \n$(aws_regions)"
		return 1
	fi
	export AWS_REGION=$1 
	export AWS_DEFAULT_REGION=$1 
	_aws_update_state
}
aws_change_access_key () {
	if [[ -z "$1" ]]
	then
		echo "usage: $0 <profile>"
		return 1
	fi
	local profile="$1" 
	local original_aws_access_key_id="$(aws configure get aws_access_key_id --profile $profile)" 
	asp "$profile" || return 1
	echo "Generating a new access key pair for you now."
	if aws --no-cli-pager iam create-access-key
	then
		echo "Insert the newly generated credentials when asked."
		aws --no-cli-pager configure --profile $profile
	else
		echo "Current access keys:"
		aws --no-cli-pager iam list-access-keys
		echo "Profile \"${profile}\" is currently using the $original_aws_access_key_id key. You can delete an old access key by running \`aws --profile $profile iam delete-access-key --access-key-id AccessKeyId\`"
		return 1
	fi
	read -q "yn?Would you like to disable your previous access key (${original_aws_access_key_id}) now? "
	case $yn in
		([Yy]*) echo -n "\nDisabling access key ${original_aws_access_key_id}..."
			if aws --no-cli-pager iam update-access-key --access-key-id ${original_aws_access_key_id} --status Inactive
			then
				echo "done."
			else
				echo "\nFailed to disable ${original_aws_access_key_id} key."
			fi ;;
		(*) echo "" ;;
	esac
	echo "You can now safely delete the old access key by running \`aws --profile $profile iam delete-access-key --access-key-id ${original_aws_access_key_id}\`"
	echo "Your current keys are:"
	aws --no-cli-pager iam list-access-keys
}
aws_profiles () {
	aws --no-cli-pager configure list-profiles 2> /dev/null && return
	[[ -r "${AWS_CONFIG_FILE:-$HOME/.aws/config}" ]] || return 1
	grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} --color=never -Eo '\[.*\]' "${AWS_CONFIG_FILE:-$HOME/.aws/config}" | sed -E 's/^[[:space:]]*\[(profile)?[[:space:]]*([^[:space:]]+)\][[:space:]]*$/\2/g'
}
aws_prompt_info () {
	local _aws_to_show
	local region="${AWS_REGION:-${AWS_DEFAULT_REGION:-$AWS_PROFILE_REGION}}" 
	if [[ -n "$AWS_PROFILE" ]]
	then
		_aws_to_show+="${ZSH_THEME_AWS_PROFILE_PREFIX="<aws:"}${AWS_PROFILE}${ZSH_THEME_AWS_PROFILE_SUFFIX=">"}" 
	fi
	if [[ -n "$region" ]]
	then
		[[ -n "$_aws_to_show" ]] && _aws_to_show+="${ZSH_THEME_AWS_DIVIDER=" "}" 
		_aws_to_show+="${ZSH_THEME_AWS_REGION_PREFIX="<region:"}${region}${ZSH_THEME_AWS_REGION_SUFFIX=">"}" 
	fi
	echo "$_aws_to_show"
}
aws_regions () {
	local region
	if [[ -n $AWS_DEFAULT_REGION ]]
	then
		region="$AWS_DEFAULT_REGION" 
	elif [[ -n $AWS_REGION ]]
	then
		region="$AWS_REGION" 
	else
		region="us-west-1" 
	fi
	if [[ -n $AWS_DEFAULT_PROFILE || -n $AWS_PROFILE ]]
	then
		aws ec2 describe-regions --region $region | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} RegionName | awk -F ':' '{gsub(/"/, "", $2);gsub(/,/, "", $2);gsub(/ /, "", $2);  print $2}'
	else
		echo "You must specify a AWS profile."
	fi
}
awslogin () {
	echo "--> unsetting AWS env vars"
	unset AWS_ACCESS_KEY_ID
	unset AWS_SECRET_ACCESS_KEY
	unset AWS_SESSION_TOKEN
	echo '--> login'
	aws sso login --profile dev
}
azure_prompt_info () {
	return 1
}
b64d () {
	echo "$1" | base64 -d
}
bashcompinit () {
	# undefined
	builtin autoload -XUz
}
bzr_prompt_info () {
	local bzr_branch
	bzr_branch=$(bzr nick 2>/dev/null)  || return
	if [[ -n "$bzr_branch" ]]
	then
		local bzr_dirty="" 
		if [[ -n $(bzr status 2>/dev/null) ]]
		then
			bzr_dirty=" %{$fg[red]%}*%{$reset_color%}" 
		fi
		printf "%s%s%s%s" "$ZSH_THEME_SCM_PROMPT_PREFIX" "bzr::${bzr_branch##*:}" "$bzr_dirty" "$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}
chruby_prompt_info () {
	return 1
}
clipcopy () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
clippaste () {
	unfunction clipcopy clippaste
	detect-clipboard || true
	"$0" "$@"
}
colors () {
	emulate -L zsh
	typeset -Ag color colour
	color=(00 none 01 bold 02 faint 22 normal 03 italic 23 no-italic 04 underline 24 no-underline 05 blink 25 no-blink 07 reverse 27 no-reverse 08 conceal 28 no-conceal 30 black 40 bg-black 31 red 41 bg-red 32 green 42 bg-green 33 yellow 43 bg-yellow 34 blue 44 bg-blue 35 magenta 45 bg-magenta 36 cyan 46 bg-cyan 37 white 47 bg-white 39 default 49 bg-default) 
	local k
	for k in ${(k)color}
	do
		color[${color[$k]}]=$k 
	done
	for k in ${color[(I)3?]}
	do
		color[fg-${color[$k]}]=$k 
	done
	for k in grey gray
	do
		color[$k]=${color[black]} 
		color[fg-$k]=${color[$k]} 
		color[bg-$k]=${color[bg-black]} 
	done
	colour=(${(kv)color}) 
	local lc=$'\e[' rc=m 
	typeset -Hg reset_color bold_color
	reset_color="$lc${color[none]}$rc" 
	bold_color="$lc${color[bold]}$rc" 
	typeset -AHg fg fg_bold fg_no_bold
	for k in ${(k)color[(I)fg-*]}
	do
		fg[${k#fg-}]="$lc${color[$k]}$rc" 
		fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc" 
		fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
	typeset -AHg bg bg_bold bg_no_bold
	for k in ${(k)color[(I)bg-*]}
	do
		bg[${k#bg-}]="$lc${color[$k]}$rc" 
		bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc" 
		bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
}
compaudit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compdef () {
	local opt autol type func delete eval new i ret=0 cmd svc 
	local -a match mbegin mend
	emulate -L zsh
	setopt extendedglob
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	while getopts "anpPkKde" opt
	do
		case "$opt" in
			(a) autol=yes  ;;
			(n) new=yes  ;;
			([pPkK]) if [[ -n "$type" ]]
				then
					print -u2 "$0: type already set to $type"
					return 1
				fi
				if [[ "$opt" = p ]]
				then
					type=pattern 
				elif [[ "$opt" = P ]]
				then
					type=postpattern 
				elif [[ "$opt" = K ]]
				then
					type=widgetkey 
				else
					type=key 
				fi ;;
			(d) delete=yes  ;;
			(e) eval=yes  ;;
		esac
	done
	shift OPTIND-1
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	if [[ -z "$delete" ]]
	then
		if [[ -z "$eval" ]] && [[ "$1" = *\=* ]]
		then
			while (( $# ))
			do
				if [[ "$1" = *\=* ]]
				then
					cmd="${1%%\=*}" 
					svc="${1#*\=}" 
					func="$_comps[${_services[(r)$svc]:-$svc}]" 
					[[ -n ${_services[$svc]} ]] && svc=${_services[$svc]} 
					[[ -z "$func" ]] && func="${${_patcomps[(K)$svc][1]}:-${_postpatcomps[(K)$svc][1]}}" 
					if [[ -n "$func" ]]
					then
						_comps[$cmd]="$func" 
						_services[$cmd]="$svc" 
					else
						print -u2 "$0: unknown command or service: $svc"
						ret=1 
					fi
				else
					print -u2 "$0: invalid argument: $1"
					ret=1 
				fi
				shift
			done
			return ret
		fi
		func="$1" 
		[[ -n "$autol" ]] && autoload -rUz "$func"
		shift
		case "$type" in
			(widgetkey) while [[ -n $1 ]]
				do
					if [[ $# -lt 3 ]]
					then
						print -u2 "$0: compdef -K requires <widget> <comp-widget> <key>"
						return 1
					fi
					[[ $1 = _* ]] || 1="_$1" 
					[[ $2 = .* ]] || 2=".$2" 
					[[ $2 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$1" "$2" "$func"
					if [[ -n $new ]]
					then
						bindkey "$3" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] && bindkey "$3" "$1"
					else
						bindkey "$3" "$1"
					fi
					shift 3
				done ;;
			(key) if [[ $# -lt 2 ]]
				then
					print -u2 "$0: missing keys"
					return 1
				fi
				if [[ $1 = .* ]]
				then
					[[ $1 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" "$1" "$func"
				else
					[[ $1 = menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" ".$1" "$func"
				fi
				shift
				for i
				do
					if [[ -n $new ]]
					then
						bindkey "$i" | IFS=$' \t' read -A opt
						[[ $opt[-1] = undefined-key ]] || continue
					fi
					bindkey "$i" "$func"
				done ;;
			(*) while (( $# ))
				do
					if [[ "$1" = -N ]]
					then
						type=normal 
					elif [[ "$1" = -p ]]
					then
						type=pattern 
					elif [[ "$1" = -P ]]
					then
						type=postpattern 
					else
						case "$type" in
							(pattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_patcomps[$match[1]]="=$match[2]=$func" 
								else
									_patcomps[$1]="$func" 
								fi ;;
							(postpattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_postpatcomps[$match[1]]="=$match[2]=$func" 
								else
									_postpatcomps[$1]="$func" 
								fi ;;
							(*) if [[ "$1" = *\=* ]]
								then
									cmd="${1%%\=*}" 
									svc=yes 
								else
									cmd="$1" 
									svc= 
								fi
								if [[ -z "$new" || -z "${_comps[$1]}" ]]
								then
									_comps[$cmd]="$func" 
									[[ -n "$svc" ]] && _services[$cmd]="${1#*\=}" 
								fi ;;
						esac
					fi
					shift
				done ;;
		esac
	else
		case "$type" in
			(pattern) unset "_patcomps[$^@]" ;;
			(postpattern) unset "_postpatcomps[$^@]" ;;
			(key) print -u2 "$0: cannot restore key bindings"
				return 1 ;;
			(*) unset "_comps[$^@]" ;;
		esac
	fi
}
compdump () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compgen () {
	local opts prefix suffix job OPTARG OPTIND ret=1 
	local -a name res results jids
	local -A shortopts
	emulate -L sh
	setopt kshglob noshglob braceexpand nokshautoload
	shortopts=(a alias b builtin c command d directory e export f file g group j job k keyword u user v variable) 
	while getopts "o:A:G:C:F:P:S:W:X:abcdefgjkuv" name
	do
		case $name in
			([abcdefgjkuv]) OPTARG="${shortopts[$name]}"  ;&
			(A) case $OPTARG in
					(alias) results+=("${(k)aliases[@]}")  ;;
					(arrayvar) results+=("${(k@)parameters[(R)array*]}")  ;;
					(binding) results+=("${(k)widgets[@]}")  ;;
					(builtin) results+=("${(k)builtins[@]}" "${(k)dis_builtins[@]}")  ;;
					(command) results+=("${(k)commands[@]}" "${(k)aliases[@]}" "${(k)builtins[@]}" "${(k)functions[@]}" "${(k)reswords[@]}")  ;;
					(directory) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N-/)) 
						setopt nobareglobqual ;;
					(disabled) results+=("${(k)dis_builtins[@]}")  ;;
					(enabled) results+=("${(k)builtins[@]}")  ;;
					(export) results+=("${(k)parameters[(R)*export*]}")  ;;
					(file) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N)) 
						setopt nobareglobqual ;;
					(function) results+=("${(k)functions[@]}")  ;;
					(group) emulate zsh
						_groups -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(hostname) emulate zsh
						_hosts -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(job) results+=("${savejobtexts[@]%% *}")  ;;
					(keyword) results+=("${(k)reswords[@]}")  ;;
					(running) jids=("${(@k)savejobstates[(R)running*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(stopped) jids=("${(@k)savejobstates[(R)suspended*]}") 
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *}) 
						done ;;
					(setopt | shopt) results+=("${(k)options[@]}")  ;;
					(signal) results+=("SIG${^signals[@]}")  ;;
					(user) results+=("${(k)userdirs[@]}")  ;;
					(variable) results+=("${(k)parameters[@]}")  ;;
					(helptopic)  ;;
				esac ;;
			(F) COMPREPLY=() 
				local -a args
				args=("${words[0]}" "${@[-1]}" "${words[CURRENT-2]}") 
				() {
					typeset -h words
					$OPTARG "${args[@]}"
				}
				results+=("${COMPREPLY[@]}")  ;;
			(G) setopt nullglob
				results+=(${~OPTARG}) 
				unsetopt nullglob ;;
			(W) results+=(${(Q)~=OPTARG})  ;;
			(C) results+=($(eval $OPTARG))  ;;
			(P) prefix="$OPTARG"  ;;
			(S) suffix="$OPTARG"  ;;
			(X) if [[ ${OPTARG[0]} = '!' ]]
				then
					results=("${(M)results[@]:#${OPTARG#?}}") 
				else
					results=("${results[@]:#$OPTARG}") 
				fi ;;
		esac
	done
	print -l -r -- "$prefix${^results[@]}$suffix"
}
compinit () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
compinstall () {
	# undefined
	builtin autoload -XUz /usr/share/zsh/5.9/functions
}
complete () {
	emulate -L zsh
	local args void cmd print remove
	args=("$@") 
	zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
	if [[ -n $print ]]
	then
		printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
	elif [[ -n $remove ]]
	then
		for cmd
		do
			unset "_comps[$cmd]"
		done
	else
		compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
	fi
}
conda_prompt_info () {
	return 1
}
current_branch () {
	git_current_branch
}
d () {
	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -n 10
	fi
}
default () {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
detect-clipboard () {
	emulate -L zsh
	if [[ "${OSTYPE}" == darwin* ]] && (( ${+commands[pbcopy]} )) && (( ${+commands[pbpaste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | pbcopy
		}
		clippaste () {
			pbpaste
		}
	elif [[ "${OSTYPE}" == (cygwin|msys)* ]]
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" > /dev/clipboard
		}
		clippaste () {
			cat /dev/clipboard
		}
	elif (( $+commands[clip.exe] )) && (( $+commands[powershell.exe] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | clip.exe
		}
		clippaste () {
			powershell.exe -noprofile -command Get-Clipboard
		}
	elif [ -n "${WAYLAND_DISPLAY:-}" ] && (( ${+commands[wl-copy]} )) && (( ${+commands[wl-paste]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | wl-copy &> /dev/null &|
		}
		clippaste () {
			wl-paste --no-newline
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xsel]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xsel --clipboard --input
		}
		clippaste () {
			xsel --clipboard --output
		}
	elif [ -n "${DISPLAY:-}" ] && (( ${+commands[xclip]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | xclip -selection clipboard -in &> /dev/null &|
		}
		clippaste () {
			xclip -out -selection clipboard
		}
	elif (( ${+commands[lemonade]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | lemonade copy
		}
		clippaste () {
			lemonade paste
		}
	elif (( ${+commands[doitclient]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | doitclient wclip
		}
		clippaste () {
			doitclient wclip -r
		}
	elif (( ${+commands[win32yank]} ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | win32yank -i
		}
		clippaste () {
			win32yank -o
		}
	elif [[ $OSTYPE == linux-android* ]] && (( $+commands[termux-clipboard-set] ))
	then
		clipcopy () {
			cat "${1:-/dev/stdin}" | termux-clipboard-set
		}
		clippaste () {
			termux-clipboard-get
		}
	elif [ -n "${TMUX:-}" ] && (( ${+commands[tmux]} ))
	then
		clipcopy () {
			tmux load-buffer "${1:--}"
		}
		clippaste () {
			tmux save-buffer -
		}
	else
		_retry_clipboard_detection_or_fail () {
			local clipcmd="${1}" 
			shift
			if detect-clipboard
			then
				"${clipcmd}" "$@"
			else
				print "${clipcmd}: Platform $OSTYPE not supported or xclip/xsel not installed" >&2
				return 1
			fi
		}
		clipcopy () {
			_retry_clipboard_detection_or_fail clipcopy "$@"
		}
		clippaste () {
			_retry_clipboard_detection_or_fail clippaste "$@"
		}
		return 1
	fi
}
diff () {
	command diff --color "$@"
}
down-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
edit-command-line () {
	# undefined
	builtin autoload -XU
}
env_default () {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}
expand-or-complete-with-dots () {
	[[ $COMPLETION_WAITING_DOTS = true ]] && COMPLETION_WAITING_DOTS="%F{red}…%f" 
	printf '\e[?7l%s\e[?7h' "${(%)COMPLETION_WAITING_DOTS}"
	zle expand-or-complete
	zle redisplay
}
fig_osc () {
	printf "\033]697;$1\007" "${@:2}"
}
fig_precmd () {
	local LAST_STATUS=$? 
	fig_reset_hooks
	fig_osc "OSCUnlock=%s" "${QTERM_SESSION_ID}"
	fig_osc "Dir=%s" "$PWD"
	fig_osc "Shell=zsh"
	fig_osc "ShellPath=%s" "${Q_SHELL:-$SHELL}"
	if [[ -n "${WSL_DISTRO_NAME:-}" ]]
	then
		fig_osc "WSLDistro=%s" "${WSL_DISTRO_NAME}"
	fi
	fig_osc "PID=%d" "$$"
	fig_osc "ExitCode=%s" "${LAST_STATUS}"
	fig_osc "TTY=%s" "${TTY}"
	fig_osc "Log=%s" "${Q_LOG_LEVEL}"
	fig_osc "ZshAutosuggestionColor=%s" "${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE}"
	fig_osc "FigAutosuggestionColor=%s" "${Q_AUTOSUGGEST_HIGHLIGHT_STYLE}"
	fig_osc "User=%s" "${USER:-root}"
	if [ "$Q_HAS_SET_PROMPT" -eq 1 ]
	then
		fig_preexec
	fi
	START_PROMPT=$'\033]697;StartPrompt\007' 
	END_PROMPT=$'\033]697;EndPrompt\007' 
	NEW_CMD=$'\033]697;NewCmd='"${QTERM_SESSION_ID}"$'\007' 
	Q_USER_PS1="$PS1" 
	Q_USER_PROMPT="$PROMPT" 
	Q_USER_prompt="$prompt" 
	Q_USER_PS2="$PS2" 
	Q_USER_PROMPT2="$PROMPT2" 
	Q_USER_PS3="$PS3" 
	Q_USER_PROMPT3="$PROMPT3" 
	Q_USER_PS4="$PS4" 
	Q_USER_PROMPT4="$PROMPT4" 
	Q_USER_RPS1="$RPS1" 
	Q_USER_RPROMPT="$RPROMPT" 
	Q_USER_RPS2="$RPS2" 
	Q_USER_RPROMPT2="$RPROMPT2" 
	if [ -n "${PROMPT+x}" ]
	then
		PROMPT="%{$START_PROMPT%}$PROMPT%{$END_PROMPT$NEW_CMD%}" 
	elif [ -n "${prompt+x}" ]
	then
		prompt="%{$START_PROMPT%}$prompt%{$END_PROMPT$NEW_CMD%}" 
	else
		PS1="%{$START_PROMPT%}$PS1%{$END_PROMPT$NEW_CMD%}" 
	fi
	if [ -n "${PROMPT2+x}" ]
	then
		PROMPT2="%{$START_PROMPT%}$PROMPT2%{$END_PROMPT%}" 
	else
		PS2="%{$START_PROMPT%}$PS2%{$END_PROMPT%}" 
	fi
	if [ -n "${PROMPT3+x}" ]
	then
		PROMPT3="%{$START_PROMPT%}$PROMPT3%{$END_PROMPT$NEW_CMD%}" 
	else
		PS3="%{$START_PROMPT%}$PS3%{$END_PROMPT$NEW_CMD%}" 
	fi
	if [ -n "${PROMPT4+x}" ]
	then
		PROMPT4="%{$START_PROMPT%}$PROMPT4%{$END_PROMPT%}" 
	else
		PS4="%{$START_PROMPT%}$PS4%{$END_PROMPT%}" 
	fi
	if [ -n "${RPROMPT+x}" ]
	then
		RPROMPT="%{$START_PROMPT%}$RPROMPT%{$END_PROMPT%}" 
	else
		RPS1="%{$START_PROMPT%}$RPS1%{$END_PROMPT%}" 
	fi
	if [ -n "${RPROMPT2+x}" ]
	then
		RPROMPT2="%{$START_PROMPT%}$RPROMPT2%{$END_PROMPT%}" 
	else
		RPS2="%{$START_PROMPT%}$RPS2%{$END_PROMPT%}" 
	fi
	Q_HAS_SET_PROMPT=1 
	if command -v q > /dev/null 2>&1
	then
		(
			command q _ pre-cmd --alias "$(\alias)" > /dev/null 2>&1 &
		) > /dev/null 2>&1
	fi
}
fig_preexec () {
	if [ -n "${PS1+x}" ]
	then
		PS1="$Q_USER_PS1" 
	fi
	if [ -n "${PROMPT+x}" ]
	then
		PROMPT="$Q_USER_PROMPT" 
	fi
	if [ -n "${prompt+x}" ]
	then
		prompt="$Q_USER_prompt" 
	fi
	if [ -n "${PS2+x}" ]
	then
		PS2="$Q_USER_PS2" 
	fi
	if [ -n "${PROMPT2+x}" ]
	then
		PROMPT2="$Q_USER_PROMPT2" 
	fi
	if [ -n "${PS3+x}" ]
	then
		PS3="$Q_USER_PS3" 
	fi
	if [ -n "${PROMPT3+x}" ]
	then
		PROMPT3="$Q_USER_PROMPT3" 
	fi
	if [ -n "${PS4+x}" ]
	then
		PS4="$Q_USER_PS4" 
	fi
	if [ -n "${PROMPT4+x}" ]
	then
		PROMPT4="$Q_USER_PROMPT4" 
	fi
	if [ -n "${RPS1+x}" ]
	then
		RPS1="$Q_USER_RPS1" 
	fi
	if [ -n "${RPROMPT+x}" ]
	then
		RPROMPT="$Q_USER_RPROMPT" 
	fi
	if [ -n "${RPS2+x}" ]
	then
		RPS2="$Q_USER_RPS2" 
	fi
	if [ -n "${RPROMPT2+x}" ]
	then
		RPROMPT2="$Q_USER_RPROMPT2" 
	fi
	Q_HAS_SET_PROMPT=0 
	fig_osc "OSCLock=%s" "${QTERM_SESSION_ID}"
	fig_osc PreExec
}
fig_reset_hooks () {
	if [[ "$precmd_functions[-1]" != fig_precmd ]]
	then
		precmd_functions=(${(@)precmd_functions:#fig_precmd} fig_precmd) 
	fi
	if [[ "$preexec_functions[1]" != fig_preexec ]]
	then
		preexec_functions=(fig_preexec ${(@)preexec_functions:#fig_preexec}) 
	fi
}
fixme () {
	rg --smart-case --no-heading --line-number "FIXME: \(JMT\)"
	rg --smart-case --no-heading --line-number "BOOKMARK:"
}
gbda () {
	git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2> /dev/null
}
gbds () {
	local default_branch=$(git_main_branch) 
	(( ! $? )) || default_branch=$(git_develop_branch) 
	git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch
	do
		local merge_base=$(git merge-base $default_branch $branch) 
		if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]
		then
			git branch -D $branch
		fi
	done
}
gccd () {
	setopt localoptions extendedglob
	local repo="${${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}" 
	command git clone --recurse-submodules "$@" || return
	[[ -d "$_" ]] && cd "$_" || cd "${${repo:t}%.git/#}"
}
gdnolock () {
	git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
gdv () {
	git diff -w "$@" | view -
}
getent () {
	if [[ $1 = hosts ]]
	then
		sed 's/#.*//' /etc/$1 | grep -w $2
	elif [[ $2 = <-> ]]
	then
		grep ":$2:[^:]*$" /etc/$1
	else
		grep "^$2:" /etc/$1
	fi
}
ggf () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force origin "${b:=$1}"
}
ggfl () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force-with-lease origin "${b:=$1}"
}
ggl () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git pull origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git pull origin "${b:=$1}"
	fi
}
ggp () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git push origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git push origin "${b:=$1}"
	fi
}
ggpnp () {
	if [[ "$#" == 0 ]]
	then
		ggl && ggp
	else
		ggl "${*}" && ggp "${*}"
	fi
}
ggu () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git pull --rebase origin "${b:=$1}"
}
git_commits_ahead () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count @{upstream}..HEAD 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$commits$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
		fi
	fi
}
git_commits_behind () {
	if __git_prompt_git rev-parse --git-dir &> /dev/null
	then
		local commits="$(__git_prompt_git rev-list --count HEAD..@{upstream} 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX$commits$ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX"
		fi
	fi
}
git_current_branch () {
	local ref
	ref=$(__git_prompt_git symbolic-ref --quiet HEAD 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]]
	then
		[[ $ret == 128 ]] && return
		ref=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo ${ref#refs/heads/}
}
git_current_user_email () {
	__git_prompt_git config user.email 2> /dev/null
}
git_current_user_name () {
	__git_prompt_git config user.name 2> /dev/null
}
git_develop_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local branch
	for branch in dev devel develop development
	do
		if command git show-ref -q --verify refs/heads/$branch
		then
			echo $branch
			return 0
		fi
	done
	echo develop
	return 1
}
git_main_branch () {
	command git rev-parse --git-dir &> /dev/null || return
	local ref
	for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}
	do
		if command git show-ref -q --verify $ref
		then
			echo ${ref:t}
			return 0
		fi
	done
	echo master
	return 1
}
git_previous_branch () {
	local ref
	ref=$(__git_prompt_git rev-parse --quiet --symbolic-full-name @{-1} 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]] || [[ -z $ref ]]
	then
		return
	fi
	echo ${ref#refs/heads/}
}
git_prompt_ahead () {
	if [[ -n "$(__git_prompt_git rev-list origin/$(git_current_branch)..HEAD 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
	fi
}
git_prompt_behind () {
	if [[ -n "$(__git_prompt_git rev-list HEAD..origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_BEHIND"
	fi
}
git_prompt_info () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]}"
	fi
}
git_prompt_long_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_remote () {
	if [[ -n "$(__git_prompt_git show-ref origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS"
	else
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_MISSING"
	fi
}
git_prompt_short_sha () {
	local SHA
	SHA=$(__git_prompt_git rev-parse --short HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_status () {
	if [[ -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}" ]]
	then
		echo -n "${_OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]}"
	fi
}
git_push_initial () {
	output=$(g push --set-upstream origin $(g rev-parse --abbrev-ref HEAD)) 
}
git_remote_status () {
	local remote ahead behind git_remote_status git_remote_status_detailed
	remote=${$(__git_prompt_git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/} 
	if [[ -n ${remote} ]]
	then
		ahead=$(__git_prompt_git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l) 
		behind=$(__git_prompt_git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l) 
		if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}" 
		elif [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		fi
		if [[ -n $ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_PREFIX${remote:gs/%/%%}$git_remote_status_detailed$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_SUFFIX" 
		fi
		echo $git_remote_status
	fi
}
git_repo_name () {
	local repo_path
	if repo_path="$(__git_prompt_git rev-parse --show-toplevel 2>/dev/null)"  && [[ -n "$repo_path" ]]
	then
		echo ${repo_path:t}
	fi
}
gpw () {
	git --work-tree "$1" pull
}
grename () {
	if [[ -z "$1" || -z "$2" ]]
	then
		echo "Usage: $0 old_branch new_branch"
		return 1
	fi
	git branch -m "$1" "$2"
	if git push origin :"$1"
	then
		git push --set-upstream origin "$2"
	fi
}
gunwipall () {
	local _commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format=format:%H) 
	if [[ "$_commit" != "$(git rev-parse HEAD)" ]]
	then
		git reset $_commit || return 1
	fi
}
gwa () {
	dir=$1 
	git worktree add "$dir"
	direnv allow "$dir" &> /dev/null
	cd "$dir"
}
gwr () {
	if [[ -z "$1" ]]
	then
		d=$(dirname "$(pwd)") 
		git worktree remove . && cd "$d"
		return
	fi
	git worktree remove "$@"
}
handle_completion_insecurities () {
	local -aU insecure_dirs
	insecure_dirs=(${(f@):-"$(compaudit 2>/dev/null)"}) 
	[[ -z "${insecure_dirs}" ]] && return
	print "[oh-my-zsh] Insecure completion-dependent directories detected:"
	ls -ld "${(@)insecure_dirs}"
	cat <<EOD

[oh-my-zsh] For safety, we will not load completions from these directories until
[oh-my-zsh] you fix their permissions and ownership and restart zsh.
[oh-my-zsh] See the above list for directories with group or other writability.

[oh-my-zsh] To fix your permissions you can do so by disabling
[oh-my-zsh] the write permission of "group" and "others" and making sure that the
[oh-my-zsh] owner of these directories is either root or your current user.
[oh-my-zsh] The following command may help:
[oh-my-zsh]     compaudit | xargs chmod g-w,o-w

[oh-my-zsh] If the above didn't help or you want to skip the verification of
[oh-my-zsh] insecure directories you can set the variable ZSH_DISABLE_COMPFIX to
[oh-my-zsh] "true" before oh-my-zsh is sourced in your zshrc file.

EOD
}
hg_prompt_info () {
	return 1
}
is-at-least () {
	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done
}
is_plugin () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/plugins/$name/$name.plugin.zsh || builtin test -f $base_dir/plugins/$name/_$name
}
is_theme () {
	local base_dir=$1 
	local name=$2 
	builtin test -f $base_dir/$name.zsh-theme
}
jenv_prompt_info () {
	return 1
}
k9c () {
	local args=("$@") 
	context="${args[1]}" 
	args=("${args[@]:1}") 
	local includes_namespace=0 
	for arg in "${args[@]}"
	do
		if [ "$arg" = "-n" ]
		then
			includes_namespace=1 
			break
		fi
	done
	if [ $includes_namespace -eq 0 ]
	then
		args+=("-c" "ns") 
	else
		args+=("-c" "pods") 
	fi
	k9s --context "$context" "${args[@]}"
}
kj () {
	kubectl "$@" -o json | jq
}
kjx () {
	kubectl "$@" -o json | fx
}
kres () {
	kubectl set env $@ REFRESHED_AT=$(date +%Y%m%d%H%M%S)
}
ky () {
	kubectl "$@" -o yaml | yh
}
mkcd () {
	mkdir -p $@ && cd ${@:$#}
}
mkv () {
	local name="${1:-$PYTHON_VENV_NAME}" 
	local venvpath="${name:P}" 
	python3 -m venv "${name}" || return
	echo "Created venv in '${venvpath}'" >&2
	vrun "${name}"
}
mr () {
	args=($@) 
	case "${args[1]}" in
		(new) PAGER=cat glab mr new --title "$(git log -1 --pretty=%s)" --description "$(cat ~/.config/merge_template.txt)" --web --push ${args[@]:1} ;;
		(*) PAGER=cat glab mr $@ ;;
	esac
}
node-docs () {
	local section=${1:-all} 
	open_command "https://nodejs.org/docs/$(node --version)/api/$section.html"
}
notifywhen () {
	cmd=$1 
	interval=$2 
	if [[ "$interval" -eq 0 ]]
	then
		echo 'notifywhen: interval must be > 0'
		return
	fi
	start_time=$(date -u +%s) 
	while true
	do
		eval "$cmd" &> /dev/null
		if [ $? -eq 0 ]
		then
			end_time=$(date -u +%s) 
			duration="$(($end_time - $start_time))" 
			osascript -e "display notification \"completed after $duration seconds\" with title \"$1\""
			osascript -e 'say "ggiggity"'
			return
		fi
		sleep "$interval"
	done
}
nvm_prompt_info () {
	which nvm &> /dev/null || return
	local nvm_prompt=${$(nvm current)#v} 
	echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt:gs/%/%%}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
}
omz () {
	setopt localoptions noksharrays
	[[ $# -gt 0 ]] || {
		_omz::help
		return 1
	}
	local command="$1" 
	shift
	(( ${+functions[_omz::$command]} )) || {
		_omz::help
		return 1
	}
	_omz::$command "$@"
}
omz_diagnostic_dump () {
	emulate -L zsh
	builtin echo "Generating diagnostic dump; please be patient..."
	local thisfcn=omz_diagnostic_dump 
	local -A opts
	local opt_verbose opt_noverbose opt_outfile
	local timestamp=$(date +%Y%m%d-%H%M%S) 
	local outfile=omz_diagdump_$timestamp.txt 
	builtin zparseopts -A opts -D -- "v+=opt_verbose" "V+=opt_noverbose"
	local verbose n_verbose=${#opt_verbose} n_noverbose=${#opt_noverbose} 
	(( verbose = 1 + n_verbose - n_noverbose ))
	if [[ ${#*} > 0 ]]
	then
		opt_outfile=$1 
	fi
	if [[ ${#*} > 1 ]]
	then
		builtin echo "$thisfcn: error: too many arguments" >&2
		return 1
	fi
	if [[ -n "$opt_outfile" ]]
	then
		outfile="$opt_outfile" 
	fi
	_omz_diag_dump_one_big_text &> "$outfile"
	if [[ $? != 0 ]]
	then
		builtin echo "$thisfcn: error while creating diagnostic dump; see $outfile for details"
	fi
	builtin echo
	builtin echo Diagnostic dump file created at: "$outfile"
	builtin echo
	builtin echo To share this with OMZ developers, post it as a gist on GitHub
	builtin echo at "https://gist.github.com" and share the link to the gist.
	builtin echo
	builtin echo "WARNING: This dump file contains all your zsh and omz configuration files,"
	builtin echo "so don't share it publicly if there's sensitive information in them."
	builtin echo
}
omz_history () {
	local clear list stamp REPLY
	zparseopts -E -D c=clear l=list f=stamp E=stamp i=stamp t:=stamp
	if [[ -n "$clear" ]]
	then
		print -nu2 "This action will irreversibly delete your command history. Are you sure? [y/N] "
		builtin read -E
		[[ "$REPLY" = [yY] ]] || return 0
		print -nu2 >| "$HISTFILE"
		fc -p "$HISTFILE"
		print -u2 History file deleted.
	elif [[ $# -eq 0 ]]
	then
		builtin fc "${stamp[@]}" -l 1
	else
		builtin fc "${stamp[@]}" -l "$@"
	fi
}
omz_termsupport_cwd () {
	setopt localoptions unset
	local URL_HOST URL_PATH
	URL_HOST="$(omz_urlencode -P $HOST)"  || return 1
	URL_PATH="$(omz_urlencode -P $PWD)"  || return 1
	[[ -z "$KONSOLE_PROFILE_NAME" && -z "$KONSOLE_DBUS_SESSION" ]] || URL_HOST="" 
	printf "\e]7;file://%s%s\e\\" "${URL_HOST}" "${URL_PATH}"
}
omz_termsupport_precmd () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return 0
	title "$ZSH_THEME_TERM_TAB_TITLE_IDLE" "$ZSH_THEME_TERM_TITLE_IDLE"
}
omz_termsupport_preexec () {
	[[ "${DISABLE_AUTO_TITLE:-}" != true ]] || return
	emulate -L zsh
	setopt extended_glob
	local -a cmdargs
	cmdargs=("${(z)2}") 
	if [[ "${cmdargs[1]}" = fg ]]
	then
		local job_id jobspec="${cmdargs[2]#%}" 
		case "$jobspec" in
			(<->) job_id=${jobspec}  ;;
			("" | % | +) job_id=${(k)jobstates[(r)*:+:*]}  ;;
			(-) job_id=${(k)jobstates[(r)*:-:*]}  ;;
			([?]*) job_id=${(k)jobtexts[(r)*${(Q)jobspec}*]}  ;;
			(*) job_id=${(k)jobtexts[(r)${(Q)jobspec}*]}  ;;
		esac
		if [[ -n "${jobtexts[$job_id]}" ]]
		then
			1="${jobtexts[$job_id]}" 
			2="${jobtexts[$job_id]}" 
		fi
	fi
	local CMD="${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}" 
	local LINE="${2:gs/%/%%}" 
	title "$CMD" "%100>...>${LINE}%<<"
}
omz_urldecode () {
	emulate -L zsh
	local encoded_url=$1 
	local caller_encoding=$langinfo[CODESET] 
	local LC_ALL=C 
	export LC_ALL
	local tmp=${encoded_url:gs/+/ /} 
	tmp=${tmp:gs/\\/\\\\/} 
	tmp=${tmp:gs/%/\\x/} 
	local decoded="$(printf -- "$tmp")" 
	local -a safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]
	then
		decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from UTF-8 to $caller_encoding" >&2
			return 1
		fi
	fi
	echo -E "$decoded"
}
omz_urlencode () {
	emulate -L zsh
	setopt norematchpcre
	local -a opts
	zparseopts -D -E -a opts r m P
	local in_str="$@" 
	local url_str="" 
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]
	then
		spaces_as_plus=1 
	fi
	local str="$in_str" 
	local encoding=$langinfo[CODESET] 
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$encoding]} ]]
	then
		str=$(echo -E "$str" | iconv -f $encoding -t UTF-8) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from $encoding to UTF-8" >&2
			return 1
		fi
	fi
	local i byte ord LC_ALL=C 
	export LC_ALL
	local reserved=';/?:@&=+$,' 
	local mark='_.!~*''()-' 
	local dont_escape="[A-Za-z0-9" 
	if [[ -z $opts[(r)-r] ]]
	then
		dont_escape+=$reserved 
	fi
	if [[ -z $opts[(r)-m] ]]
	then
		dont_escape+=$mark 
	fi
	dont_escape+="]" 
	local url_str="" 
	for ((i = 1; i <= ${#str}; ++i )) do
		byte="$str[i]" 
		if [[ "$byte" =~ "$dont_escape" ]]
		then
			url_str+="$byte" 
		else
			if [[ "$byte" == " " && -n $spaces_as_plus ]]
			then
				url_str+="+" 
			elif [[ "$PREFIX" = *com.termux* ]]
			then
				url_str+="$byte" 
			else
				ord=$(( [##16] #byte )) 
				url_str+="%$ord" 
			fi
		fi
	done
	echo -E "$url_str"
}
open_command () {
	local open_cmd
	case "$OSTYPE" in
		(darwin*) open_cmd='open'  ;;
		(cygwin*) open_cmd='cygstart'  ;;
		(linux*) [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open'  || {
				open_cmd='cmd.exe /c start ""' 
				[[ -e "$1" ]] && {
					1="$(wslpath -w "${1:a}")"  || return 1
				}
				[[ "$1" = (http|https)://* ]] && {
					1="$(echo "$1" | sed -E 's/([&|()<>^])/^\1/g')"  || return 1
				}
			} ;;
		(msys*) open_cmd='start ""'  ;;
		(*) echo "Platform $OSTYPE not supported"
			return 1 ;;
	esac
	if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]
	then
		"$BROWSER" "$@"
		return
	fi
	${=open_cmd} "$@" &> /dev/null
}
parse_git_dirty () {
	local STATUS
	local -a FLAGS
	FLAGS=('--porcelain') 
	if [[ "$(__git_prompt_git config --get oh-my-zsh.hide-dirty)" != "1" ]]
	then
		if [[ "${DISABLE_UNTRACKED_FILES_DIRTY:-}" == "true" ]]
		then
			FLAGS+='--untracked-files=no' 
		fi
		case "${GIT_STATUS_IGNORE_SUBMODULES:-}" in
			(git)  ;;
			(*) FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"  ;;
		esac
		STATUS=$(__git_prompt_git status ${FLAGS} 2> /dev/null | tail -n 1) 
	fi
	if [[ -n $STATUS ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
	else
		echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
	fi
}
pyclean () {
	find "${@:-.}" -type f -name "*.py[co]" -delete
	find "${@:-.}" -type d -name "__pycache__" -delete
	find "${@:-.}" -depth -type d -name ".mypy_cache" -exec rm -r "{}" +
	find "${@:-.}" -depth -type d -name ".pytest_cache" -exec rm -r "{}" +
}
pyenv_prompt_info () {
	return 1
}
pyuserpaths () {
	setopt localoptions extendedglob
	local user_base="${PYTHONUSERBASE:-"${HOME}/.local"}" 
	local python version site_pkgs
	for python in python2 python3
	do
		(( ${+commands[$python]} )) || continue
		version=${(M)${"$($python -V 2>&1)":7}#[^.]##.[^.]##} 
		site_pkgs="${user_base}/lib/python${version}/site-packages" 
		[[ -d "$site_pkgs" && ! "$PYTHONPATH" =~ (^|:)"$site_pkgs"(:|$) ]] || continue
		export PYTHONPATH="${site_pkgs}${PYTHONPATH+":${PYTHONPATH}"}" 
	done
}
rbenv_prompt_info () {
	return 1
}
regexp-replace () {
	argv=("$1" "$2" "$3") 
	4=0 
	[[ -o re_match_pcre ]] && 4=1 
	emulate -L zsh
	local MATCH MBEGIN MEND
	local -a match mbegin mend
	if (( $4 ))
	then
		zmodload zsh/pcre || return 2
		pcre_compile -- "$2" && pcre_study || return 2
		4=0 6= 
		local ZPCRE_OP
		while pcre_match -b -n $4 -- "${(P)1}"
		do
			5=${(e)3} 
			argv+=(${(s: :)ZPCRE_OP} "$5") 
			4=$((argv[-2] + (argv[-3] == argv[-2]))) 
		done
		(($# > 6)) || return
		set +o multibyte
		5= 6=1 
		for 2 3 4 in "$@[7,-1]"
		do
			5+=${(P)1[$6,$2]}$4 
			6=$(($3 + 1)) 
		done
		5+=${(P)1[$6,-1]} 
	else
		4=${(P)1} 
		while [[ -n $4 ]]
		do
			if [[ $4 =~ $2 ]]
			then
				5+=${4[1,MBEGIN-1]}${(e)3} 
				if ((MEND < MBEGIN))
				then
					((MEND++))
					5+=${4[1]} 
				fi
				4=${4[MEND+1,-1]} 
				6=1 
			else
				break
			fi
		done
		[[ -n $6 ]] || return
		5+=$4 
	fi
	eval $1=\$5
}
review () {
	if [[ -n $(git status -s) ]]
	then
		echo 'must start with clean tree!'
		return 1
	fi
	git checkout pristine
	git rebase origin/master
	branch="$1" 
	git branch -D "$branch"
	git checkout "$branch"
	git rebase origin/master
	git reset --soft origin/master
	git reset
	nvim -c ':G'
	git reset --hard
	git status -s | awk '{ print $2 }' | xargs rm
	git checkout pristine
	git branch -D "$branch"
}
ruby_prompt_info () {
	echo "$(rvm_prompt_info || rbenv_prompt_info || chruby_prompt_info)"
}
rvm_prompt_info () {
	[ -f $HOME/.rvm/bin/rvm-prompt ] || return 1
	local rvm_prompt
	rvm_prompt=$($HOME/.rvm/bin/rvm-prompt ${=ZSH_THEME_RVM_PROMPT_OPTIONS} 2>/dev/null) 
	[[ -z "${rvm_prompt}" ]] && return 1
	echo "${ZSH_THEME_RUBY_PROMPT_PREFIX}${rvm_prompt:gs/%/%%}${ZSH_THEME_RUBY_PROMPT_SUFFIX}"
}
spectrum_bls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${BG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
spectrum_ls () {
	setopt localoptions nopromptsubst
	local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris} 
	for code in {000..255}
	do
		print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
	done
}
svn_prompt_info () {
	return 1
}
t () {
	if [[ -z "$1" ]]
	then
		go test -failfast -timeout=60s -cover ./... -json | tparse -progress
		return
	fi
	go test -failfast -timeout=16s -cover . -run "$1" -json | tparse
}
tabname () {
	echo -ne "\033]0;$@\007"
}
take () {
	if [[ $1 =~ ^(https?|ftp).*\.(tar\.(gz|bz2|xz)|tgz)$ ]]
	then
		takeurl "$1"
	elif [[ $1 =~ ^(https?|ftp).*\.(zip)$ ]]
	then
		takezip "$1"
	elif [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]
	then
		takegit "$1"
	else
		takedir "$@"
	fi
}
takedir () {
	mkdir -p $@ && cd ${@:$#}
}
takegit () {
	git clone "$1"
	cd "$(basename ${1%%.git})"
}
takeurl () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	tar xf "$data"
	thedir="$(tar tf "$data" | head -n 1)" 
	rm "$data"
	cd "$thedir"
}
takezip () {
	local data thedir
	data="$(mktemp)" 
	curl -L "$1" > "$data"
	unzip "$data" -d "./"
	thedir="$(unzip -l "$data" | awk 'NR==4 {print $4}' | sed 's/\/.*//')" 
	rm "$data"
	cd "$thedir"
}
tf_prompt_info () {
	return 1
}
title () {
	setopt localoptions nopromptsubst
	[[ -n "${INSIDE_EMACS:-}" && "$INSIDE_EMACS" != vterm ]] && return
	: ${2=$1}
	case "$TERM" in
		(cygwin | xterm* | putty* | rxvt* | konsole* | ansi | mlterm* | alacritty* | st* | foot* | contour* | wezterm*) print -Pn "\e]2;${2:q}\a"
			print -Pn "\e]1;${1:q}\a" ;;
		(screen* | tmux*) print -Pn "\ek${1:q}\e\\" ;;
		(*) if [[ "$TERM_PROGRAM" == "iTerm.app" ]]
			then
				print -Pn "\e]2;${2:q}\a"
				print -Pn "\e]1;${1:q}\a"
			else
				if (( ${+terminfo[fsl]} && ${+terminfo[tsl]} ))
				then
					print -Pn "${terminfo[tsl]}$1${terminfo[fsl]}"
				fi
			fi ;;
	esac
}
try_alias_value () {
	alias_value "$1" || echo "$1"
}
tto () {
	echo "$(date -u): $@" > ~/tto.log
	exec "$@" | tee -a ~/tto.log
}
tv () {
	if [[ -z "$1" ]]
	then
		go test -v -failfast -timeout=60s -cover ./... -json | tparse -follow
		return
	fi
	go test -v -failfast -timeout=10s -cover . -run "$1" -json | tparse -follow
}
tw () {
	while true
	do
		clear
		t $1
		fswatch -1 . > /dev/null
	done
}
uninstall_oh_my_zsh () {
	command env ZSH="$ZSH" sh "$ZSH/tools/uninstall.sh"
}
up-line-or-beginning-search () {
	# undefined
	builtin autoload -XU
}
upgrade_oh_my_zsh () {
	echo "${fg[yellow]}Note: \`$0\` is deprecated. Use \`omz update\` instead.$reset_color" >&2
	omz update
}
vh () {
	index=$1 
	if [[ -z $index ]]
	then
		index=1 
	fi
	last=$(history | rg rg | tail -n1 | sed -E 's/[0-9]*:[0-9]*  //') 
	out=$(eval "$last" | tail -n $index | head -n 1) 
	file=$(echo "$out" | cut -d ':' -f 1) 
	line=$(echo "$out" | cut -d ':' -f 2) 
	nvim "$file" "+${line}"
}
vi_mode_prompt_info () {
	return 1
}
virtualenv_prompt_info () {
	return 1
}
vrun () {
	if [[ -z "$1" ]]
	then
		local name
		for name in $PYTHON_VENV_NAMES
		do
			local venvpath="${name:P}" 
			if [[ -d "$venvpath" ]]
			then
				vrun "$name"
				return $?
			fi
		done
		echo "Error: no virtual environment found in current directory" >&2
	fi
	local name="${1:-$PYTHON_VENV_NAME}" 
	local venvpath="${name:P}" 
	if [[ ! -d "$venvpath" ]]
	then
		echo "Error: no such venv in current directory: $name" >&2
		return 1
	fi
	if [[ ! -f "${venvpath}/bin/activate" ]]
	then
		echo "Error: '${name}' is not a proper virtual environment" >&2
		return 1
	fi
	. "${venvpath}/bin/activate" || return $?
	echo "Activated virtual environment ${name}"
}
whosgot () {
	id=$1 
	matches=$(rg "$id" ~/.speedscale/config.yaml.* --files-with-matches) 
	if [ -z "$matches" ]
	then
		echo 'not found'
	fi
	echo $matches | sed 's/^.*config\.yaml\.prod\.//g'
}
work_in_progress () {
	command git -c log.showSignature=false log -n 1 2> /dev/null | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} -q -- "--wip--" && echo "WIP!!"
}
zle-line-finish () {
	echoti rmkx
}
zle-line-init () {
	echoti smkx
}
zrecompile () {
	setopt localoptions extendedglob noshwordsplit noksharrays
	local opt check quiet zwc files re file pre ret map tmp mesg pats
	tmp=() 
	while getopts ":tqp" opt
	do
		case $opt in
			(t) check=yes  ;;
			(q) quiet=yes  ;;
			(p) pats=yes  ;;
			(*) if [[ -n $pats ]]
				then
					tmp=($tmp $OPTARG) 
				else
					print -u2 zrecompile: bad option: -$OPTARG
					return 1
				fi ;;
		esac
	done
	shift OPTIND-${#tmp}-1
	if [[ -n $check ]]
	then
		ret=1 
	else
		ret=0 
	fi
	if [[ -n $pats ]]
	then
		local end num
		while (( $# ))
		do
			end=$argv[(i)--] 
			if [[ end -le $# ]]
			then
				files=($argv[1,end-1]) 
				shift end
			else
				files=($argv) 
				argv=() 
			fi
			tmp=() 
			map=() 
			OPTIND=1 
			while getopts :MR opt $files
			do
				case $opt in
					([MR]) map=(-$opt)  ;;
					(*) tmp=($tmp $files[OPTIND])  ;;
				esac
			done
			shift OPTIND-1 files
			(( $#files )) || continue
			files=($files[1] ${files[2,-1]:#*(.zwc|~)}) 
			(( $#files )) || continue
			zwc=${files[1]%.zwc}.zwc 
			shift 1 files
			(( $#files )) || files=(${zwc%.zwc}) 
			if [[ -f $zwc ]]
			then
				num=$(zcompile -t $zwc | wc -l) 
				if [[ num-1 -ne $#files ]]
				then
					re=yes 
				else
					re= 
					for file in $files
					do
						if [[ $file -nt $zwc ]]
						then
							re=yes 
							break
						fi
					done
				fi
			else
				re=yes 
			fi
			if [[ -n $re ]]
			then
				if [[ -n $check ]]
				then
					[[ -z $quiet ]] && print $zwc needs re-compilation
					ret=0 
				else
					[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
					if [[ -z "$quiet" ]] && {
							[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
						} && zcompile $map $tmp $zwc $files
					then
						print succeeded
					elif ! {
							{
								[[ ! -f $zwc ]] || mv -f $zwc ${zwc}.old
							} && zcompile $map $tmp $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		done
		return ret
	fi
	if (( $# ))
	then
		argv=(${^argv}/*.zwc(ND) ${^argv}.zwc(ND) ${(M)argv:#*.zwc}) 
	else
		argv=(${^fpath}/*.zwc(ND) ${^fpath}.zwc(ND) ${(M)fpath:#*.zwc}) 
	fi
	argv=(${^argv%.zwc}.zwc) 
	for zwc
	do
		files=(${(f)"$(zcompile -t $zwc)"}) 
		if [[ $files[1] = *\(mapped\)* ]]
		then
			map=-M 
			mesg='succeeded (old saved)' 
		else
			map=-R 
			mesg=succeeded 
		fi
		if [[ $zwc = */* ]]
		then
			pre=${zwc%/*}/ 
		else
			pre= 
		fi
		if [[ $files[1] != *$ZSH_VERSION ]]
		then
			re=yes 
		else
			re= 
		fi
		files=(${pre}${^files[2,-1]:#/*} ${(M)files[2,-1]:#/*}) 
		[[ -z $re ]] && for file in $files
		do
			if [[ $file -nt $zwc ]]
			then
				re=yes 
				break
			fi
		done
		if [[ -n $re ]]
		then
			if [[ -n $check ]]
			then
				[[ -z $quiet ]] && print $zwc needs re-compilation
				ret=0 
			else
				[[ -z $quiet ]] && print -n "re-compiling ${zwc}: "
				tmp=(${^files}(N)) 
				if [[ $#tmp -ne $#files ]]
				then
					[[ -z $quiet ]] && print 'failed (missing files)'
					ret=1 
				else
					if [[ -z "$quiet" ]] && mv -f $zwc ${zwc}.old && zcompile $map $zwc $files
					then
						print $mesg
					elif ! {
							mv -f $zwc ${zwc}.old && zcompile $map $zwc $files 2> /dev/null
						}
					then
						[[ -z $quiet ]] && print "re-compiling ${zwc}: failed"
						ret=1 
					fi
				fi
			fi
		fi
	done
	return ret
}
zsh_stats () {
	fc -l 1 | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' | grep -v "./" | sort -nr | head -n 20 | column -c3 -s " " -t | nl
}
# Shell Options
setopt alwaystoend
setopt autocd
setopt autopushd
setopt completeinword
setopt extendedhistory
setopt noflowcontrol
setopt nohashdirs
setopt histexpiredupsfirst
setopt histignoredups
setopt histignorespace
setopt histverify
setopt ignoreeof
setopt interactivecomments
setopt login
setopt longlistjobs
setopt promptsubst
setopt pushdignoredups
setopt pushdminus
setopt sharehistory
# Aliases
alias -- -='cd -'
alias -- ...=../..
alias -- ....=../../..
alias -- .....=../../../..
alias -- ......=../../../../..
alias -- 1='cd -1'
alias -- 2='cd -2'
alias -- 3='cd -3'
alias -- 4='cd -4'
alias -- 5='cd -5'
alias -- 6='cd -6'
alias -- 7='cd -7'
alias -- 8='cd -8'
alias -- 9='cd -9'
alias -- _='sudo '
alias -- adr=$'aider \\\n  --model gemini/gemini-2.5-pro-preview-05-06 \\\n  --reasoning-effort high \\\n  --no-auto-commits \\\n  --no-auto-accept-architect \\\n  --aiderignore /Users/josh/.config/aider/.aiderignore \\\n  --watch \\\n  --cache-keepalive-pings 1 \\\n  --vim'
alias -- ag='ag --skip-vcs-ignores --follow --ignore node_modules'
alias -- cat=bat
alias -- cdc='cd ~/code'
alias -- cds='cd ~/code/ss/'
alias -- cdsm='cd ~/code/ss/ss/master/'
alias -- cdsp='cd ~/code/ss/pristine/'
alias -- cdt='cd /tmp'
alias -- dbl='docker build'
alias -- dc=docker-compose
alias -- dcin='docker container inspect'
alias -- dcls='docker container ls'
alias -- dclsa='docker container ls -a'
alias -- dib='docker image build'
alias -- dii='docker image inspect'
alias -- dils='docker image ls'
alias -- dipru='docker image prune -a'
alias -- dipu='docker image push'
alias -- dirm='docker image rm'
alias -- dit='docker image tag'
alias -- dlo='docker container logs'
alias -- dnc='docker network create'
alias -- dncn='docker network connect'
alias -- dndcn='docker network disconnect'
alias -- dni='docker network inspect'
alias -- dnls='docker network ls'
alias -- dnrm='docker network rm'
alias -- dpo='docker container port'
alias -- dps='docker ps'
alias -- dpsa='docker ps -a'
alias -- dpu='docker pull'
alias -- dr='docker container run'
alias -- drit='docker container run -it'
alias -- drm='docker container rm'
alias -- drm!='docker container rm -f'
alias -- drs='docker container restart'
alias -- dst='docker container start'
alias -- dsta='docker stop $(docker ps -q)'
alias -- dstp='docker container stop'
alias -- dsts='docker stats'
alias -- dtop='docker top'
alias -- dvi='docker volume inspect'
alias -- dvls='docker volume ls'
alias -- dvprune='docker volume prune'
alias -- dxc='docker container exec'
alias -- dxcit='docker container exec -it'
alias -- e=exit
alias -- egrep='grep -E'
alias -- ff='fzf --preview='\''less {}'\'' --bind shift-up:preview-page-up,shift-down:preview-page-down'
alias -- fgrep='grep -F'
alias -- g=git
alias -- ga='g add'
alias -- gaa='g add --all'
alias -- gai=/Users/josh/.local/bin/goose
alias -- gam='git am'
alias -- gama='git am --abort'
alias -- gamc='git am --continue'
alias -- gams='git am --skip'
alias -- gamscp='git am --show-current-patch'
alias -- gap='git apply'
alias -- gapa='git add --patch'
alias -- gapt='git apply --3way'
alias -- gau='git add --update'
alias -- gav='git add --verbose'
alias -- gb='for k in $(g branch | sed s/^..//); do echo -e $(g log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --)\\t"$k";done | sort'
alias -- gbD='git branch --delete --force'
alias -- gba='git branch --all'
alias -- gbd='git branch --delete'
alias -- gbg='LANG=C git branch -vv | grep ": gone\]"'
alias -- gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -D'
alias -- gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -d'
alias -- gbl='git blame -w'
alias -- gbm='git branch --move'
alias -- gbnm='git branch --no-merged'
alias -- gbr='git branch --remote'
alias -- gbs='git bisect'
alias -- gbsb='git bisect bad'
alias -- gbsg='git bisect good'
alias -- gbsn='git bisect new'
alias -- gbso='git bisect old'
alias -- gbsr='git bisect reset'
alias -- gbss='git bisect start'
alias -- gc='g checkout'
alias -- gc!='git commit --verbose --amend'
alias -- gcB='git checkout -B'
alias -- gca='git commit --verbose --all'
alias -- gca!='git commit --verbose --all --amend'
alias -- gcam='git commit --all --message'
alias -- gcan!='git commit --verbose --all --no-edit --amend'
alias -- gcann!='git commit --verbose --all --date=now --no-edit --amend'
alias -- gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias -- gcas='git commit --all --signoff'
alias -- gcasm='git commit --all --signoff --message'
alias -- gcb='git checkout -b'
alias -- gcd='git checkout $(git_develop_branch)'
alias -- gcf='git config --list'
alias -- gcfu='git commit --fixup'
alias -- gcl='git clone --recurse-submodules'
alias -- gclean='git clean --interactive -d'
alias -- gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'
alias -- gcm='g commit -m'
alias -- gcmsg='git commit --message'
alias -- gcn='git commit --verbose --no-edit'
alias -- gcn!='git commit --verbose --no-edit --amend'
alias -- gco='git checkout'
alias -- gcor='git checkout --recurse-submodules'
alias -- gcount='git shortlog --summary --numbered'
alias -- gcp='git cherry-pick'
alias -- gcpa='git cherry-pick --abort'
alias -- gcpc='git cherry-pick --continue'
alias -- gcs='git commit --gpg-sign'
alias -- gcsm='git commit --signoff --message'
alias -- gcss='git commit --gpg-sign --signoff'
alias -- gcssm='git commit --gpg-sign --signoff --message'
alias -- gd='g diff'
alias -- gdc='g diff --cached'
alias -- gdca='git diff --cached'
alias -- gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias -- gdcw='git diff --cached --word-diff'
alias -- gdm='g diff origin/master..HEAD'
alias -- gds='git diff --staged'
alias -- gdt='git diff-tree --no-commit-id --name-only -r'
alias -- gdup='git diff @{upstream}'
alias -- gdw='git diff --word-diff'
alias -- gf='git fetch'
alias -- gfa='git fetch --all --tags --prune --jobs=10'
alias -- gfg='git ls-files | grep'
alias -- gfo='git fetch origin'
alias -- gg='git gui citool'
alias -- gga='git gui citool --amend'
alias -- ggpull='git pull origin "$(git_current_branch)"'
alias -- ggpur=ggu
alias -- ggpush='git push origin "$(git_current_branch)"'
alias -- ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias -- ghh='git help'
alias -- gignore='git update-index --assume-unchanged'
alias -- gignored='git ls-files -v | grep "^[[:lower:]]"'
alias -- git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
alias -- gk='\gitk --all --branches &!'
alias -- gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
alias -- gl='g log --graph --decorate --decorate-refs=tags --all --single-worktree --topo-order --pretty='\''format:%C(yellow)%h %C(blue)%ad %C(auto)%s%C(red)% D%C(auto)'\'' --merges'
alias -- glab='PAGER=cat glab'
alias -- glg='git log --stat'
alias -- glgg='git log --graph'
alias -- glgga='git log --graph --decorate --all'
alias -- glgm='git log --graph --max-count=10'
alias -- glgp='git log --stat --patch'
alias -- glo='git log --oneline --decorate'
alias -- glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias -- glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias -- glog='git log --oneline --decorate --graph'
alias -- gloga='git log --oneline --decorate --graph --all'
alias -- glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias -- glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias -- glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias -- glp=_git_log_prettily
alias -- gluc='git pull upstream $(git_current_branch)'
alias -- glum='git pull upstream $(git_main_branch)'
alias -- gm='git merge'
alias -- gma='git merge --abort'
alias -- gmc='git merge --continue'
alias -- gmff='git merge --ff-only'
alias -- gmom='git merge origin/$(git_main_branch)'
alias -- gms='git merge --squash'
alias -- gmtl='git mergetool --no-prompt'
alias -- gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias -- gmum='git merge upstream/$(git_main_branch)'
alias -- gob='go build'
alias -- goc='go clean'
alias -- god='go doc'
alias -- goe='go env'
alias -- gof='go fmt'
alias -- gofa='go fmt ./...'
alias -- gofx='go fix'
alias -- gog='go get'
alias -- goga='go get ./...'
alias -- goi='go install'
alias -- gol='go list'
alias -- gom='go mod'
alias -- gomt='go mod tidy'
alias -- gopa='cd $GOPATH'
alias -- gopb='cd $GOPATH/bin'
alias -- gops='cd $GOPATH/src'
alias -- gor='go run'
alias -- got='go test'
alias -- gota='go test ./...'
alias -- goto='go tool'
alias -- gotoc='go tool compile'
alias -- gotod='go tool dist'
alias -- gotofx='go tool fix'
alias -- gov='go vet'
alias -- gove='go version'
alias -- gow='go work'
alias -- gp='g pull --rebase --autostash'
alias -- gpd='git push --dry-run'
alias -- gpf='git push --force-with-lease --force-if-includes'
alias -- gpf!='git push --force'
alias -- gpoat='git push origin --all && git push origin --tags'
alias -- gpod='git push origin --delete'
alias -- gpr='git pull --rebase'
alias -- gpra='git pull --rebase --autostash'
alias -- gprav='git pull --rebase --autostash -v'
alias -- gpristine='git reset --hard && git clean --force -dfx'
alias -- gprom='git pull --rebase origin $(git_main_branch)'
alias -- gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias -- gprum='git pull --rebase upstream $(git_main_branch)'
alias -- gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias -- gprv='git pull --rebase -v'
alias -- gpsh='g push'
alias -- gpsup='git push --set-upstream origin $(git_current_branch)'
alias -- gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes'
alias -- gpu=git_push_initial
alias -- gpv='git push --verbose'
alias -- gr='git remote'
alias -- gra='git remote add'
alias -- grb='git rebase'
alias -- grba='git rebase --abort'
alias -- grbc='git rebase --continue'
alias -- grbd='git rebase $(git_develop_branch)'
alias -- grbi='git rebase --interactive'
alias -- grbm='git rebase $(git_main_branch)'
alias -- grbo='git rebase --onto'
alias -- grbom='git rebase origin/$(git_main_branch)'
alias -- grbs='git rebase --skip'
alias -- grbum='git rebase upstream/$(git_main_branch)'
alias -- grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias -- grev='git revert'
alias -- greva='git revert --abort'
alias -- grevc='git revert --continue'
alias -- grf='git reflog'
alias -- grh='git reset'
alias -- grhh='git reset --hard'
alias -- grhk='git reset --keep'
alias -- grhs='git reset --soft'
alias -- grm='git rm'
alias -- grmc='git rm --cached'
alias -- grmv='git remote rename'
alias -- groh='git reset origin/$(git_current_branch) --hard'
alias -- grrm='git remote remove'
alias -- grs='git restore'
alias -- grset='git remote set-url'
alias -- grss='git restore --source'
alias -- grst='git restore --staged'
alias -- grt='cd "$(git rev-parse --show-toplevel || echo .)"'
alias -- gru='git reset --'
alias -- grup='git remote update'
alias -- grv='git remote --verbose'
alias -- gs='g status -s && g status | rg "g push"'
alias -- gsb='git status --short --branch'
alias -- gsd='git svn dcommit'
alias -- gsh='g stash'
alias -- gsi='git submodule init'
alias -- gsps='git show --pretty=short --show-signature'
alias -- gsr='git svn rebase'
alias -- gss='git status --short'
alias -- gst='git status'
alias -- gsta='git stash push'
alias -- gstaa='git stash apply'
alias -- gstall='git stash --all'
alias -- gstc='git stash clear'
alias -- gstd='git stash drop'
alias -- gstl='git stash list'
alias -- gstp='git stash pop'
alias -- gsts='git stash show --patch'
alias -- gstu='gsta --include-untracked'
alias -- gsu='git submodule update'
alias -- gsw='git switch'
alias -- gswc='git switch --create'
alias -- gswd='git switch $(git_develop_branch)'
alias -- gswm='git switch $(git_main_branch)'
alias -- gta='git tag --annotate'
alias -- gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'
alias -- gts='g pull'
alias -- gtv='git tag | sort -V'
alias -- gunignore='git update-index --no-assume-unchanged'
alias -- gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias -- gup=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gup%F{yellow}\' is a deprecated alias, using \'%F{green}gpr%F{yellow}\' instead.%f"\n    gpr'
alias -- gupa=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupa%F{yellow}\' is a deprecated alias, using \'%F{green}gpra%F{yellow}\' instead.%f"\n    gpra'
alias -- gupav=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupav%F{yellow}\' is a deprecated alias, using \'%F{green}gprav%F{yellow}\' instead.%f"\n    gprav'
alias -- gupom=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupom%F{yellow}\' is a deprecated alias, using \'%F{green}gprom%F{yellow}\' instead.%f"\n    gprom'
alias -- gupomi=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupomi%F{yellow}\' is a deprecated alias, using \'%F{green}gpromi%F{yellow}\' instead.%f"\n    gpromi'
alias -- gupv=$'\n    print -Pu2 "%F{yellow}[oh-my-zsh] \'%F{red}gupv%F{yellow}\' is a deprecated alias, using \'%F{green}gprv%F{yellow}\' instead.%f"\n    gprv'
alias -- gw='g worktree'
alias -- gwch='git whatchanged -p --abbrev-commit --pretty=medium'
alias -- gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias -- gwipe='git reset --hard && git clean --force -df'
alias -- gwt='git worktree'
alias -- gwta='git worktree add'
alias -- gwtls='git worktree list'
alias -- gwtmv='git worktree move'
alias -- gwtrm='git worktree remove'
alias -- h=history
alias -- history=omz_history
alias -- k=kubectl
alias -- k9d='k9s --context dev -n sstenant-external -c pods'
alias -- k9m='k9s --context minikube -c ns'
alias -- ka='k apply'
alias -- kaf='kubectl apply -f'
alias -- kc='k create'
alias -- kca='_kca(){ kubectl "$@" --all-namespaces;  unset -f _kca; }; _kca'
alias -- kccc='kubectl config current-context'
alias -- kcdc='kubectl config delete-context'
alias -- kcgc='kubectl config get-contexts'
alias -- kcn='kubectl config set-context --current --namespace'
alias -- kcp='kubectl cp'
alias -- kcsc='kubectl config set-context'
alias -- kcuc='kubectl config use-context'
alias -- kd='k delete'
alias -- kdcj='kubectl describe cronjob'
alias -- kdcm='kubectl describe configmap'
alias -- kdd='kubectl describe deployment'
alias -- kdds='kubectl describe daemonset'
alias -- kdel='kubectl delete'
alias -- kdelcj='kubectl delete cronjob'
alias -- kdelcm='kubectl delete configmap'
alias -- kdeld='kubectl delete deployment'
alias -- kdelds='kubectl delete daemonset'
alias -- kdelf='kubectl delete -f'
alias -- kdeli='kubectl delete ingress'
alias -- kdelj='kubectl delete job'
alias -- kdelno='kubectl delete node'
alias -- kdelns='kubectl delete namespace'
alias -- kdelp='kubectl delete pods'
alias -- kdelpvc='kubectl delete pvc'
alias -- kdels='kubectl delete svc'
alias -- kdelsa='kubectl delete sa'
alias -- kdelsec='kubectl delete secret'
alias -- kdelss='kubectl delete statefulset'
alias -- kdi='kubectl describe ingress'
alias -- kdj='kubectl describe job'
alias -- kdno='kubectl describe node'
alias -- kdns='kubectl describe namespace'
alias -- kdp='k delete pod'
alias -- kdpvc='kubectl describe pvc'
alias -- kdrs='kubectl describe replicaset'
alias -- kds='kubectl describe svc'
alias -- kdsa='kubectl describe sa'
alias -- kdsec='kubectl describe secret'
alias -- kdss='kubectl describe statefulset'
alias -- ke='k edit'
alias -- kecj='kubectl edit cronjob'
alias -- kecm='kubectl edit configmap'
alias -- ked='kubectl edit deployment'
alias -- keds='kubectl edit daemonset'
alias -- kei='kubectl edit ingress'
alias -- kej='kubectl edit job'
alias -- keno='kubectl edit node'
alias -- kens='kubectl edit namespace'
alias -- kep='kubectl edit pods'
alias -- kepvc='kubectl edit pvc'
alias -- kers='kubectl edit replicaset'
alias -- kes='kubectl edit svc'
alias -- kess='kubectl edit statefulset'
alias -- keti='kubectl exec -t -i'
alias -- kg='k get'
alias -- kga='k get all'
alias -- kgaa='kubectl get all --all-namespaces'
alias -- kgcj='kubectl get cronjob'
alias -- kgcm='kubectl get configmaps'
alias -- kgcma='kubectl get configmaps --all-namespaces'
alias -- kgd='k get deploy'
alias -- kgda='kubectl get deployment --all-namespaces'
alias -- kgds='kubectl get daemonset'
alias -- kgdsa='kubectl get daemonset --all-namespaces'
alias -- kgdsw='kgds --watch'
alias -- kgdw='kgd --watch'
alias -- kgdwide='kgd -o wide'
alias -- kge='kubectl get events --sort-by=".lastTimestamp"'
alias -- kgew='kubectl get events --sort-by=".lastTimestamp" --watch'
alias -- kgi='kubectl get ingress'
alias -- kgia='kubectl get ingress --all-namespaces'
alias -- kgj='kubectl get job'
alias -- kgno='kubectl get nodes'
alias -- kgnosl='kubectl get nodes --show-labels'
alias -- kgns='kg ns'
alias -- kgp='k get pod'
alias -- kgpa='kubectl get pods --all-namespaces'
alias -- kgpall='kubectl get pods --all-namespaces -o wide'
alias -- kgpl='kgp -l'
alias -- kgpn='kgp -n'
alias -- kgpsl='kubectl get pods --show-labels'
alias -- kgpvc='kubectl get pvc'
alias -- kgpvca='kubectl get pvc --all-namespaces'
alias -- kgpvcw='kgpvc --watch'
alias -- kgpw='kgp --watch'
alias -- kgpwide='kgp -o wide'
alias -- kgrs='kubectl get replicaset'
alias -- kgs='k get svc'
alias -- kgsa='kubectl get svc --all-namespaces'
alias -- kgsec='kubectl get secret'
alias -- kgseca='kubectl get secret --all-namespaces'
alias -- kgss='kubectl get statefulset'
alias -- kgssa='kubectl get statefulset --all-namespaces'
alias -- kgssw='kgss --watch'
alias -- kgsswide='kgss -o wide'
alias -- kgsw='kgs --watch'
alias -- kgswide='kgs -o wide'
alias -- kl='k logs'
alias -- kl1h='kubectl logs --since 1h'
alias -- kl1m='kubectl logs --since 1m'
alias -- kl1s='kubectl logs --since 1s'
alias -- klf='kubectl logs -f'
alias -- klf1h='kubectl logs --since 1h -f'
alias -- klf1m='kubectl logs --since 1m -f'
alias -- klf1s='kubectl logs --since 1s -f'
alias -- kpf='kubectl port-forward'
alias -- krh='kubectl rollout history'
alias -- krsd='kubectl rollout status deployment'
alias -- krsss='kubectl rollout status statefulset'
alias -- kru='kubectl rollout undo'
alias -- ksd='kubectl scale deployment'
alias -- ksss='kubectl scale statefulset'
alias -- kx=kubectx
alias -- l='ls -lah'
alias -- la='ls -lAh'
alias -- less=bat
alias -- ll='ls -lh'
alias -- ls='ls -G'
alias -- lsa='ls -lah'
alias -- md='mkdir -p'
alias -- mk=minikube
alias -- pm=proxymock
alias -- py=python3
alias -- pyfind='find . -name "*.py"'
alias -- pygrep='grep -nr --include="*.py"'
alias -- pyserver='python3 -m http.server'
alias -- rd=rmdir
alias -- rg='rg --smart-case --no-heading --line-number'
alias -- rgg='rg --type go'
alias -- rgn='rg --no-line-number'
alias -- rigwake='wakeonlan A8:A1:59:2D:26:60'
alias -- run-help=man
alias -- s=speedctl
alias -- sm=speedmgmt
alias -- sns='kubectl config set-context $(kubectl config current-context) --namespace '
alias -- tf=terraform
alias -- theqr='open ~/doc/theqr.png'
alias -- uniq='sort -u'
alias -- v=nvim
alias -- vf='v $($(which fzf))'
alias -- vg='v -c :G'
alias -- vimdiff='v diff'
alias -- vt='v -c terminal'
alias -- watch=viddy
alias -- which-command=whence
alias -- wk='watch kubectl'
alias -- wkg='watch kubectl get'
alias -- wkgd='watch kubectl get deploy'
alias -- wkgns='watch kubectl get ns'
alias -- wkgp='watch kubectl get pods'
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/opt/homebrew/Cellar/ripgrep/14.1.1/bin/rg'
fi
export PATH=/opt/google-cloud-sdk/bin\:/opt/homebrew/bin\:/opt/homebrew/sbin\:/Users/josh/.krew/bin\:/Users/josh/.local/share/solana/install/active_release/bin\:/Users/josh/.speedscale\:/Users/josh/.cargo/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/Applications/Ghostty.app/Contents/MacOS\:/Users/josh/.local/bin\:/usr/local/go/bin\:/Users/josh/go/bin\:/opt/homebrew/opt/openjdk/bin\:/opt/local
