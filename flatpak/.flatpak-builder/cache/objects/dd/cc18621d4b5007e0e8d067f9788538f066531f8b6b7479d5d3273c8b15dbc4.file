#!/bin/sh

# Script for gvmap pipeline
# Use -A to add flags for gvmap; e.g., -Ae results in gvmap -e
# -K can be used to change the original layout; by default, sfdp is used
# -T is used to specify the final output format
# -G, -N and -E flags can be used to tailor the rendering
# -g, -n and -e flags can be used to tailor the initial layout
# Be careful of spaces in the flags. If these are not wrapped in quotes, the
# parts will be separated during option processing.

LAYOUT=sfdp
trap 'rm -f $TMPFILE1 $TMPFILE2 $TMPINFILE errout; exit' 0 1 2 3 15
OPTSTR="vVA:[gvmap flags]G:[attr=val]E:[attr=val]N:[attr=val]g:[attr=val]e:[attr=val]n:[attr=val]K:[layout]T:[output format]o:[outfile]"
FLAGS1=
FLAGS2=
FLAGS3=

while getopts ":$OPTSTR" c
do
  case $c in
  v )
    VERBOSE=1
    FLAGS1="$FLAGS1 -v"
    FLAGS2="$FLAGS2 -v"
    FLAGS3="$FLAGS3 -v"
    ;;
  V )
	dot -V
    exit 0
    ;;
  K )
    LAYOUT=$OPTARG
    ;;
  A )
    FLAGS2="$FLAGS2 -$OPTARG"
    ;;
  T )
    FLAGS3="$FLAGS3 -T$OPTARG"
    ;;
  e )
      FLAGS1="$FLAGS1 -E$OPTARG"
    ;;
  n )
      FLAGS1="$FLAGS1 -N$OPTARG"
    ;;
  g )
      FLAGS1="$FLAGS1 -G$OPTARG"
    ;;
  E )
      FLAGS3="$FLAGS3 -E$OPTARG"
    ;;
  N )
      FLAGS3="$FLAGS3 -N$OPTARG"
    ;;
  G )
      FLAGS3="$FLAGS3 -G$OPTARG"
    ;;
  o )
      FLAGS3="$FLAGS3 -o$OPTARG"
    ;;
  :)
    print -u 2 $OPTARG requires a value
    exit 2
    ;;
  \? )
    if [[ "$OPTARG" == '?' ]]
    then
      getopts -a gvmap "$OPTSTR" x '-?'
      exit 0
    else
      print -u 2 "gvmap: unknown flag $OPTARG - ignored"
    fi
    ;;
  esac
done
shift $((OPTIND-1))

if [[ $# == 0 ]]
then
  if [[ -n $VERBOSE ]]
  then
    print -u 2 "$LAYOUT -Goverlap=prism $FLAGS1 | gvmap $FLAGS2 | neato -n2 $FLAGS3"
  fi
  $LAYOUT -Goverlap=prism $FLAGS1 | gvmap $FLAGS2 | neato -n2 $FLAGS3
else
  while (( $# > 0 ))
  do
    if [[ -f $1 ]]
    then
      if [[ -n $VERBOSE ]]
      then
        print -u 2 "$LAYOUT -Goverlap=prism $FLAGS1 $1 | gvmap $FLAGS2 | neato -n2 $FLAGS3"
      fi
      $LAYOUT -Goverlap=prism $FLAGS1 $1 | gvmap $FLAGS2 | neato -n2 $FLAGS3
    else
      print -u 2 "gvmap: unknown input file $1 - ignored"
    fi
    shift
  done
fi



