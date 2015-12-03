#!/usr/bin/env bash

make_module() {
  # Reset OPTIND so that getopts invocations don't conflict
  unset OPTIND
  # Set fallback values
  module_prefix="/no/prefix/given" 
  output_file="/dev/stdout"
  module_name="no_name"
  variables_to_import=""
  variables_to_append=""
  variables_to_prepend=""
  module_whatis="This is a module for ${module_name}."
  module_conflicts=""
  module_prereqs=""
  send_help_and_quit="n"

  #Get command line arguments
  while getopts  "hp:o:n:v:a:e:w:c:r:d" flag
  do
    case "$flag" in
      "p")
        module_prefix="$OPTARG"
        ;;
      "o")
        output_file="$OPTARG"
        ;;
      "d")
        omit_normal_block="y"
        ;;
      "v")
        printf -v variables_to_import "%s\nsetenv %s" "$variables_to_import" "${OPTARG/=/ }"
        ;;
      "a")
        printf -v variables_to_append "%s\nappend-path %s" "$variables_to_append" "${OPTARG/:/ }"
        ;;
      "e")
        printf -v variables_to_prepend "%s\nprepend-path %s" "$variables_to_prepend" "${OPTARG/:/ }"
        ;;
      "w")
        module_whatis="$OPTARG"
        ;;
      "c")
        printf -v module_conflicts "%s\nconflict %s" "$module_conflicts" "$OPTARG"
        ;;
      "r")
        printf -v module_prereqs "%s\nprereq %s" "$module_prereqs" "$OPTARG"
        ;;
      "h")
        send_help_and_quit="y"
        ;;
      *)
        echo "Invalid argument specified." >&2
        exit 5
        ;;
    esac
  done

  module_maker_help_file="module_maker_inc.sh: makes modules

  In shell, so as to not add extra dependencies.

  Options:
    -p   prefix dir: allows quick configuration of all \$prefix/bin, \$prefix/lib paths
    -o   where to write modulefile -- directories will be created if necessary
    -n   module name
    -v   variables to set, as \"variable=value\". Use multiple times if nec.
    -a   variables to append, as \"variable:value\". Ditto.
    -e   variables to prepend, as \"variable:value\". Ditto.
    -w   module whatis information. A brief description.
    -c   modules this module conflicts with. Space separate, quote.
    -r   modules this module depends on. Space separate, quote.
    -h   print this.
  "

  #Send the help message and exit if -h was specified.
  if [[ "$send_help_and_quit" == "y" ]]; then
    echo -e "$module_maker_help_file"
    exit
  fi

  #Extra output variables
  user=$(whoami)
  date=$(date +"%Y-%m-%d %H:%M:%S %z")

  #Create dir for module if necessary
  mkdir -p $(dirname $output_file)

  cat >$output_file <<EOF
#%Module -*- tcl -*-
##
## $module_name
##
## generated by $user on $date
## using cmd line:
##  "$@"

proc ModulesHelp { } {

  puts stderr {${module_whatis}}

}

module-whatis {${module_whatis}}
${module_prereqs}
${module_conflicts}

set              prefix               $module_prefix
${variables_to_import}${variables_to_prepend}${variables_to_append}
EOF

if [ -z "$omit_normal_block" ]; then
cat >>$output_file <<EOF

prepend-path        CMAKE_PREFIX_PATH    \$prefix

if { [file isdirectory \$prefix/bin] } then {
  prepend-path      PATH                 \$prefix/bin
}

if { [file isdirectory \$prefix/man] } then {
  prepend-path      MANPATH              \$prefix/man
}

if { [file isdirectory \$prefix/share/man] } then {
  prepend-path      MANPATH              \$prefix/share/man
}

if { [file isdirectory \$prefix/lib] } then {
  prepend-path      LIBRARY_PATH         \$prefix/lib
  prepend-path      LD_LIBRARY_PATH      \$prefix/lib
}

if { [file isdirectory \$prefix/lib64] } then {
  prepend-path      LIBRARY_PATH         \$prefix/lib64
  prepend-path      LD_LIBRARY_PATH      \$prefix/lib64
}

if { [file isdirectory \$prefix/lib/pkgconfig] } then {
  prepend-path      PKG_CONFIG_PATH      \$prefix/lib/pkgconfig
}

if { [file isdirectory \$prefix/include] } then {
  prepend-path      CPATH                \$prefix/include
  prepend-path      INCLUDE_PATH         \$prefix/include
}

EOF
fi

}

if [ "$(basename $0)" == "module_maker_inc.sh" ]; then
  make_module "$@"
fi
