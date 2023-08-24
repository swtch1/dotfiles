### personal ###

# zsh-autocomplete
# source /Users/josh/code/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# zstyle ':autocomplete:*' min-delay 0.25
# zstyle ':autocomplete:*' no

source ~/.zshrc-lite

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

# zsh
DISABLE_MAGIC_FUNCTIONS="true"
# don't kill shell on ctrl-d
setopt ignoreeof
# https://www.johnhawthorn.com/2012/09/vi-escape-delays/
KEYTIMEOUT=0

# node version manager nonsense
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

alias v='nvim'
if [ "$(env | grep VIM)" ]; then
  alias v='nvr'
fi
alias vt='v -c terminal'
alias vg='v -c :G'
alias vimdiff='v diff'
alias fzf='v $(/usr/local/bin/fzf)'

alias h='history'
alias c='clear'
alias cat='bat'
alias less='bat'
# I shouldn't have to do this
alias uniq='sort -u'
alias mk='minikube'
alias cdt='cd $(mktemp -d)'
alias cdc='cd ~/code'
alias cds='cd ~/code/speedscale/'
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

# speedctl
alias soa='s deploy operator -e jmt-dev | k apply -n speedscale -f -'
alias soax='s deploy operator -e jmt-dev -X | k apply -n speedscale -f -'
alias sod='s deploy operator | k delete -n speedscale -f -'
alias sodx='s deploy operator -X | k delete -n speedscale -f -'
export PROD_USER_ID='bec83d8b-2c15-4e2e-a0a5-7a90193665f4'

export REVIEW_BASE='master'
alias gp='git pull'
function gpw() { git --work-tree "$1" pull }
alias gpsh='git push'
alias gs='git status -s && git status | ag --no-color "git push"'
alias gc='git checkout'
alias gcm='gt cc -m'
alias gsh='git stash'
alias gpu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gd='git diff'
alias gdm='git diff origin/master..HEAD'
alias gdc='git diff --cached'
# alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit -- "
alias gl="git log --graph --decorate --decorate-refs=tags --all --single-worktree --topo-order --pretty='format:%C(yellow)%h %C(blue)%ad %C(green)%an %C(auto)%s%C(red)% D%C(auto)' --merges"
alias gb='for k in $(git branch | sed s/^..//); do echo -e $(git log -1 --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k --)\\t"$k";done | sort'
alias gw='git worktree'
alias gwa='git worktree add'
# function gpa() {
#   for d in $(git worktree list| grep -v '(bare)'| cut -d ' ' -f 1);do
#     echo "worktree: $d"
#     git --work-tree "$d" pull
#   done
# }
# function gpm() {
#   for d in $(git worktree list| grep 'master'| cut -d ' ' -f 1);do
#     echo "worktree: $d"
#     git --work-tree "$d" pull
#   done
# }
alias grs='gt rs --force --restack'

# kubernetes
source <(kubectl completion zsh)
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
alias k9d='k9s --context dev -n sstenant-external -c pods'
alias k9m='k9s --context minikube -c ns'

####################
### custom funcs ###
####################

# run base64 easier
function b64d() {
  echo "$1" | base64 -d
}

# vim here
function vh() {
  last=$(echo `history |tail -n1 |head -n1` | sed 's/[0-9]* //')
  out=$(eval "$last" | tail -n1)
  combo=$(echo "$out" | awk '{ print $1 }')
  file=$(echo "$combo" | cut -d ':' -f 1)
  line=$(echo "$combo" | cut -d ':' -f 2)
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
  nvim -c :G

  # reset everything
  git reset --hard
  git status -s | awk '{ print $2 }' | xargs rm
  git checkout master
}

# connect to timescale DB
function connect-timescale() {
  if [[ -z $CONTEXT ]];then
    echo "CONTEXT is required"
    return
  fi
  if [[ -z $NAMESPACE ]];then
    echo "NAMESPACE is required"
    return
  fi

  k --context $CONTEXT -n $NAMESPACE exec -it timescaledb-0 -c timescaledb -- bash -c 'PGPASSWORD=$PATRONI_speedscale_PASSWORD psql --user speedscale $TIMESCALE_DB_NAME'
}

# connect to usr-mgmt DB
function connect-usr-mgmt() {
  if [[ -z $CONTEXT ]];then
    echo "CONTEXT is required"
    return
  fi
  if [[ -z $NAMESPACE ]];then
    echo "NAMESPACE is required"
    return
  fi

  pod=$(kgp --context $CONTEXT -n default -l app=usr-mgmt --no-headers | cut -d ' ' -f 1)
  env_vars=$(k --context $CONTEXT -n default exec "$pod" -- printenv)
  db_host=$(echo "$env_vars" | awk -F= '/^DB_HOST/ {print $2}')
  db_username=$(echo "$env_vars" | awk -F= '/^DB_USERNAME/ {print $2}')
  db_password=$(echo "$env_vars" | awk -F= '/^DB_PASSWORD/ {print $2}')
  db_name=$(echo "$env_vars" | awk -F= '/^DB_NAME/ {print $2}')
  k --context $CONTEXT -n $NAMESPACE exec -it timescaledb-0 -c timescaledb -- bash -c "export PGPASSWORD=$db_password && psql --host $db_host --user $db_username $db_name"
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

############
### misc ###
############

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/google-cloud-sdk/path.zsh.inc' ]; then . '/usr/local/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/google-cloud-sdk/completion.zsh.inc' ]; then . '/usr/local/google-cloud-sdk/completion.zsh.inc'; fi

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

