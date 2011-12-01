#!/bin/bash
# lesspipe.sh, a preprocessor for less (version 1.72)
#===============================================================================
### THIS FILE IS GENERATED FROM lesspipe.sh.in, PLEASE GET THE TAR FILE
### from http://sourceforge.net/projects/lesspipe/
### AND RUN configure TO GENERATE A lesspipe.sh THAT WORKS IN YOUR ENVIRONMENT
#===============================================================================
#
# Usage:   lesspipe.sh is called when the environment variable LESSOPEN is set:
#	   LESSOPEN="|lesspipe.sh %s"; export LESSOPEN	(sh like shells)
#	   setenv LESSOPEN "|lesspipe.sh %s"		(csh, tcsh)
#	   Use the fully qualified path if lesspipe.sh is not in the search path
#	   View files in multifile archives:
#			less archive_file:contained_file
#	   This can be used to extract ASCII files from a multifile archive:
#			less archive_file:contained_file>extracted_file
#	   As less is not good for extracting binary data use instead:
#			lesspipe.sh archive_file:contained_file>extracted_file
#          Even a file in a multifile archive that itself is contained in yet
#          another archive can be viewed this way:
#			less super_archive:archive_file:contained_file
#	   Display the last file in the file1:..:fileN chain in raw format:
#	   Suppress input filtering:	less file1:..:fileN:   (append a colon)
#	   Suppress decompression:	less file1:..:fileN::  (append 2 colons)
#
# Required programs and supported formats: see the separate file README
# License: GPL (see file LICENSE)
# History: see the separate file ChangeLog
# Author:  Wolfgang Friebel, DESY (Wolfgang.Friebel AT desy.de)
#
#===============================================================================
( [[ -n 1 && -n 2 ]] ) > /dev/null 2>&1 || exec zsh -y --ksh-arrays -- "$0" ${1+"$@"}
#setopt KSH_ARRAYS SH_WORD_SPLIT 2>/dev/null
set +o noclobber
tarcmd='tar'

cmd_exist () {
  command -v "$1" > /dev/null 2>&1 && return 0 || return 1
}

filecmd() {
  file -L -s "$@"
  file -L -s -i "$@" 2> /dev/null | sed -n 's/.*charset=/;/p' | tr a-z A-Z
}

sep=:						# file name separator
altsep==					# alternate separator character
if [[ -f "$1" && "$1" = *$sep* || "$1" = *$altsep ]]; then
  sep=$altsep
  xxx="${1%=}"
  set "$xxx"
fi
if cmd_exist mktemp; then
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/lesspipe.XXXXXXXXXX")

  nexttmp () {
    # nexttmp -d returns a directory
    mktemp $1 "${tmpdir}/XXXXXXXX"
  }
else
  tmpdir=${TMPDIR:-/tmp}/lesspipe.$RANDOM
  mkdir $tmpdir

  nexttmp () {
    new="$tmpdir/lesspipe.$RANDOM"
    [[ "$1" = -d ]] && mkdir $new
    echo $new
  }
fi
[[ -d "$tmpdir" ]] || exit 1
trap "rm -rf '$tmpdir'" 0
trap - PIPE

unset iconv
iconv() {
  if [[ -z "$iconv" ]]; then
    iconv="command iconv $(printf "%s$(command iconv --help | sed -n \
      's/.*\(--.*-subst=\)\(FORMATSTRING\).*/\1\\033[7m?\\033[m/p' | \
      tr \\n ' ')") -t //TRANSLIT"
  fi
  $iconv "$@"
}

filetype () {
  # wrapper for 'file' command
  typeset name
  name="$1"
  if [[ "$1" = - ]]; then
    dd bs=40000 count=1 > "$tmpdir/file" 2>/dev/null
    set "$tmpdir/file" "$2"
    name="$filen"
  fi
  typeset type
  # type=" $(filecmd -b "$1")" # not supported by all versions of 'file'
  type=$(filecmd "$1" | cut -d : -f 2-)
  if [[ "$type" = " empty" ]]; then
    # exit if file returns "empty" (e.g., with "less archive:nonexisting_file")
    exit 1
  elif [[ "$type" = *XML* && "$name" = *html ]]; then
    type=" HTML document text"
  elif [[ ("$type" = *HTML* || "$type" = *ASCII*) && "$name" = *xml ]]; then
    type=" XML document text"
  elif [[ "$type" != *lzip\ compressed* && ("$name" = *.lzma || "$name" = *.tlz) ]]; then
    type=" LZMA compressed data"
  elif [[ ("$type" = *Zip* || "$type" = *ZIP*) && ("$name" = *.jar || "$name" = *.xpi) ]]; then
    type=" Zip compressed Jar archive"
  elif [[ "$type" = *Microsoft\ Office\ Document* && ("$name" = *.ppt) ]]; then
       type=" PowerPoint document"
  elif [[ "$type" = *Microsoft\ Office\ Document* && ("$name" = *.xls) ]]; then
       type=" Excel document"
  fi
  echo "$type"
}

show () {
  file1="${1%%$sep*}"
  rest1="${1#$file1}"
  while [[ "$rest1" = ::* ]]; do
    if [[ "$rest1" = "::" ]]; then
      break
    else
      rest1="${rest1#$sep$sep}"
      file1="${rest1%%$sep*}"
      rest1="${rest1#$file1}"
      file1="${1%$rest1}"
    fi
  done
  rest11="${rest1#$sep}"
  file2="${rest11%%$sep*}"
  rest2="${rest11#$file2}"
  while [[ "$rest2" = ::* ]]; do
    if [[ "$rest2" = "::" ]]; then
      break
    else
      rest2="${rest2#$sep$sep}"
      file2="${rest2%%$sep*}"
      rest2="${rest2#$file2}"
      file2="${rest11%$rest2}"
    fi
  done
  if [[ "$file2" != "" ]]; then
    in_file="-i$file2"
  fi
  rest2="${rest11#$file2}"
  rest11="$rest1"
  if [[ "$cmd" = "" ]]; then
    type=$(filetype "$file1") || exit 1
    if cmd_exist lsbom; then
      if [[ ! -f "$file1" ]]; then
        if [[ "$type" = *directory* ]]; then
	  if [[ "$file1" = *.pkg ]]; then
	    if [[ -f "$file1/Contents/Archive.bom" ]]; then
	      type="bill of materials"
	      file1="$file1/Contents/Archive.bom"
	      echo "==> This is a Mac OS X archive directory, showing its contents (bom file)"
	    fi
	  fi
        fi
      fi
    fi
    get_cmd "$type" "$file1" "$rest1"
    if [[ "$cmd" != "" ]]; then
      show "-$rest1"
    else
      isfinal "$type" "$file1" "$rest11"
    fi
  elif [[ "$c1" = "" ]]; then
    c1=("${cmd[@]}")
    type=$("${c1[@]}" | filetype -) || exit 1
    get_cmd "$type" "$file1" "$rest1"
    if [[ "$cmd" != "" ]]; then
      show "-$rest1"
    else
      "${c1[@]}" | isfinal "$type" - "$rest11"
    fi
  elif [[ "$c2" = "" ]]; then
    c2=("${cmd[@]}")
    type=$("${c1[@]}" | "${c2[@]}" | filetype -) || exit 1
    get_cmd "$type" "$file1" "$rest1"
    if [[ "$cmd" != "" ]]; then
      show "-$rest1"
    else
      "${c1[@]}" | "${c2[@]}" | isfinal "$type" - "$rest11"
    fi
  elif [[ "$c3" = "" ]]; then
    c3=("${cmd[@]}")
    type=$("${c1[@]}" | "${c2[@]}" | "${c3[@]}" | filetype -) || exit 1
    get_cmd "$type" "$file1" "$rest1"
    if [[ "$cmd" != "" ]]; then
      show "-$rest1"
    else
      "${c1[@]}" | "${c2[@]}" | "${c3[@]}" | isfinal "$type" - "$rest11"
    fi
  elif [[ "$c4" = "" ]]; then
    c4=("${cmd[@]}")
    type=$("${c1[@]}" | "${c2[@]}" | "${c3[@]}" | "${c4[@]}" | filetype -) || exit 1
    get_cmd "$type" "$file1" "$rest1"
    if [[ "$cmd" != "" ]]; then
      show "-$rest1"
    else
      "${c1[@]}" | "${c2[@]}" | "${c3[@]}" | "${c4[@]}" | isfinal "$type" - "$rest11"
    fi
  elif [[ "$c5" = "" ]]; then
    c5=("${cmd[@]}")
    type=$("${c1[@]}" | "${c2[@]}" | "${c3[@]}" | "${c4[@]}" | "${c5[@]}" | filetype -) || exit 1
    get_cmd "$type" "$file1" "$rest1"
    if [[ "$cmd" != "" ]]; then
      echo "$0: Too many levels of encapsulation"
    else
      "${c1[@]}" | "${c2[@]}" | "${c3[@]}" | "${c4[@]}" | "${c5[@]}" | isfinal "$type" - "$rest11"
    fi
  fi
}

get_cmd () {
  cmd=
  typeset t
  if [[ "$1" = *[bg]zip*compress* || "$1" = *compress\'d\ * || "$1" = *packed\ data* || "$1" = *LZMA\ compressed* || "$1" = *lzip\ compressed* || "$1" = *[Xx][Zz]\ compressed* ]]; then ## added '#..then' to fix vim's syntax parsing
    if [[ "$3" = $sep$sep ]]; then
      return
    elif [[ "$1" = *bzip*compress* ]] && cmd_exist bzip2; then
      cmd=(bzip2 -cd "$2")
      if [[ "$2" != - ]]; then filen="$2"; fi
      case "$filen" in
        *.bz2) filen="${filen%.bz2}";;
        *.tbz) filen="${filen%.tbz}.tar";;
      esac
      return
    elif [[ "$1" = *gzip\ compress* || "$1" =  *compress\'d\ * || "$1" = *packed\ data* ]]; then ## added '#..then' to fix vim's syntax parsing
      cmd=(gzip -cd "$2")
      if [[ "$2" != - ]]; then filen="$2"; fi
      case "$filen" in
        *.gz) filen="${filen%.gz}";;
        *.tgz) filen="${filen%.tgz}.tar";;
      esac
    fi
    return
  fi

  rsave="$rest1"
  rest1="$rest2"
  if [[ "$file2" != "" ]]; then
    if [[ "$1" = *\ tar* || "$1" = *\	tar* ]]; then
      cmd=(istar "$2" "$file2")
    elif [[ "$1" = *Debian* ]]; then
      t=$(nexttmp)
      if [[ "$file2" = control/* ]]; then
        istemp "ar p" "$2" control.tar.gz | gzip -dc - > "$t"
        file2=".${file2:7}"
      else
        istemp "ar p" "$2" data.tar.gz | gzip -dc - > "$t"
      fi
      cmd=(istar "$t" "$file2")
    elif [[ "$1" = *Zip* || "$1" = *ZIP* ]] && cmd_exist unzip; then
      cmd=(istemp "unzip -avp" "$2" "$file2")
    elif [[ "$1" = *\ ar\ archive* ]]; then
      cmd=(istemp "ar p" "$2" "$file2")
    fi
    if [[ "$cmd" != "" ]]; then
      filen="$file2"
    fi
  fi
}


istar () {
  $tarcmd Oxf "$1" "$2" 2>/dev/null
}


istemp () {
  typeset prog
  typeset t
  prog="$1"
  t="$2"
  shift
  shift
  if [[ "$t" = - ]]; then
    t=$(nexttmp)
    cat > "$t"
  fi
  if [[ $# -gt 0 ]]; then
    $prog "$t" "$@" 2>/dev/null
  else
    $prog "$t" 2>/dev/null
  fi
}

nodash () {
  typeset prog
  prog="$1"
  shift
  if [[ "$1" = - ]]; then
    shift
    if [[ $# -gt 0 ]]; then
      $prog "$@" 2>/dev/null
    else
      $prog 2>/dev/null
    fi
  else
    $prog "$@" 2>/dev/null
  fi
}

isrpm () {
  if cmd_exist rpm2cpio && cmd_exist cpio; then
    typeset t
    if [[ "$1" = - ]]; then
      t=$(nexttmp)
      cat > "$t"
      set "$t" "$2"
    fi
    # setup $b as a batch file containing "$b.out"
    typeset b
    b=$(nexttmp)
    echo "$b.out" > "$b"
    # to support older versions of cpio the --to-stdout option is not used here
    rpm2cpio "$1"|cpio -i --quiet --rename-batch-file "$b" "$2"
    cat "$b.out"
  elif cmd_exist rpmunpack && cmd_exist cpio; then
    # rpmunpack will write to stdout if it gets file from stdin
    # extract file $2 from archive $1, assume that cpio is sufficiently new
    # (option --to-stdout existing) if rpmunpack is installed
    cat "$1" | rpmunpack | gzip -cd | cpio -i --quiet --to-stdout "$2"
  fi
}


if cmd_exist html2text || cmd_exist elinks || cmd_exist links || cmd_exist lynx || cmd_exist w3m; then
  PARSEHTML=yes
else
  PARSEHTML=no
fi
#parsexml () { nodash "elinks -dump -default-mime-type text/xml" "$1"; }
parsehtml () {
  if [[ "$PARSEHTML" = no ]]; then
    echo "==> No suitable tool for HTML parsing found, install one of html2text, elinks, links, lynx or w3m"
    return
  fi
}

isfinal() {
  typeset t
  if [[ "$3" = $sep$sep ]]; then
    cat "$2"
    return
  elif [[ "$3" = $sep* ]]; then
    cat "$2"
    return
  fi
  if [[ "$1" = *No\ such* ]]; then
    exit 1
  elif [[ "$1" = *directory* ]]; then
    # color requires -r or -R when calling less, not recommended
    typeset COLOR
    if [[ $(tput colors) -ge 8 && ("$LESS" = *-*r* || "$LESS" = *-*R*) ]]; then
      COLOR="--color=always"
    fi
    cmd="ls -lA $COLOR $2"
    if ! ls $COLOR > /dev/null 2>&1; then
      cmd="CLICOLOR_FORCE=1 ls -lA -G $2"
      if ! ls -lA -G > /dev/null 2>&1; then
        cmd="ls -lA $2"
      fi
    fi
    echo "==> This is a directory, showing the output of"
    echo $cmd
    eval $cmd
  elif [[ "$1" = *\ tar* || "$1" = *\	tar* ]]; then
    echo "==> use tar_file${sep}contained_file to view a file in the archive"
    $tarcmd tvf "$2"
  elif [[ "$1" = *roff* ]] && cmd_exist groff; then
    DEV=utf8
    if [[ $LANG != *UTF*8* && $LANG != *utf*8* ]]; then
      if [[ "$LANG" = ja* ]]; then
        DEV=nippon
      else
        DEV=latin1
      fi
    fi
    MACRO=andoc
    if [[ "$2" = *.me ]]; then
      MACRO=e
    elif [[ "$2" = *.ms ]]; then
      MACRO=s
    fi
    echo "==> append $sep to filename to view the nroff source"
    groff -s -p -t -e -T$DEV -m$MACRO "$2"
  elif [[ "$1" = *Debian* ]]; then
    echo "==> use Deb_file${sep}contained_file to view a file in the Deb"
    echo
    istemp "ar p" "$2" control.tar.gz | gzip -dc - | $tarcmd tvf - | sed -r 's/(.{48})\./\1control/'
    echo
    istemp "ar p" "$2" data.tar.gz | gzip -dc - | $tarcmd tvf -
  # do not display all perl text containing pod using perldoc
  #elif [[ "$1" = *Perl\ POD\ document\ text* || "$1" = *Perl5\ module\ source\ text* ]]; then
  elif [[ "$1" = *Perl\ POD\ document\ text* ]] && cmd_exist perldoc; then
    echo "==> append $sep to filename to view the perl source"
    istemp perldoc "$2"
  elif [[ "$1" = *\ script* ]]; then
    set "plain text" "$2"
  elif [[ "$1" = *text\ executable* ]]; then
    set "plain text" "$2"
  elif [[ "$1" = *executable* ]]; then
    echo "==> append $sep to filename to view the binary file"
    nodash strings "$2"
  elif [[ "$1" = *\ ar\ archive* ]]; then
    echo "==> use library${sep}contained_file to view a file in the archive"
    istemp "ar vt" "$2"
  elif [[ "$1" = *shared* ]] && cmd_exist nm; then
    echo "==> This is a dynamic library, showing the output of nm"
    istemp nm "$2"
  elif [[ "$1" = *Zip* || "$1" = *ZIP* ]] && cmd_exist unzip; then
    echo "==> use zip_file${sep}contained_file to view a file in the archive"
    istemp "unzip -lv" "$2"
  elif [[ "$PARSEHTML" = yes && "$1" = *HTML* ]]; then
    echo "==> append $sep to filename to view the HTML source"
    parsehtml "$2"
  elif [[ "$PARSEHTML" = yes && ("$1" = *OpenDocument\ [CHMPST]* || "$1" = *OpenOffice\.org\ 1\.x\ [CIWdgpst]*) ]] && cmd_exist unzip; then
    if cmd_exist sxw2txt; then
      echo "==> append $sep to filename to view the OpenOffice or OpenDocument source"
      istemp sxw2txt "$2"
    else
      echo "==> install at least sxw2txt from the lesspipe package to see plain text in openoffice documents"
    fi
  elif [[ "$1" = *bill\ of\ materials* ]] && cmd_exist lsbom; then
    echo "==> append $sep to filename to view the binary data"
    lsbom -p MUGsf "$2"
  elif [[ "$1" = *perl\ Storable* ]]; then
    echo "==> append $sep to filename to view the binary data"
    perl -MStorable=retrieve -MData::Dumper -e '$Data::Dumper::Indent=1;print Dumper retrieve shift' "$2"
  elif [[ "$1" = *UTF-8* ]] && cmd_exist iconv -c; then
    echo "==> append $sep to filename to view the UTF-8 encoded data"
    iconv -c -f UTF-8 "$2"
  elif [[ "$1" = *ISO-8859* ]] && cmd_exist iconv -c; then
    echo "==> append $sep to filename to view the ISO-8859 encoded data"
    iconv -c -f ISO-8859-1 "$2"
  elif [[ "$1" = *UTF-16* ]] && cmd_exist iconv -c; then
    echo "==> append $sep to filename to view the UTF-16 encoded data"
    iconv -c -f UTF-16 "$2"
  elif [[ "$1" = *Apple\ binary\ property\ list* ]] && cmd_exist plutil; then
    echo "==> append $sep to filename to view the binary data"
    plutil -convert xml1 -o - "$2"
  elif [[ "$1" = *data* ]]; then
    echo "==> append $sep to filename to view the $1 source"
    nodash strings "$2"
  else
    set "plain text" "$2"
  fi
  if [[ "$2" = - ]]; then
    cat
  fi  
}

IFS=$sep a="$@"
IFS=' '
if [[ "$a" = "" ]]; then
  if [[ "$0" != /* ]]; then
     pat=`pwd`/
  fi
  if [[ "$SHELL" = *csh ]]; then
    echo "setenv LESSOPEN \"|$pat$0 %s\""
  else
    echo "LESSOPEN=\"|$pat$0 %s\""
    echo "export LESSOPEN"
  fi
else
  # check for pipes so that "less -f ... <(cmd) ..." works properly
  [[ -p "$1" ]] && exit 1
  show "$a"
fi
