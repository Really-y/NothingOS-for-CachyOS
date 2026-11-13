# Nothing — zsh highlighting, suggestions and fzf in white / grey / one red.
# Sourced at the end of ~/.zshrc (after oh-my-zsh loads the plugins) by scripts/install.sh.

typeset -gA ZSH_HIGHLIGHT_STYLES
for k in default command builtin alias suffix-alias global-alias function precommand \
         reserved-word hashed-command autodirectory; do
  ZSH_HIGHLIGHT_STYLES[$k]='fg=15'
done
for k in single-quoted-argument double-quoted-argument dollar-quoted-argument \
         back-quoted-argument rc-quote dollar-double-quoted-argument \
         back-double-quoted-argument back-dollar-quoted-argument assign named-fd \
         numeric-fd redirection commandseparator single-hyphen-option double-hyphen-option \
         globbing history-expansion process-substitution command-substitution \
         arithmetic-expansion arg0; do
  ZSH_HIGHLIGHT_STYLES[$k]='fg=245'
done
ZSH_HIGHLIGHT_STYLES[path]='fg=15,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=15,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=245,underline'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=1'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=15'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=245'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=8'
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg=16,bg=15'

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--color=bg:#000000,bg+:#1a1a1a,fg:#8e8e8e,fg+:#ffffff,hl:#ffffff,hl+:#d71921,info:#5e5e5e,prompt:#ffffff,pointer:#d71921,marker:#d71921,spinner:#5e5e5e,header:#5e5e5e,border:#2a2a2a,gutter:#000000 --pointer=● --marker=● --prompt='● '"
