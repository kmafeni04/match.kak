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
i:             indent
p:             paragraph
t:             XML tag
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
t:             XML tag
...:           Pressed character
"
}

declare-option -hidden str _match_xml_object "c<lt>([\w.]+)\b[^>]*?(?<lt>!/)>,<lt>/([\w.]+)\b[^>]*?(?<lt>!/)><ret>"

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

define-command _match-surround-delete-tag -hidden %{
  _match-around-tag
  execute-keys m
  evaluate-commands %sh{
    tag="${kak_selections##*</}"
    tag="${tag%>}"
    echo "execute-keys s<lt>/$tag<ret>m<a-d><a-?><lt>${tag}<ret>m<a-d>"
  }
}

define-command match-surround-delete %{
  _match-surround-info "Surround delete"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo "evaluate-commands -draft _match-surround-delete-tag" ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"|"|"\\"|"*")
          echo "execute-keys -draft <a-i>${kak_key}i<backspace><esc>a<del><esc>:nop<ret>"
          ;;
        *)
          echo "execute-keys <a-i>c${kak_key},${kak_key}<ret>i<backspace><esc>a<del><esc>:nop<ret>"
          ;;
      esac
    }
    execute-keys :nop<ret>
  }
}

define-command _match-surround-replace-tag -hidden %{
  _match-around-tag
  prompt "Tag: " %{
    evaluate-commands -save-regs 't' %sh{
      echo "execute-keys '<dquote>tZ'"
      echo "execute-keys m"
      tag="${kak_selections##*</}"
      tag="${tag%>}"
      echo "execute-keys s<lt>/$tag<ret><a-c><lt>/$kak_text<esc>"
      echo "execute-keys <dquote>tz<a-:><a-semicolon>ms<lt>$tag<ret><a-c><lt>$kak_text<esc>"
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
    execute-keys :nop<ret>
  }
}

define-command match-surround-replace %{
  _match-surround-info "Surround replace"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-surround-replace-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"<a-w>"|"|"|"\\"|"*")
          echo "execute-keys <a-i>${kak_key}<ret>:_match-surround-replace<ret>"
          ;;
        *) echo "execute-keys <a-i>c${kak_key},${kak_key}<ret>:_match-surround-replace<ret>" ;;
      esac
    }
  }
}

define-command _match-inside-tag -hidden %{
  execute-keys "<a-i>%opt{_match_xml_object}<ret><a-:><a-;>"
}

define-command match-inside %{
  _match-info "Match inside"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-inside-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"<a-w>"|"|"|"\\"|"*"|"i"|"p")
          echo "execute-keys <a-i>${kak_key}<ret>"
          ;;
        *) echo "execute-keys <a-i>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}

define-command _match-around-tag -hidden %{
  execute-keys "<a-a>%opt{_match_xml_object}<ret><a-:><a-semicolon>"
}

define-command match-around %{
  _match-info "Match around"
  on-key %{
    evaluate-commands %sh{
      case "$kak_key" in
        "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") echo "execute-keys :nop<ret>" ;;
        "t") echo _match-around-tag ;;
        "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"<a-w>"|"|"|"\\"|"*"|"i"|"p")
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
        "w") echo "execute-keys /\w+<ret><a-i>w" ;;
        "<a-w>") echo "execute-keys /\S+<ret><a-i><a-w>" ;;
        "t") echo "execute-keys '<a-:><a-semicolon><semicolon>/<lt>\w[\w-0-9]*[^<gt>]*[^/]<gt><ret>l:_match-around-tag<ret>'" ;;
        "i") echo "execute-keys /^\h+<ret><a-a>i<a-:><a-semicolon><ret>";;
        "p") echo "execute-keys /^[^\n]<ret><a-i>p<a-:><a-semicolon>" ;;
        "\\"|"|"|"*") echo "execute-keys /\\${kak_key}<ret><a-a>${kak_key}" ;;
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
        "w") echo "execute-keys <a-/>\w+<ret><a-i>w" ;;
        "<a-w>") echo "execute-keys <a-/>\S+<ret><a-i><a-w>" ;;
        "t") "execute-keys '<a-/><lt>/?\w[\w-0-9]*[^<gt>]*[^/]<gt><ret>m:_match-around-tag<ret>'" ;;
        "i") echo "execute-keys <a-/>^\h+<ret><a-a>i<a-:><ret>";;
        "p") echo "execute-keys <a-/>^[^\n]<ret><a-i>p<a-:><a-semicolon>" ;;
        "\\"|"|"|"*") echo "execute-keys <a-/>\\${kak_key}<ret><a-a>${kak_key}" ;;
        *) echo "execute-keys <a-/>${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
      esac
    }
  }
}
