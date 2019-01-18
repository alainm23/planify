#!/bin/sh
# Written by: John Ellson <ellson@research.att.com>

error() { echo "$0: $*" >&2; exit 1; }

# Try $EDITOR first, else try vim or vi
editor="$EDITOR"
[ -x "$editor" ] || editor="/usr/bin/vim"
[ -x "$editor" ] || editor="/usr/bin/vi"
[ -x "$editor" ] || error "EDITOR not found or not executable";

default="noname.gv"

if test -z "$1"; then
	f="$default"
	if ! test -f "$f"; then
		if ! test -w .; then error "directory `pwd` is not writable"; fi
		cat >"$f" <<EOF
digraph G {
	graph [layout=dot rankdir=LR]

// This is just an example for you to use as a template.
// Edit as you like. Whenever you save a legal graph
// the layout in the graphviz window will be updated.

	vim [href="http://www.vim.org/"]
	dot [href="http://www.graphviz.org/"]
	vimdot [href="file:///usr/bin/vimdot"]

	{vim dot} -> vimdot
}
EOF
	fi
else
	f="$1"
fi

if ! test -w "$f"; then error "$f is not writable"; fi

# dot -Txlib watches the file $f for changes using inotify()
dot -Txlib "$f" 2>/dev/null &
# open an editor on the file $f (could be any editor; gvim &'s itself)
exec $editor "$f"
