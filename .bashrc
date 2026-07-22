export TERM=xterm-256color
export LS_OPTIONS='--color=auto'
# Codespaces/devcontainers can inject empty GIT_AUTHOR_*/GIT_COMMITTER_* vars
# that override gitconfig identity; drop the empty ones so .gitconfig wins.
[ -z "${GIT_AUTHOR_NAME:-}" ] && unset GIT_AUTHOR_NAME
[ -z "${GIT_AUTHOR_EMAIL:-}" ] && unset GIT_AUTHOR_EMAIL
[ -z "${GIT_COMMITTER_NAME:-}" ] && unset GIT_COMMITTER_NAME
[ -z "${GIT_COMMITTER_EMAIL:-}" ] && unset GIT_COMMITTER_EMAIL
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lahtr'
alias l='ls $LS_OPTIONS -lA'
alias back='popd 2>&1 > /dev/null'
alias cd-builtin='builtin cd'

if [[ $- = *i* ]]; then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi
cd (){
    if [ -z "$1" ]; then
        pushd ~ 2>&1 > /dev/null
    else
        pushd "$1" 2>&1 > /dev/null
    fi
}


# Make the prompt nice (User@Host:CurrentDir)
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
