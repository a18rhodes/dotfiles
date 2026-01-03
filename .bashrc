export TERM=xterm-256color
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lahtr'
alias l='ls $LS_OPTIONS -lA'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Make the prompt nice (User@Host:CurrentDir)
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
