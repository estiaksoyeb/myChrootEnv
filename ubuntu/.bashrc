# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


source ~/.local/bin/bashmarks.sh

export ANDROID_SDK_ROOT=/opt/android-sdk-custom/android-sdk
export ANDROID_HOME=/opt/android-sdk-custom/android-sdk
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
export PATH=/data/data/com.termux/files/usr/bin:$PATH

eval "$(zoxide init bash)"

PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;0m\]\w\[\e[0m\]\$ '
export PATH=$HOME/.local/bin:$PATH

# Android NDK configuration
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.0.12077973
export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME
export PATH="/opt/android-sdk-custom/android-sdk/build-tools/36.1.0:$PATH"

# Termai auto-completion
source <("/root/.local/bin/ai" completion bash)

# Termai auto-completion
source <("/root/.local/bin/ai" completion bash)
alias rich='python3 -m rich.markdown'


# Added by Antigravity CLI installer
export PATH="/root/.local/bin:$PATH"

# Added custom command shortcut
export PATH="$HOME/bin:$PATH"


# my function
h() {
    local cmd
    cmd=$(history | tac | fzf | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//')
    [[ -z $cmd ]] && return
    history -s "$cmd"
    eval "$cmd"
}

e() {
    nvim "$(fzf)"
}

d() {
    git diff "$@" | delta
}
r() {
    rich "$(fzf)"
}

# pnpm
export PNPM_HOME="/root/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# Auto-attach to tmux on SSH login
if [ -n "$SSH_CONNECTION" ] && command -v tmux >/dev/null; then
    [ -z "$TMUX" ] && exec tmux new-session -A -s main
fi

# Initialize starship prompt
eval "$(starship init bash)"

# Fix environment variables for ble.sh
export USER=${USER:-$(id -un)}
export LANG=${LANG:-C.UTF-8}

# Initialize ble.sh (auto-suggestions and syntax highlighting)
[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh

