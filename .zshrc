# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
###########
### env ###
###########

export EDITOR='nvim'

export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/Users/josh/go/bin"
export PATH="$PATH:/opt/homebrew/opt/openjdk/bin"
export PATH="$PATH:/opt/local"
export PATH="$PATH:/Users/josh/.local/bin"

# which characters are considered part of a word
export WORDCHARS=''


# speedscale
export SPEEDSCALE_HOME=/Users/josh/.speedscale
export PATH=$PATH:$SPEEDSCALE_HOME

# speedscale dir shorthands
sc=~/.speedscale/config.yaml
sd=~/.speedscale/data
ss=~/.speedscale/data/snapshots
sr=~/.speedscale/data/reports

# solana
export PATH="/Users/josh/.local/share/solana/install/active_release/bin:$PATH"

# kubernetes plugins
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# zsh
DISABLE_MAGIC_FUNCTIONS="true"
# don't kill shell on ctrl-d
setopt ignoreeof
# https://www.johnhawthorn.com/2012/09/vi-escape-delays/
KEYTIMEOUT=0

# node version manager nonsense
export NVM_DIR="$HOME/.nvm"
# do we need this?  It's slow
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# make gke use new auth method
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

export AWS_REGION=us-east-1

export GOOSE_PROVIDER=claude-code

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(direnv hook zsh)"

###############
### plugins ###
###############

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
plugins=(
  aws
  docker
  git
  golang
  istioctl
  kubectl
  node
  nvm
  python
  rust
)
SHOW_AWS_PROMPT=false

############
### init ###
############

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_TITLE="true"
source $ZSH/oh-my-zsh.sh



################
### includes ###
################

source ~/.secrets

####################
### key bindings ###
####################

bindkey "^h" backward-word
bindkey "^l" forward-word

###############
### aliases ###
###############

## speedscale
alias s='speedctl'
alias sm='speedmgmt'
alias pm='proxymock'

## nvim
# alias v='rm /Users/josh/vim.log; nvim -V9/Users/josh/vim.log' # for debugging
alias v='nvim'
if [ "$(env | grep VIM)" ]; then
  alias v='nvr'
fi
alias vt='v -c terminal'
alias vg='v -c :G'
alias vimdiff='v diff'
alias vf='v $($(which fzf))'

## junk drawer
alias h='history'
alias cat='bat'
alias less='bat'
# I shouldn't have to do this
alias uniq='sort -u'
alias mk='minikube'
alias cdt='cd /tmp'
alias cdc='cd ~/code'
alias cds='cd ~/code/ss/'
alias cdsp='cd ~/code/ss/pristine/'
alias cdsm='cd ~/code/ss/ss/master/'
alias rigwake='wakeonlan A8:A1:59:2D:26:60'
# alias kdbg='kill $(lsof -i -P | grep -i listen | grep __debug_ | tr -s " " | cut -d " " -f 2)' # for vscode
alias tf='terraform'
alias e='exit'
alias ff="fzf --preview='less {}' --bind shift-up:preview-page-up,shift-down:preview-page-down"
alias dc='docker-compose'
alias theqr='open ~/doc/theqr.png'
alias ag='ag --skip-vcs-ignores --follow --ignore node_modules'
alias glab='PAGER=cat glab'
alias rg='rg --smart-case --no-heading --line-number'
alias rgg='rg --type go'
alias rgn='rg --no-line-number'
# goose AI conflicts with other tools named goose
alias gai='/Users/josh/.local/bin/goose'
alias adr='aider \
  --model gemini/gemini-2.5-pro-preview-05-06 \
  --reasoning-effort high \
  --no-auto-commits \
  --no-auto-accept-architect \
  --aiderignore /Users/josh/.config/aider/.aiderignore \
  --watch \
  --cache-keepalive-pings 1 \
  --vim'

## git
alias g='git'
alias ga='g add'
alias gaa='g add --all'
alias gp='g pull --rebase --autostash'
function gpw() { g --work-tree "$1" pull }
alias gpsh='g push'
alias gs='g status -s && g status | rg "g push"'
alias gc='g checkout'
alias gsh='g stash'
alias gpu=git_push_initial
alias gd='g diff'
alias gdm='g diff origin/master..HEAD'
alias gdc='g diff --cached'
# alias gl="g log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -- "
alias gl="g log --graph --decorate --decorate-refs=tags --all --single-worktree --topo-order --pretty='format:%C(yellow)%h %C(blue)%ad %C(auto)%s%C(red)% D%C(auto)' --merges"
alias gb='for k in $(g branch | sed s/^..//); do echo -e $(g log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --)\\t"$k";done | sort'
alias gw='g worktree'
alias gts='g pull'
alias gw='g worktree'
alias gcm='g commit -m'

## kubernetes
alias k='kubectl'
alias wk='watch kubectl'
alias kx='kubectx'
alias sns='kubectl config set-context $(kubectl config current-context) --namespace '
alias kc='k create'
alias kg='k get'
alias wkg='watch kubectl get'
alias kga='k get all'
alias ke='k edit'
alias kgp='k get pod'
alias wkgp='watch kubectl get pods'
alias kgd='k get deploy'
alias wkgd='watch kubectl get deploy'
alias kgs='k get svc'
alias kgns='kg ns'
alias wkgns='watch kubectl get ns'
alias ka='k apply'
alias kd='k delete'
alias kdp='k delete pod'
alias kl='k logs'
alias k9d='k9s --context dev -n sstenant-external -c pods'
alias k9m='k9s --context minikube -c ns'

##################
### completion ###
##################

# source speedctl and add the s alias
# FIXME: re-enable these when we speed up speedctl
# source <(s completion zsh | sed 's/^compdef _speedctl speedctl/compdef _speedctl speedctl s/')
# source <(sm completion zsh | sed 's/^compdef _speedmgmt speedmgmt/compdef _speedmgmt speedmgmt sm/')

source <(kubectl completion zsh)
source <(kubebuilder completion zsh)

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

####################
### custom funcs ###
####################

# run k9s in a specific context
k9c() {
  local args=("$@")

  # extract and remove context
  context="${args[1]}"
  args=("${args[@]:1}")

  # find out if we passed a namespace
  local includes_namespace=0
  for arg in "${args[@]}"; do
    if [ "$arg" = "-n" ]; then
      includes_namespace=1
      break
    fi
  done

  # if no namespace we should start with the namespaces list
  if [ $includes_namespace -eq 0 ]; then
    args+=("-c" "ns")
  else
    args+=("-c" "pods")
  fi

  k9s --context "$context" "${args[@]}"
}

# run base64 easier
function b64d() {
  echo "$1" | base64 -d
}

# vim here
function vh() {
  index=$1
  if [[ -z $index ]]; then
    index=1
  fi

  # last=$(history | rg rg | tail -n1 | sed 's/[0-9]*: [0-9]*  //') # for earlier numbers - we need a better sed expression
  last=$(history | rg rg | tail -n1 | sed -E 's/[0-9]*:[0-9]*  //')
  out=$(eval "$last" | tail -n $index | head -n 1)
  file=$(echo "$out" | cut -d ':' -f 1)
  line=$(echo "$out" | cut -d ':' -f 2)
  v "$file" "+${line}"
}

function git_push_initial() {
  output=$(g push --set-upstream origin $(g rev-parse --abbrev-ref HEAD))
  # FIXME: this doesn't work
  # echo "output:"
	# echo "$output"

  # # find the URL so we can open it
  # url=$(/bin/cat "$output" | rg 'remote:\s+https' | rg -o 'https')
  # echo "url:"
  # echo "$url"
  # open "$url"
}

# review a branch
function review() {
  if [[ -n $(git status -s) ]];then
    echo 'must start with clean tree!'
    return 1
  fi
  git checkout pristine
  git rebase origin/master

  branch="$1"
  git branch -D "$branch"

  git checkout "$branch"
  git rebase origin/master
  # if ! git rebase origin/master --strategy ours;then
  #  echo '###################'
  #  echo '## REBASE FAILED ##'
  #  echo '###################'
  #  echo
  #  echo 'Press any key to continue...'
  #  read
  # fi
  git reset --soft origin/master
  git reset

  # review tool
  nvim -c ':G' # fugutive
  # nvim -c :DiffviewOpen # diffview

  # reset everything
  git reset --hard
  git status -s | awk '{ print $2 }' | xargs rm
  git checkout pristine
  git branch -D "$branch"
}

function awslogin() {
  echo "--> unsetting AWS env vars"
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  echo '--> login'
  aws sso login --profile dev
  # echo '--> update kubeconfig - dev'
  # aws eks update-kubeconfig --name dev-sstenant-eks-cluster --region us-east-1 --profile dev
  # echo '--> update kubeconfig - staging'
  # aws eks update-kubeconfig --name staging-sstenant-eks-cluster --region us-east-1 --profile staging
  # echo '--> update kubeconfig - prod'
  # aws eks update-kubeconfig --name prod-sstenant-eks-cluster --region us-east-1 --profile prod
  # echo '--> update kubeconfig - kraken'
  # gcloud container clusters get-credentials kraken --project=speedscale-demos --region=us-central1
  # echo '--> update kubeconfig - dev-decoy'
  # gcloud container clusters get-credentials dev-decoy --project=speedscale-demos --region=us-central1
  # echo '--> update kubeconfig - staging-decoy'
  # gcloud container clusters get-credentials staging-decoy --project=speedscale-demos --region=us-central1
  # echo '--> update kubeconfig - prod-decoy'
  # gcloud container clusters get-credentials prod-decoy --project=speedscale-demos --region=us-central1
  # echo '--> setting kube context to minikube'
  # kubectx minikube
}

# git worktree add
function gwa() {
  dir=$1
  git worktree add "$dir"
  direnv allow "$dir" &> /dev/null
  cd "$dir"
}
# git worktree remove
function gwr() {
  if [[ -z "$1" ]]; then
    d=$(dirname "$(pwd)")
    git worktree remove . && cd "$d"
    return
  fi
  git worktree remove "$@"
}

############
### misc ###
############

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/opt/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/google-cloud-sdk/path.zsh.inc'; fi

# create a new MR
function mr() {
    args=($@)

    case "${args[1]}" in

        new)
            glab mr new --title "$(git log -1 --pretty=%s)" --description "$(cat ~/.config/merge_template.txt)" --web --push ${args[@]:1}
            ;;

        *)
            glab mr $@
            ;;
    esac
}

function agg() {
  ag --go $@
}

# notify when cmd finishes, retry every interval seconds.
# usage: notifywhen '<cmd>' <interval>
function notifywhen() {
  cmd=$1
  interval=$2

  if [[ "$interval" -eq 0 ]]; then
    echo 'notifywhen: interval must be > 0'
    return
  fi

  start_time=$(date -u +%s)
  while true; do
    eval "$cmd" &> /dev/null
    if [ $? -eq 0 ];then
      end_time=$(date -u +%s)
      duration="$(($end_time - $start_time))"
      osascript -e "display notification \"completed after $duration seconds\" with title \"$1\""
      osascript -e 'say "ggiggity"'
      return
    fi
    sleep "$interval"
  done
}

function whosgot() {
  id=$1
  matches=$(rg "$id" ~/.speedscale/config.yaml.* --files-with-matches)
  if [ -z "$matches" ]; then
    echo 'not found'
  fi
  echo $matches | sed 's/^.*config\.yaml\.prod\.//g'
}

# Run the command and pipe the output through tee to ~/tto.log.  The file is
# overwritten every time.
function tto() {
  echo "$(date -u): $@" > ~/tto.log
  exec "$@" | tee -a ~/tto.log
}

# make it easier to spot the testing debug lines I drop
function fixme() {
  rg "FIXME: \(JMT\)"
  rg "BOOKMARK:"
}

# test with output in tparse
function t() {
  if [[ -z "$1" ]]; then
    go test -failfast -timeout=60s -cover ./... -json | tparse -progress
    return
  fi
  go test -failfast -timeout=16s -cover . -run "$1" -json | tparse
}

# test with verbose output during test
function tv() {
  if [[ -z "$1" ]]; then
    # go test -v -failfast -timeout=60s -cover ./...
    go test -v -failfast -timeout=60s -cover ./... -json | tparse -follow
    return
  fi
  # go test -v -failfast -timeout=10s . -run "$1"
  go test -v -failfast -timeout=10s -cover . -run "$1" -json | tparse -follow
}

# run go tests easier.. with file watches
function tw() {
  while true; do
    clear
    t $1
    fswatch -1 . > /dev/null
  done
}

function analyze_report() {
  rpt_id=$1
  speedmgmt queue send raw \
    --queue-url https://sqs.us-east-1.amazonaws.com/094668123143/dev-sstenant-external-api-gateway \
    --message '{"msgType":"event","version":"0.0.1","name":"sigReport","type":"STRING","stringVal":{"val":"trafficReplayStarted"},"tags":{"source":"jmt-test","tenantId":"63b7c67e-233d-4e9e-a9aa-62db482be7ac","testReportId":"'$rpt_id'"}}'
}

# tab name management
# see ~/.config/ghostty/config for the other half of this setup
{
  # remove ALL title-related hooks (run after first prompt)
  function cleanup_title_hooks() {
      add-zsh-hook -D precmd _ghostty_precmd 2>/dev/null
      add-zsh-hook -D preexec _ghostty_preexec 2>/dev/null
      add-zsh-hook -D precmd omz_termsupport_precmd 2>/dev/null
      add-zsh-hook -D preexec omz_termsupport_preexec 2>/dev/null
      add-zsh-hook -D precmd cleanup_title_hooks  # Remove ourselves
  }
  add-zsh-hook precmd cleanup_title_hooks

  # Tabname function that persists through commands
  tabname() {
      echo -ne "\033]0;$@\007"
      export CUSTOM_TAB_TITLE="$@"

      # Preserve title function
      function preserve_title() {
          if [[ -n "$CUSTOM_TAB_TITLE" ]]; then
              echo -ne "\033]0;$CUSTOM_TAB_TITLE\007"
          fi
      }

      # Add to BOTH precmd and preexec to survive commands
      add-zsh-hook precmd preserve_title
      add-zsh-hook preexec preserve_title
  }

  # Clear custom title
  cleartab() {
      unset CUSTOM_TAB_TITLE
      add-zsh-hook -D precmd preserve_title 2>/dev/null
      add-zsh-hook -D preexec preserve_title 2>/dev/null
  }
}

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/josh/.lmstudio/bin"
# End of LM Studio CLI section

##########################
### EXPERIMENTAL BELOW ###
##########################

