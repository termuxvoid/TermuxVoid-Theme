if status is-interactive
    # Commands to run in interactive sessions can go here
end
function fish_greeting
#logo
end
# navigation
alias ..='cd ..'
alias ....='cd ../..'
alias ......='cd ../../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'


# Changing "ls" to "eza"
alias la='eza -al --color=always --group-directories-first' # my preferred listing
alias ls='eza --color=always --group-directories-first'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first'  # long format
alias lt='eza -a --color=always --group-directories-first' # tree listing
#alias l.='eza -a | grep -E "^\."

starship init fish | source
