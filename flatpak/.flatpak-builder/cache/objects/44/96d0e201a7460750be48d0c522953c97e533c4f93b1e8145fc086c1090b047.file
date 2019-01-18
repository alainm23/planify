#!/bin/sh
FILES=""
MLEVEL="0"
LMODE="async"
FLAGS=

usage="echo usage: lneato [-V] [-lm (sync|async)] [-el (0|1)] <filename>"

if test "x$DOTTYOPTIONS" != "x"
then
    options=$DOTTYOPTIONS
else
    options="$@"
fi

set -- $options

for i in "$@"
do
	if test "x$i" = "x$1"
	then
		case $i in
		-V)
			shift
			echo "lneato version 95 (04-18-95)"
			FLAGS=$FLAGS" -V"
			;;
		-lm)
			shift
			LMODE="$1"
			shift
			if test "x$LMODE" != "xsync" -a "x$LMODE" != "xasync"
			then
				$usage
				exit 1
			fi
			;;
		-el)
			shift
			MLEVEL="$1"
			shift
			if test "x$MLEVEL" != "x0" -a "x$MLEVEL" != "x1"
			then
				$usage
				exit 1
			fi
			;;
		-?*)
			$usage
			exit 1
			;;
		*)
			FILES="$FILES '"$1"'"
			shift
			;;
		esac
	fi
done

if test "x$MLEVEL" != "x0"
then
	echo "FILES  = $FILES"
	echo "MLEVEL = $MLEVEL"
	echo "LMODE  = $LMODE"
fi

if test "x$DOTTYPATH" != "x"
then
    LEFTYPATH="$DOTTYPATH:$LEFTYPATH"
fi

CMDS="dotty.layoutmode = '$LMODE';"
CMDS="$CMDS dotty.mlevel = $MLEVEL; dot.mlevel =  $MLEVEL;"

if test "x$FILES" = "x"
then
    FILES=null
fi
for i in $FILES
do
	CMDS="$CMDS dotty.createviewandgraph($i,'file',null,null);"
done

lefty $FLAGS -e "
load ('dotty.lefty');

checkpath = function () {
	if (tablesize(dotty) > 0);	# because tablesize(undef) returns "" not 0
	else {
		echo('You must set LEFTYPATH to the lefty lib directory path name.');
		exit();
	}
};
checkpath ();

dotty.protogt.lserver = 'neato';
dotty.protogt.graph.type = 'graph';
dotty.init ();
monitorfile = dotty.monitorfile;
$CMDS
txtview ('off');
"
