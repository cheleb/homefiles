# Options
set __fish_git_prompt_show_informative_status
set __fish_git_prompt_showcolorhints
set __fish_git_prompt_showupstream "informative"

# Colors
set green (set_color green)
set magenta (set_color magenta)
set normal (set_color normal)
set red (set_color red)
set yellow (set_color yellow)

set __fish_git_prompt_color_branch magenta --bold
set __fish_git_prompt_color_dirtystate white
set __fish_git_prompt_color_invalidstate red
set __fish_git_prompt_color_merging yellow
set __fish_git_prompt_color_stagedstate yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red


# Icons
set __fish_git_prompt_char_cleanstate ' 👍  '
set __fish_git_prompt_char_conflictedstate ' ⚠️  '
set __fish_git_prompt_char_dirtystate ' 💩  '
set __fish_git_prompt_char_invalidstate ' 🤮  '
set __fish_git_prompt_char_stagedstate ' 🚥  '
set __fish_git_prompt_char_stashstate ' 📦  '
set __fish_git_prompt_char_stateseparator ' | '
set __fish_git_prompt_char_untrackedfiles ' 🔍  '
set __fish_git_prompt_char_upstream_ahead ' ☝️  '
set __fish_git_prompt_char_upstream_behind ' 👇  '
set __fish_git_prompt_char_upstream_diverged ' 🚧  '
set __fish_git_prompt_char_upstream_equal ' 💯 ' 


function visual_length --description\
    "Return visual length of string, i.e. without terminal escape sequences"
    # TODO: Use "string replace" builtin in Fish 2.3.0
    printf $argv | perl -pe 's/\x1b.*?[mGKH]//g' | wc -m
end

function fish_prompt
  set last_status $status

  set my_git_prompt (__fish_git_prompt)
  if test -n "$my_git_prompt" 
    set pwd (prompt_pwd)
    set length2 (string trim (printf "$pwd$my_git_prompt" | perl -pe 's/\x1b.*?[mGKH]//g' | wc -m ) )
    set length ( string length $my_git_prompt )
    set COLUMNS (tput cols) 
    set MID (math "$COLUMNS - $length2 - 2" )
    set padding (string repeat -n $MID " ")
    set_color $fish_color_cwd
    printf "%s" $pwd$padding
    printf "%s\n" $my_git_prompt
  else
    set_color $fish_color_cwd
    printf '%s ' (prompt_pwd)
  end  
  echo -n "🐠 "
  set_color normal
end
