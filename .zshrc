############
### init ###
############

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"
source $ZSH/oh-my-zsh.sh

# zsh-autocomplete
# source /Users/josh/code/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# zstyle ':autocomplete:*' min-delay 0.25
# zstyle ':autocomplete:*' no

source ~/.zshrc-lite
source ~/.zshrc-db

eval "$(/opt/homebrew/bin/brew shellenv)"

###############
### plugins ###
###############

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
plugins=(aws, git)

###########
### env ###
###########

export EDITOR='nvim'

export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/Users/josh/go/bin"

# which characters are considered part of a word
export WORDCHARS='-_'

# speedscale
export SPEEDSCALE_HOME=/Users/josh/.speedscale
export PATH=$SPEEDSCALE_HOME:$PATH
# data directories shorthand
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

####################
### key bindings ###
####################

bindkey "^h" backward-word
bindkey "^l" forward-word

###############
### aliases ###
###############

# alias v='rm /Users/josh/vim.log; nvim -V9/Users/josh/vim.log' # for debugging
alias v='nvim'
if [ "$(env | grep VIM)" ]; then
  alias v='nvr'
fi
alias vt='v -c terminal'
alias vg='v -c :G'
alias vimdiff='v diff'
alias vf='v $($(which fzf))'

alias h='history'
alias c='clear'
alias cat='bat'
alias less='bat'
# I shouldn't have to do this
alias uniq='sort -u'
alias mk='minikube'
alias cdt='cd /tmp'
alias cdc='cd ~/code'
alias cds='cd ~/code/ss/'
alias cdsp='cd ~/code/speedscale-pristine/'
alias cdsm='cd ~/code/ss/ss/master/'
alias rigwake='wakeonlan A8:A1:59:2D:26:60'
# alias kdbg='kill $(lsof -i -P | grep -i listen | grep __debug_ | tr -s " " | cut -d " " -f 2)' # for vscode
alias tf='terraform'
alias sk='skaffold'
alias gcurl='grpcurl'
alias e='exit'
alias ff="fzf --preview='less {}' --bind shift-up:preview-page-up,shift-down:preview-page-down"
alias dc='docker-compose'
alias theqr='open ~/doc/theqr.png'
alias ag='ag --skip-vcs-ignores --follow --ignore node_modules'
alias glab='PAGER=cat glab'
alias rg='rg --smart-case --no-heading --line-number'
alias rgg='rg --type go'
alias rgn='rg --no-line-number'

export REVIEW_BASE='master'
alias g='git'
alias ga='g add'
alias gaa='g add --all'
alias gp='g pull'
function gpw() { g --work-tree "$1" pull }
alias gpsh='g push'
alias gs='g status -s && g status | rg "g push"'
alias gc='g checkout'
alias gsh='g stash'
alias gpu='g push --set-upstream origin $(g rev-parse --abbrev-ref HEAD)'
alias gd='g diff'
alias gdm='g diff origin/master..HEAD'
alias gdc='g diff --cached'
# alias gl="g log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -- "
alias gl="g log --graph --decorate --decorate-refs=tags --all --single-worktree --topo-order --pretty='format:%C(yellow)%h %C(blue)%ad %C(green)%an %C(auto)%s%C(red)% D%C(auto)' --merges"
alias gb='for k in $(g branch | sed s/^..//); do echo -e $(g log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --)\\t"$k";done | sort'
alias gw='g worktree'
alias gts='g pull'
alias gw='g worktree'
alias gcm='g commit -m'

# kubernetes
alias watch='viddy'
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
alias k9c='k9s -c ns --context'
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

# review a branch
function review() {
  if [[ -n $(git status -s) ]];then
    echo 'must start with clean tree!'
    return 1
  fi
  git checkout master
  git pull

  branch="$1"
  git branch -D "$branch"

  git checkout "$branch"
  git pull
  git merge origin/master -m 'whatevs' || (echo 'merge failed!'; return)
  git reset --soft origin/master
  git reset

  # review tool
  nvim -c :G # fugutive
  # nvim -c :DiffviewOpen # diffview

  # reset everything
  git reset --hard
  git status -s | awk '{ print $2 }' | xargs rm
  git checkout master
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
  direnv allow "$dir"
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

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
