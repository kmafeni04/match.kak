define-command -hidden _match-info -params 1 %{
  info -title "%arg{1}" \
"b,(,):         Parentheses block
B,{,}:         Braces block
r,[,]:         Bracket block
a,<lt>,<gt>:   Angle block
<dquote>,Q:    Double quote string
<quote>,q:     Single quote string
`,g:           Grave quote string
w:             word
<a-w>:         WORD
t:             Markup tag<tag>
...:           Pressed character
"
}
define-command -hidden _match-surround-info -params 1 %{
  info -title "%arg{1}" \
"b,(,):         Parentheses block
B,{,}:         Braces block
r,[,]:         Bracket block
a,<lt>,<gt>:   Angle block
<dquote>,Q:    Double quote string
<quote>,q:     Single quote string
`,g:           Grave quote string
t:             Markup tag<tag>
...:           Pressed character
"
}

define-command _match-surround-add-tag -hidden %{
  prompt "Tag:" %{
    eval %sh{
      escape(){
        echo "$1"                                  \
        | sed 's/</#:____lt____:#/g'               \
        | sed 's/>/#:____gt____:#/g'               \
        | sed -E 's/#:____([a-z]{2})____:#/<\1>/g' \
        | sed 's/;/<semicolon>/g'                  \
        | sed 's/$/<ret>/g;'                       \
        | sed 's/ /<space>/g'                      \
        | sed 's/\t/<tab>/g'                       \
        | sed ':a;N;$!ba;s/\n//g'                  \
        | sed 's/<ret>$//'
      }
      echo "exec -draft i<lt>$(escape "$kak_text")<gt><esc>a<lt>/${kak_text% *}<gt><esc>i<left><right><esc>"
    }
  }
}

define-command match-surround-add %{
  _match-surround-info "Surround add"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "t") echo _match-surround-add-tag ;;
        "b"|"("|")") echo "exec i(<esc>a)<esc>H" ;;
        "B"|"{"|"}") echo "exec i{<esc>a}<esc>H" ;;
        "r"|"["|"]") echo "exec i[<esc>a]<esc>H" ;;
        "a"|"<lt>"|"<gt>") echo "exec i<lt><esc>a<gt><esc>H" ;;
        "q") echo "exec i<quote><esc>a<quote><esc>H" ;;
        "Q") echo "exec i<dquote><esc>a<dquote><esc>H" ;;
        *) echo "exec i$kak_key<esc>a$kak_key<esc>H" ;;
      esac
    }
  }
}

define-command match-surround-delete %{
  _match-surround-info "Surround delete"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "t") echo "exec -draft ':_select-boundary-of-surrounding-tag<ret>m<a-d>'" ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"<lt>"|"<gt>"|"Q"|"q"|"|"|"\\") echo "exec -draft <a-i>${kak_key}i<backspace><esc>a<del><esc>" ;;
        *) echo "exec <a-i>c${kak_key},${kak_key}<ret>i<backspace><esc>a<del><esc>" ;;
      esac
    }
  }
}

define-command _match-surround-replace-tag -hidden %{
  _select-boundary-of-surrounding-tag
  exec m
  prompt "Tag: " %{
    eval %sh{
      tag="${kak_selections##*</}"
      tag="${tag%>}"
      echo "exec s(?<lt>=<lt>)/?\w[\w-0-9]*<ret>"
      echo "exec -draft <a-c>/$kak_text<esc><a-,>mi<right><del><esc>ma<right><esc>"
    }
  }
}

define-command _match-surround-replace -hidden %{
  info -title "Surround replace char" \
"enter char to replace with
 - <t> will replace selection with markup tag
"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "("|")") echo "exec -draft i<backspace>(<esc>a<del>)<esc>" ;;
        "{"|"}") echo "exec -draft i<backspace>{<esc>a<del>}<esc>" ;;
        "["|"]") echo "exec -draft i<backspace>[<esc>a<del>]<esc>" ;;
        "<lt>"|"<gt>") echo "exec -draft i<backspace><lt><esc>a<del><gt><esc>" ;;
        "t") echo "exec i<backspace><esc>a<del><esc>:_match-surround-add-tag<ret>" ;;
        *) echo "exec -draft i<backspace>${kak_key}<esc>a<del>${kak_key}<esc>" ;;
      esac
    }
  }
}

define-command match-surround-replace %{
  _match-surround-info "Surround replace"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "t") echo _match-surround-replace-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"W"|"|"|"\\")
          echo "exec <a-i>${kak_key}<ret>:_match-surround-replace<ret>"
        ;;
        *) echo "exec <a-i>c${kak_key},${kak_key}<ret>:_match-surround-replace<ret>" ;;
      esac
    }
  }
}

define-command _match-inside-tag -hidden %{
  _select-boundary-of-surrounding-tag
  exec m
  eval %sh{
    tag="${kak_selections##*</}"
    tag="${tag%>}"
    echo "exec '<a-,>a<right><esc><a-i>c<lt>$tag[^<gt>]*<gt>,<lt>/$tag[^<gt>]*<gt><ret>'"
  }
}

define-command match-inside %{
  _match-info "Match inside"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "t") echo _match-inside-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"W"|"|"|"\\") echo "exec <a-i>${kak_key}<ret>" ;;
        *) echo "exec <a-i>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command _match-around-tag -hidden %{
  _select-boundary-of-surrounding-tag
  exec m
  eval %sh{
    tag="${kak_selections##*</}"
    tag="${tag%>}"
    echo "exec '<a-,>i<left><right><esc>'"
    echo "exec '?<lt>/$tag<gt><ret><a-;>'"
  }
}

define-command match-around %{
  _match-info "Match around"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "t") echo _match-around-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"W"|"|"|"\\") echo "exec <a-a>${kak_key}<ret>" ;;
        *) echo "exec <a-a>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command match-next %{
  _match-info "Match next"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "b"|"("|")") echo "exec /\(<ret><a-a>)<ret>" ;;
        "B"|"{"|"}") echo "exec /\{<ret><a-a>}<ret>" ;;
        "r"|"["|"]") echo "exec /\[<ret><a-a>]<ret>" ;;
        "a"|"<lt>"|"<gt>") echo "exec /<lt><ret><a-a><lt><ret>" ;;
        "q") echo "exec /<quote><ret><a-a><quote><ret>" ;;
        "Q") echo 'exec /<dquote><ret><a-a><dquote><ret>' ;;
        "w") echo "exec /\w[\w-_]*<ret>" ;;
        "<a-w>") echo "exec /\S+<ret>" ;;
        "t") echo "exec 'lh/<lt>\w[\w-0-9]*[^/<gt>]*<gt><ret>l:_match-around-tag<ret>'" ;;
        "\\"|"|") echo "exec /\\${kak_key}<ret><a-a>${kak_key}" ;;
        *) echo "exec /${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command match-prev %{
  _match-info "Match previous"
  on-key %{
    eval %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "exec :nop<ret>" ;;
        "b"|"("|")") echo "exec <a-/>\(<ret><a-a>)<ret>" ;;
        "B"|"{"|"}") echo "exec <a-/>\{<ret><a-a>}<ret>" ;;
        "r"|"["|"]") echo "exec <a-/>\[<ret><a-a>]<ret>" ;;
        "a"|"<lt>"|"<gt>") echo "exec <a-/><lt><ret><a-a><lt><ret>" ;;
        "q") echo "exec <a-/><quote><ret><a-a><quote><ret>" ;;
        "Q") echo 'exec <a-/><dquote><ret><a-a><dquote><ret>' ;;
        "w") echo "exec <a-/>\w[\w-_]*<ret>" ;;
        "<a-w>") echo "exec <a-/>\S+<ret>" ;;
        "t") echo "exec 'hl<a-/><lt>\w[\w-0-9]*[^/<gt>]*<gt><ret>l:_match-around-tag<ret>'" ;;
        "\\"|"|") echo "exec <a-/>\\${kak_key}<ret><a-a>${kak_key}" ;;
        *) echo "exec <a-/>${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

# https://github.com/h-youhei/kakoune-surround/blob/efe74c6f434d1e30eff70d4b0d737f55bf6c5022/surround.kak#L199-L239
define-command -hidden _select-boundary-of-surrounding-tag %{
  execute-keys \;
  #handle inside open tag
  try %{
    #<a-a>> produce side effect inside close tag
    #that make tag_list include the close tag
    execute-keys -draft '<a-a>c<lt>/,><ret>'
  } catch %{
    try %{
      execute-keys '<a-a>>'
    }
  }
  execute-keys 'Ge<a-;>'
  eval %sh{
    tag_list=`echo "$kak_selection" | grep -P -o '(?<=<)[^>]+(?=>)' | cut -d ' ' -f 1`
    open=
    open_stack=
    result=
    for tag in $tag_list ; do
      if [ `echo $tag | cut -c 1` != / ] ; then
        case $tag in
        #self-closing tags
        area|base|br|col|command|embed|hr|img|input|keygen|link|meta|param|source|track|wbr) continue ;;
        *)
          open="$tag"
          open_stack="$open\n$open_stack" ;;
        esac
      else
        if [ $tag = /$open ] ; then
          open_stack="${open_stack#*\n}"
          open=`echo -e "$open_stack" | head -n 1`
        else
          result="${tag#/}"
          break
        fi
      fi
    done
    echo "try %{ exec '<a-a>c<lt>$result\s?[^>]*>,<lt>/$result><ret>' } catch %{ exec 'i<left><right><esc>'; fail 'No tag matched' }"
  }
  execute-keys '<a-S>'
}
