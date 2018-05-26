# vim:ft=zsh ts=2 sw=2 sts=2
#
# gunzy's Theme
# fork of agnoster's theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # READMudo
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
PRIMARY_FG=black

SEGMENT_SEPARATOR='\ue0b0'

GIT_BRANCH="\ue725"
GIT_DETACHED="\ue729"
GIT_STAGED="\uf067"
GIT_UNSTAGED="\uf111"
GIT_PROMPT_AHEAD="\u2191"
GIT_PROMPT_BEHIND="\u2193"

ROOT="\u2622"
PYTHON="\ue606"
ERROR="\ue009"
GEAR="\uf013"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ $UID -eq 0 ]]; then
    prompt_segment $PRIMARY_FG red "%(!.%{%F{red}%}.)$ROOT $user@%m"
  elif [[ -n "$SSH_CLIENT" ]]; then
    prompt_segment $PRIMARY_FG yellow "%(!.%{%F{yellow}%}.)$user@%m"
  else
    prompt_segment $PRIMARY_FG green "%(!.%{%F{green}%}.)%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="$GIT_DETACHED $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if is_dirty; then
      prompt_segment yellow $PRIMARY_FG
    else
      prompt_segment green $PRIMARY_FG
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr "$GIT_STAGED "
    zstyle ':vcs_info:*:*' unstagedstr "$GIT_UNSTAGED "
    zstyle ':vcs_info:*:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats '%u%c'
    vcs_info
    echo -n "${ref/refs\/heads\//$GIT_BRANCH }${vcs_info_msg_0_}$(git_remote_status)"
  fi
}

git_remote_status() {
    local remote ahead behind git_remote_status
    remote=${$(command git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/}
    if [[ -n ${remote} ]]; then
        ahead=$(command git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l)
        behind=$(command git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l)

        if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]; then
            git_remote_status=""
        elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]; then
            git_remote_status="$GIT_PROMPT_AHEAD$((ahead)) "
        elif [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]; then
            git_remote_status="$GIT_PROMPT_BEHIND$((behind)) "
        elif [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]; then
            git_remote_status="$GIT_PROMPT_AHEAD$((ahead))$GIT_PROMPT_BEHIND$((behind)) "
        fi
        echo $git_remote_status
    fi
}

prompt_pyenv() {
  if which pyenv &> /dev/null; then
    version="$(pyenv version | sed -e 's/ (set.*$//' | tr '\n' ' ' | sed 's/.$//')"
    [[ $version != system && $version != "" ]] && prompt_segment white black "$PYTHON $version"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$ERROR "
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR "

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

## Main prompt
prompt_gunzy_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  if [ $TERM = "xterm-256color" ]; then
        prompt_status
        prompt_context
        prompt_pyenv
        prompt_dir
        prompt_git
        prompt_end
  else
        echo -n "%n@%m $"
  fi
}

prompt_gunzy_precmd() {
  PROMPT='%{%f%b%k%}$(prompt_gunzy_main) '
}

prompt_gunzy_setup() {
  autoload -Uz add-zsh-hook

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_gunzy_precmd
}

prompt_gunzy_setup "$@"
