export TERM=xterm-256color
export LS_OPTIONS='--color=auto'
# Devcontainer can inject empty GIT_AUTHOR_* vars that override git config
[ -z "${GIT_AUTHOR_NAME:-}" ] && unset GIT_AUTHOR_NAME
[ -z "${GIT_AUTHOR_EMAIL:-}" ] && unset GIT_AUTHOR_EMAIL
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lahtr'
alias l='ls $LS_OPTIONS -lA'

if [[ $- = *i* ]]; then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi


# Make the prompt nice (User@Host:CurrentDir)
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
