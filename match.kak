provide-module match %{
  declare-option -hidden str _match_xml_object "c<lt>([\w.]+)\b[^>]*?(?<lt>!/)>,<lt>/([\w.]+)\b[^>]*?(?<lt>!/)><ret>"
  declare-option -hidden str-list _match_saved_surround_history

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
u:             argument
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

  define-command -hidden _match-surround-save-undo %{
    set-option -add window _match_saved_surround_history "%val{history_id}|%val{selections_desc}"
  }

  define-command match-surround-undo %{
    evaluate-commands %{
      try %{ execute-keys u } catch %{ fail 'nothing left to undo' }
      evaluate-commands %sh{
        eval "set -- $kak_quoted_opt__match_saved_surround_history"

        for his in "$@"; do
          id="$(printf '%s' "$his" | cut -d '|' -f1 )"
          sel="$(printf '%s' "$his" | cut -d '|' -f2 )"
          if [ "$id" = "$kak_history_id" ]; then
            printf '%s\n' "select $sel"
            printf 'echo\n'
            break
          fi
        done
      }
    }
  }

  define-command -override match-surround-redo %{
    evaluate-commands -save-regs 's' %{
      set-register s  ''
      evaluate-commands %sh{
        eval "set -- $kak_quoted_opt__match_saved_surround_history"

        for his in "$@"; do
          id="$(printf '%s' "$his" | cut -d '|' -f1)"
          sel="$(printf '%s' "$his" | cut -d '|' -f2)"
          if [ "$id" = "$kak_history_id" ]; then
            printf "%s\n" "set-register s '$sel'"
            break
          fi
        done
      }
      try %{ execute-keys U } catch %{ fail 'nothing left to redo' }
      evaluate-commands %sh{
        if [ -n "$kak_main_reg_s" ]; then
          printf "%s\n" "select $kak_main_reg_s"
          printf "%s\n" "execute-keys '<a-semicolon>L<a-semicolon>L'"
          printf 'echo\n'
        fi
      }
    }
  }

  define-command _match-surround-add-tag -hidden %{
    prompt "Tag:" %{
      evaluate-commands %sh{
        printf '%s\n' "execute-keys -draft i<lt>$( \
          printf '%s\n' "$kak_text" | sed 's/ /<space>/g' \
        )<gt><esc>a<lt>/${kak_text%% *}<gt><esc>i<left><right><esc>"
      }
    }
  }

  define-command match-surround-add %{
    _match-surround-info "Surround add"
    _match-surround-save-undo
    on-key %{
      evaluate-commands %sh{
        case "$kak_key" in
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "t") printf '%s\n' "_match-surround-add-tag" ;;
          "b"|"("|")") printf '%s\n' "execute-keys i(<esc>a)<esc>H" ;;
          "B"|"{"|"}") printf '%s\n' "execute-keys i{<esc>a}<esc>H" ;;
          "r"|"["|"]") printf '%s\n' "execute-keys i[<esc>a]<esc>H" ;;
          "a"|"<lt>"|"<gt>") printf '%s\n' "execute-keys i<lt><esc>a<gt><esc>H" ;;
          "g") printf '%s\n' "execute-keys i\`<esc>a\`<esc>H" ;;
          "q") printf '%s\n' "execute-keys i<quote><esc>a<quote><esc>H" ;;
          "Q") printf '%s\n' "execute-keys i<dquote><esc>a<dquote><esc>H" ;;
          *) printf '%s\n' "execute-keys i$kak_key<esc>a$kak_key<esc>H" ;;
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
      printf '%s\n' "execute-keys s<lt>/$tag<ret>m<a-d><a-?><lt>${tag}<ret>m<a-d>"
    }
  }

  define-command match-surround-delete %{
    _match-surround-info "Surround delete"
    _match-surround-save-undo
    on-key %{
      evaluate-commands %sh{
        case "$kak_key" in
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "t") printf '%s\n' "evaluate-commands -draft _match-surround-delete-tag" ;;
          "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"|"|"\\"|"*"|"i"|"p"|'.'|','|'?'|'^'|"<plus>"|'$')
            printf '%s\n' "execute-keys -draft <a-i>${kak_key}i<backspace><esc>a<del><esc>:nop<ret>"
            ;;
          *)
            printf '%s\n' "execute-keys <a-i>c${kak_key},${kak_key}<ret>i<backspace><esc>a<del><esc>:nop<ret>"
            ;;
        esac
      }
      execute-keys :nop<ret>
    }
  }

  define-command _match-surround-replace-tag -hidden %{
    _match-around-tag
    prompt "Tag: " %{
      evaluate-commands -save-regs 'ts' %{
        execute-keys '"tZ' # Select the whole tag
        execute-keys '<a-:><a-semicolon>e' # Get tag start
        execute-keys '"sZ' # Save tag start
        execute-keys '"tz' # Select whole tag
        execute-keys '<a-:><semicolon><a-/><lt>/<ret>e' # Get tag end
        execute-keys '"s<a-z>a' # Select tag start and end
        execute-keys "c%val{text}<esc>" # Change text
        execute-keys '"tz' # Select whole tag
      }
    }
  }

  define-command _match-surround-replace -hidden %{
    _match-surround-info "Surround replace with"
    _match-surround-save-undo
    on-key %{
      evaluate-commands %sh{
        case "$kak_key" in
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "b"|"("|")") printf '%s\n' "execute-keys -draft i<backspace>(<esc>a<del>)<esc>" ;;
          "B"|"{"|"}") printf '%s\n' "execute-keys -draft i<backspace>{<esc>a<del>}<esc>" ;;
          "r"|"["|"]") printf '%s\n' "execute-keys -draft i<backspace>[<esc>a<del>]<esc>" ;;
          "a"|"<lt>"|"<gt>") printf '%s\n' "execute-keys -draft i<backspace><lt><esc>a<del><gt><esc>" ;;
          "g") printf '%s\n' "execute-keys -draft i<backspace>\`<esc>a<del>\`<esc>" ;;
          "q") printf '%s\n' "execute-keys -draft i<backspace><quote><esc>a<del><quote><esc>" ;;
          "Q") printf '%s\n' "execute-keys -draft i<backspace><dquote><esc>a<del><dquote><esc>" ;;
          "t") printf '%s\n' "execute-keys -draft i<backspace><esc>a<del><esc>:_match-surround-add-tag<ret>" ;;
          *) printf '%s\n' "execute-keys -draft i<backspace>${kak_key}<esc>a<del>${kak_key}<esc>" ;;
        esac
      }
      execute-keys :nop<ret>
    }
  }

  define-command match-surround-replace %{
    _match-surround-info "Surround replace"
    _match-surround-save-undo
    on-key %{
      evaluate-commands %sh{
        case "$kak_key" in
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "t") printf '%s\n' _match-surround-replace-tag ;;
          "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"|"|"\\"|"*"|"i"|"p"|'.'|','|'?'|'^'|"<plus>"|'$')
            printf '%s\n' "execute-keys <a-i>${kak_key}<ret>:_match-surround-replace<ret>"
            ;;
          *) printf '%s\n' "execute-keys <a-i>c${kak_key},${kak_key}<ret>:_match-surround-replace<ret>" ;;
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
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "t") printf '%s\n' "_match-inside-tag" ;;
          "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"<a-w>"|"u"|"|"|"\\"|"*"|"i"|"p"|'.'|','|'?'|'^'|"<plus>"|'$')
            printf '%s\n' "execute-keys <a-i>${kak_key}<ret>"
            ;;
          *) printf '%s\n' "execute-keys <a-i>c${kak_key},${kak_key}<ret>" ;;
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
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "t") printf '%s\n' _match-around-tag ;;
          "b"|"("|")"|"B"|"{"|"}"|"r"|"["|"]"|"a"|"g"|"<lt>"|"<gt>"|"Q"|"q"|"w"|"<a-w>"|"u"|"|"|"\\"|"*"|"i"|"p"|'.'|','|'?'|'^'|"<plus>"|'$')
            printf '%s\n' "execute-keys <a-a>${kak_key}<ret>"
            ;;
          *) printf '%s\n' "execute-keys <a-a>c${kak_key},${kak_key}<ret>" ;;
        esac
      }
    }
  }

  define-command match-next %{
    _match-info "Match next"
    on-key %{
      evaluate-commands %sh{
        case "$kak_key" in
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "b"|"("|")") printf '%s\n' "execute-keys /\(<ret><a-a>)<ret>" ;;
          "B"|"{"|"}") printf '%s\n' "execute-keys /\{<ret><a-a>}<ret>" ;;
          "r"|"["|"]") printf '%s\n' "execute-keys /\[<ret><a-a>]<ret>" ;;
          "a"|"<lt>"|"<gt>") printf '%s\n' "execute-keys /<lt><ret><a-a><lt><ret>" ;;
          "g") printf '%s\n' "execute-keys /\`<ret><a-a>\`<ret>" ;;
          "q") printf '%s\n' "execute-keys /<quote><ret><a-a><quote><ret>" ;;
          "Q") printf '%s\n' 'execute-keys /<dquote><ret><a-a><dquote><ret>' ;;
          "w") printf '%s\n' "execute-keys /\w+<ret><a-i>w" ;;
          "<a-w>") printf '%s\n' "execute-keys /\S+<ret><a-i><a-w>" ;;
          "u") printf '%s\n' "execute-keys /\\(|\\{|\\[|,|\;)<ret>l<a-i>u" ;; #] } )
          "t") printf '%s\n' "execute-keys '<a-:><a-semicolon><semicolon>/<lt>\w[\w-0-9]*[^<gt>]*[^/]<gt><ret>l:_match-around-tag<ret>'" ;;
          "i") printf '%s\n' "execute-keys /^\h+<ret><a-a>i<a-:><a-semicolon><ret>";;
          "p") printf '%s\n' "execute-keys /^[^\n]<ret><a-i>p<a-:><a-semicolon>" ;;
          '.'|'*'|','|'?'|'^'|'|'|"<plus>"|'$'|'\\') printf '%s\n' "execute-keys /\\${kak_key}<ret><a-a>${kak_key}" ;;
          *) printf '%s\n' "execute-keys /${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
        esac
      }
    }
  }

  define-command match-prev %{
    _match-info "Match previous"
    on-key %{
      evaluate-commands %sh{
        case "$kak_key" in
          "<esc>"|"<left>"|"<right>"|"<up>"|"<down>"|"<backspace>"|"<del>"|"<ret>"|"<home>"|"<end>") printf '%s\n' "execute-keys :nop<ret>" ;;
          "b"|"("|")") printf '%s\n' "execute-keys <a-/>\(<ret><a-a>)<ret>" ;;
          "B"|"{"|"}") printf '%s\n' "execute-keys <a-/>\{<ret><a-a>}<ret>" ;;
          "r"|"["|"]") printf '%s\n' "execute-keys <a-/>\[<ret><a-a>]<ret>" ;;
          "a"|"<lt>"|"<gt>") printf '%s\n' "execute-keys <a-/><lt><ret><a-a><lt><ret>" ;;
          "g") printf '%s\n' "execute-keys <a-/>\`<ret><a-a>\`<ret>" ;;
          "q") printf '%s\n' "execute-keys <a-/><quote><ret><a-a><quote><ret>" ;;
          "Q") printf '%s\n' 'execute-keys <a-/><dquote><ret><a-a><dquote><ret>' ;;
          "w") printf '%s\n' "execute-keys <a-/>\w+<ret><a-i>w" ;;
          "<a-w>") printf '%s\n' "execute-keys <a-/>\S+<ret><a-i><a-w>" ;;
          "u") #( { [ \              # Used case I'm too lazy to pick the right characters to stop this from breaking
            printf '%s\n' "execute-keys <a-/>\\)|\\}|\\]|,|\;<ret>h<a-i>u" ;;
          "t") printf '%s\n' "execute-keys '<a-/><lt>/?\w[\w-0-9]*[^<gt>]*[^/]<gt><ret>m:_match-around-tag<ret>'" ;;
          "i") printf '%s\n' "execute-keys <a-/>^\h+<ret><a-a>i<a-:><ret>";;
          "p") printf '%s\n' "execute-keys <a-/>^[^\n]<ret><a-i>p<a-:><a-semicolon>" ;;
           '.'|'*'|','|'?'|'^'|'|'|"<plus>"|'$'|'\\') printf '%s\n' "execute-keys <a-/>\\${kak_key}<ret><a-a>${kak_key}" ;;
          *) printf '%s\n' "execute-keys <a-/>${kak_key}<ret><a-a>c${kak_key},${kak_key}<ret>" ;;
        esac
      }
    }
  }
}

require-module match
