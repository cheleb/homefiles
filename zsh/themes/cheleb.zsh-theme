# oh-my-zsh Bureau Theme

### Git [±master ▾●]

cheleb_git_prompt () {
   print $(gistrot-out)
# --warning=%{$fg_bold[red]%} --cool=%{$fg_bold[green]%} --reset=%{$reset_color%})
}

_PATH="%{$fg_bold[white]%}%~%{$reset_color%}"

if [[ $EUID -eq 0 ]]; then
  _USERNAME="%{$fg_bold[red]%}%n"
  _LIBERTY="%{$fg[red]%}#"
else
  _USERNAME="%{$fg_bold[white]%}%n"
  _LIBERTY="%{$fg[green]%}$"
fi
_USERNAME="$_USERNAME%{$reset_color%}@%m"
_LIBERTY="$_LIBERTY%{$reset_color%}"

get_space () {
  local STR=$1$2
  local zero='%([BSUbfksu]|([FB]|){*})'
  local LENGTH=${#${(S%%)STR//$~zero/}}
  local SPACES=""
  (( LENGTH = ${COLUMNS} - $LENGTH - 1))

  for i in {1..$LENGTH}
    do
      SPACES="$SPACES "
    done

  echo $SPACES
}

_1LEFT="$_PATH"
_1RIGHT='$(cheleb_git_prompt)'

cheleb_precmd () {
  _1SPACES=`get_space $_1LEFT$_1RIGHT`
  print
  print -rP "$_1LEFT$_1SPACES$_1RIGHT"
}

setopt prompt_subst
PROMPT='[%*]> $_LIBERTY '
RPROMPT=''

autoload -U add-zsh-hook
add-zsh-hook precmd cheleb_precmd
