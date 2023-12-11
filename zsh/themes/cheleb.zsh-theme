# oh-my-zsh cheleb Theme

### Git [±master ▾●]

cheleb_precmd() {
  print -rP $(gistrot-out ${COLUMNS} "⎯")
}

setopt prompt_subst
PROMPT='[%*]> %{$fg[green]%}$%{$reset_color%} '
RPROMPT=''

autoload -U add-zsh-hook
add-zsh-hook precmd cheleb_precmd
