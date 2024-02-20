# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

### personal ###

# zsh-autocomplete
# source /Users/josh/code/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# zstyle ':autocomplete:*' min-delay 0.25
# zstyle ':autocomplete:*' no

source ~/.zshrc-lite
source ~/.zshrc-db

###########
### env ###
###########

export EDITOR='nvim'

export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:/Users/josh/go/bin"

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

# alias v='rm vim.log; nvim -V9vim.log' # for debugging
alias v='nvim'
if [ "$(env | grep VIM)" ]; then
  alias v='nvr'
fi
alias vt='v -c terminal'
alias vg='v -c :G'
alias vimdiff='v diff'
alias fzf='v $(/usr/local/bin/fzf)'
alias vf='fzf'

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

export REVIEW_BASE='master'
alias ga='git add'
alias gaa='git add --all'
alias gp='git pull'
function gpw() { git --work-tree "$1" pull }
alias gpsh='git push'
alias gs='git status -s && git status | ag --no-color "git push"'
alias gc='git checkout'
alias gsh='git stash'
alias gpu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gd='git diff'
alias gdm='git diff origin/master..HEAD'
alias gdc='git diff --cached'
# alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -- "
alias gl="git log --graph --decorate --decorate-refs=tags --all --single-worktree --topo-order --pretty='format:%C(yellow)%h %C(blue)%ad %C(green)%an %C(auto)%s%C(red)% D%C(auto)' --merges"
alias gb='for k in $(git branch | sed s/^..//); do echo -e $(git log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --)\\t"$k";done | sort'
alias gw='git worktree'
alias gts='git pull && gt sync --force'
alias gw='git worktree'
function gcm() {
  if gt info > /dev/null;then
    gt modify --commit -m "$@"
  else
    git commit -m "$@"
  fi
}

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
alias k9c='k9s --context'
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
source <(mirrord completions zsh)

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/google-cloud-sdk/completion.zsh.inc' ]; then . '/usr/local/google-cloud-sdk/completion.zsh.inc'; fi

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
    echo "must start with clean tree!"
    return 1
  fi
  git checkout master
  git pull

  branch="$1"
  git branch -D "$branch"

  git checkout "$branch"
  git pull
  git merge origin/master -m 'whatevs'
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
  echo '--> update kubeconfig - dev'
  aws eks update-kubeconfig --name dev-sstenant-eks-cluster --region us-east-1 --profile dev
  echo '--> update kubeconfig - staging'
  aws eks update-kubeconfig --name staging-sstenant-eks-cluster --region us-east-1 --profile staging
  echo '--> update kubeconfig - prod'
  aws eks update-kubeconfig --name prod-sstenant-eks-cluster --region us-east-1 --profile prod
  echo '--> update kubeconfig - kraken'
  gcloud container clusters get-credentials kraken --project=speedscale-demos --region=us-central1
  echo '--> update kubeconfig - dev-decoy'
  gcloud container clusters get-credentials dev-decoy --project=speedscale-demos --region=us-central1
  echo '--> update kubeconfig - staging-decoy'
  gcloud container clusters get-credentials staging-decoy --project=speedscale-demos --region=us-central1
  echo '--> update kubeconfig - prod-decoy'
  gcloud container clusters get-credentials prod-decoy --project=speedscale-demos --region=us-central1
  echo '--> setting kube context to minikube'
  kubectx minikube
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
    git worktree remove . && cds
    return
  fi
  git worktree remove "$@"
}

############
### misc ###
############

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/google-cloud-sdk/path.zsh.inc' ]; then . '/usr/local/google-cloud-sdk/path.zsh.inc'; fi

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

# notify when cmd finishes, retry every n seconds.
# usage: notifywhen '<cmd>' <n>
function notifywhen() {
  cmd=$1
  every=$2

  start_time=$(date -u +%s)
  while true; do
    eval "$cmd" &> /dev/null
    if [ $? -eq 0 ];then
      end_time=$(date -u +%s)
      duration="$(($end_time - $start_time))"
      osascript -e "display notification \"completed after $duration seconds\" with title \"$1\""
      return
    fi

    if [[ "$every" -eq 0 ]]; then
      osascript -e "display notification \"failed after 1 attempt\" with title \"$1\""
      return
    fi
    sleep "$every"
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

