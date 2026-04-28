# match.kak
Helix like match commnands plus hacky XML tag support

TODO: Video Showcase

## Installation
Copy [match.kak](./match.kak) into your autoload directory

## Usage

Suggested keymap:
```kak
declare-user-mode match
map global normal m ':enter-user-mode match<ret>'
map global match m m -docstring 'Match next matching pair'
map global match i ':match-inside<ret>' -docstring 'Match inside object'
map global match a ':match-around<ret>' -docstring 'Match around object'
map global match n ':match-next<ret>' -docstring 'Match next object'
map global match p ':match-prev<ret>' -docstring 'Match previous object'
map global match s ':match-surround-add<ret>' -docstring 'Surround selection with character'
map global match d ':match-surround-delete<ret>' -docstring "Delete selection's surrounding character"
map global match r ':match-surround-replace<ret>' -docstring "Replace selection's surrounding character"
```
