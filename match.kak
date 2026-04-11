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
    evaluate-commands %sh{
      echo "execute-keys -draft i<lt>$(echo "$kak_text" | sed 's/ /<space>/g')<gt><esc>a<lt>/${kak_text%% *}<gt><esc>i<left><right><esc>"
    }
  }
}

define-command match-surround-add %{
  _match-surround-info "Surround add"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-surround-add-tag ;;
        "b"|"("|")") echo "execute-keys i(<esc>a)<esc>H" ;;
        "B"|"{"|"}") echo "execute-keys i{<esc>a}<esc>H" ;;
        "r"|"["|"]") echo "execute-keys i[<esc>a]<esc>H" ;;
        "a"|"<lt>"|"<gt>") echo "execute-keys i<lt><esc>a<gt><esc>H" ;;
        "g") echo "execute-keys i\`<esc>a\`<esc>H" ;;
        "q") echo "execute-keys i<quote><esc>a<quote><esc>H" ;;
        "Q") echo "execute-keys i<dquote><esc>a<dquote><esc>H" ;;
        *) echo "execute-keys i$kak_key<esc>a$kak_key<esc>H" ;;
      esac
    }
  }
}

define-command match-surround-delete %{
  _match-surround-info "Surround delete"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo "execute-keys -draft ':_select-boundary-of-surrounding-tag<ret>m<a-d>'" ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"|"|"\\")
          echo "execute-keys -draft <a-i>${kak_key}i<backspace><esc>a<del><esc>:nop<ret>"
          ;;
        *)
          echo "execute-keys <a-i>c${kak_key},${kak_key}<ret>i<backspace><esc>a<del><esc>:nop<ret>"
          ;;
      esac
    }
  }
}

define-command _match-surround-replace-tag -hidden %{
  _select-boundary-of-surrounding-tag
  execute-keys m
  prompt "Tag: " %{
    evaluate-commands %sh{
      tag="${kak_selections##*</}"
      tag="${tag%>}"
      echo "execute-keys s(?<lt>=<lt>)/?\w[\w-0-9]*<ret>"
      echo "execute-keys -draft <a-c>/$kak_text<esc><a-,>mi<right><del><esc>ma<right><esc>"
    }
  }
}

define-command _match-surround-replace -hidden %{
  _match-surround-info "Surround replace with"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "b"|"("|")") echo "execute-keys -draft i<backspace>(<esc>a<del>)<esc>" ;;
        "B"|"{"|"}") echo "execute-keys -draft i<backspace>{<esc>a<del>}<esc>" ;;
        "r"|"["|"]") echo "execute-keys -draft i<backspace>[<esc>a<del>]<esc>" ;;
        "a"|"<lt>"|"<gt>") echo "execute-keys -draft i<backspace><lt><esc>a<del><gt><esc>" ;;
        "g") echo "execute-keys -draft i<backspace>\`<esc>a<del>\`<esc>" ;;
        "q") echo "execute-keys -draft i<backspace><quote><esc>a<del><quote><esc>" ;;
        "Q") echo "execute-keys -draft i<backspace><dquote><esc>a<del><dquote><esc>" ;;
        "t") echo "execute-keys -draft i<backspace><esc>a<del><esc>:_match-surround-add-tag<ret>" ;;
        *) echo "execute-keys -draft i<backspace>${kak_key}<esc>a<del>${kak_key}<esc>" ;;
      esac
    }
  }
}

define-command match-surround-replace %{
  _match-surround-info "Surround replace"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-surround-replace-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"W"|"|"|"\\")
          echo "execute-keys <a-i>${kak_key}<ret>:_match-surround-replace<ret>"
          ;;
        *) echo "execute-keys <a-i>c${kak_key},${kak_key}<ret>:_match-surround-replace<ret>" ;;
      esac
    }
  }
}

define-command _match-inside-tag -hidden %{
  _select-boundary-of-surrounding-tag
  execute-keys m
  evaluate-commands %sh{
    tag="${kak_selections##*</}"
    tag="${tag%>}"
    echo "execute-keys '<a-,>a<right><esc><a-i>c<lt>$tag[^<gt>]*<gt>,<lt>/$tag[^<gt>]*<gt><ret>'"
  }
}

define-command match-inside %{
  _match-info "Match inside"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-inside-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"W"|"|"|"\\")
          echo "execute-keys <a-i>${kak_key}<ret>"
          ;;
        *) echo "execute-keys <a-i>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command _match-around-tag -hidden %{
  _select-boundary-of-surrounding-tag
  execute-keys m
  evaluate-commands %sh{
    tag="${kak_selections##*</}"
    tag="${tag%>}"
    echo "execute-keys '<a-,>i<left><right><esc>'"
    echo "execute-keys '?<lt>/$tag<gt><ret><a-;>'"
  }
}

define-command match-around %{
  _match-info "Match around"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-around-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"W"|"|"|"\\")
          echo "execute-keys <a-a>${kak_key}<ret>"
          ;;
        *) echo "execute-keys <a-a>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command match-next %{
  _match-info "Match next"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "b"|"("|")") echo "execute-keys /\(<ret><a-a>)<ret>" ;;
        "B"|"{"|"}") echo "execute-keys /\{<ret><a-a>}<ret>" ;;
        "r"|"["|"]") echo "execute-keys /\[<ret><a-a>]<ret>" ;;
        "a"|"<lt>"|"<gt>") echo "execute-keys /<lt><ret><a-a><lt><ret>" ;;
        "g") echo "execute-keys /\`<ret><a-a>\`<ret>" ;;
        "q") echo "execute-keys /<quote><ret><a-a><quote><ret>" ;;
        "Q") echo 'execute-keys /<dquote><ret><a-a><dquote><ret>' ;;
        "w") echo "execute-keys /\w[\w-_]*<ret>" ;;
        "<a-w>") echo "execute-keys /\S+<ret>" ;;
        "t") echo "execute-keys 'lh/<lt>\w[\w-0-9]*[^/<gt>]*<gt><ret>l:_match-around-tag<ret>'" ;;
        "\\"|"|") echo "execute-keys /\\${kak_key}<ret><a-a>${kak_key}" ;;
        *) echo "execute-keys /${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command match-prev %{
  _match-info "Match previous"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "b"|"("|")") echo "execute-keys <a-/>\(<ret><a-a>)<ret>" ;;
        "B"|"{"|"}") echo "execute-keys <a-/>\{<ret><a-a>}<ret>" ;;
        "r"|"["|"]") echo "execute-keys <a-/>\[<ret><a-a>]<ret>" ;;
        "a"|"<lt>"|"<gt>") echo "execute-keys <a-/><lt><ret><a-a><lt><ret>" ;;
        "g") echo "execute-keys <a-/>\`<ret><a-a>\`<ret>" ;;
        "q") echo "execute-keys <a-/><quote><ret><a-a><quote><ret>" ;;
        "Q") echo 'execute-keys <a-/><dquote><ret><a-a><dquote><ret>' ;;
        "w") echo "execute-keys <a-/>\w[\w-_]*<ret>" ;;
        "<a-w>") echo "execute-keys <a-/>\S+<ret>" ;;
        "t") echo "execute-keys 'hl<a-/><lt>\w[\w-0-9]*[^/<gt>]*<gt><ret>l:_match-around-tag<ret>'" ;;
        "\\"|"|") echo "execute-keys <a-/>\\${kak_key}<ret><a-a>${kak_key}" ;;
        *) echo "execute-keys <a-/>${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
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
  evaluate-commands %sh{
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
    echo "try %{ execute-keys '<a-a>c<lt>$result\s?[^>]*>,<lt>/$result><ret>' } catch %{ execute-keys 'i<left><right><esc>'; fail 'No tag matched' }"
  }
  execute-keys '<a-S>'
}
