# oh-my-zsh Bureau Theme

### Git [±master ▾●]

cheleb_git_prompt () {
  print $(zsh-git-prompt.pl %{$fg_bold[red]%} %{$fg_bold[green]%} %{$reset_color%})
}


_PATH="%{$fg_bold[white]%}%~%{$reset_color%}"


get_space () {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=""
  (( LENGTH = ${COLUMNS} - $LENGTH - 1))

  for i in {0..$LENGTH}
    do
      SPACES="$SPACES "
    done

  echo $SPACES
}

_1LEFT="$_PATH"
_1RIGHT="[%*] "

cheleb_precmd () {
  _1SPACES=`get_space $_1LEFT $_1RIGHT`
  print
  print -rP "$_1LEFT$_1SPACES$_1RIGHT"
}

setopt prompt_subst
PROMPT='> $_LIBERTY'
RPROMPT='$(cheleb_git_prompt)'

autoload -U add-zsh-hook
add-zsh-hook precmd cheleb_precmd
