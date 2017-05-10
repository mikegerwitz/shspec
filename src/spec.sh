#!/bin/bash
# Specification language
#
#  Copyright (C) 2014, 2017 Mike Gerwitz
#
#  This file is part of shspec.
#
#  shspec is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Upon examining this code, you will likely notice that it is not
# re-entrant. This is okay, because the intended use is to invoke a new
# process *per specification*, not to run multiple specifications
# concurrently within the same process.
#
# You've been warned.
##

[ -z $__INC_SPEC ] || return
__INC_SPEC=1

source specstack.sh
source expect.sh

# number of internal arguments before remainder clause
declare -ir __SHIFTN=4


##
# Attempts to make tempoary path in /dev/shm, falling back to default
shspec:__mktemp-shm()
{
  local -r shm=/dev/shm
  [ -d $shm -a -r $shm ] && mktemp -p$shm || mktemp
}


# std{out,err} file
readonly __spec_outpath="$(shspec:__mktemp-shm)"
readonly __spec_errpath="$(shspec:__mktemp-shm)"

# env dump file
readonly __spec_envpath="$(shspec:__mktemp-shm)"

# most recent expect result exit code
declare -i __spec_rexit=0

# most recent caller for expectations
declare __spec_caller=


##
# Begin a new specification definition
#
# A specification is any shell script using the specification commands
# defined herein.
shspec:begin-spec()
{
  : placeholder
}


##
# Mark the end of a specification
#
# If the specification was improperly nested, this will output a list of
# nesting errors and return a non-zero error. Otherwise, nothing is done.
shspec:end-spec()
{
  # if the stack is empty then everything is in order
  shspec:stack:_empty && return 0

  # otherwise, output an error message for each item in the stack
  until shspec:stack:_empty; do
    shspec:stack:_read type line file _ < <(shspec:stack:_head)
    shspec:stack:_pop
    echo "error: unterminated \`$type' at $file:$line"
  done

  return 1
}


##
# Begin describing a SUT
#
# All arguments are used as the description of the SUT (but remember that,
# even though the DSL makes it look like plain english, shell quoting and
# escaping rules still apply!).
describe()
{
  local -r desc="$*"
  shspec:stack:_push "describe" $(caller) "$desc"
}


##
# Declare a fact
#
# Like `describe', the entire argument list is used as the fact description.
it()
{
  local -r desc="$*"
  shspec:stack:_push "it" $(caller) "$desc"
}


##
# End the nearest declaration
#
# Note that some declarations (such as `expect') are implicitly closed and
# should not use this command.
end()
{
  local -r head="$(shspec:stack:_head-type)"
  local -r cleanhead="$head"

  # some statements are implicitly terminated; explicitly doing so is
  # indicitive of a syntax issue
  [ "${head:0:1}" != : ] \
    || shspec:bail \
      "unexpected \`end': still processing \`$cleanhead'" $(caller)

  shspec:stack:_pop >/dev/null || shspec:bail "unmatched \`end'"
}


##
# Declare the premise of an expectation
#
# All arguments are interpreted to be the command line to execute for the
# test. The actual expectations that assert upon this declaration are
# defined by `to'.
#
# That is, this declares "given this command, I can expect that..."
expect()
{
  shspec:stack:_assert-within it expect $(caller)
  ( "$@" >"$__spec_outpath" 2>"$__spec_errpath" )
  __spec_rexit=$?
  shspec:stack:_push :expect $(caller) "$@"
}


##
# Declare expectations
#
# This declares an expectation on the immediately preceding expectation
# premise.
to()
{
  __spec_caller=${__spec_caller:-$(caller)}

  [ $# -gt 0 ] || \
    shspec:bail "missing assertion string for \`to'" $__spec_caller

  shspec:stack:_assert-follow :expect to $(caller)
  shspec:stack:_pop

  shspec:__handle-to "$__spec_rexit" $__SHIFTN \
    "$__spec_errpath" "$__spec_envpath" "$@" \
    || fail "$*"

  __spec_caller=
}


##
# Perform expectation assertion by invoking expectation handler
#
# Will throw an error if the handler cannot be found. Arguments are expected
# to be of the following form:
#
#   <exit code> <shiftn> <...N> <expect type> <...remainder clause>
#
shspec:__handle-to()
{
  local -ri rexit="$1"
  local -ri shiftn="$2"
  local -r errpath="$( [ $shiftn -gt 2 ] && echo "$3" )"
  local -r envpath="$( [ $shiftn -gt 3 ] && echo "$4" )"
  shift "$shiftn"

  local -r type="$1"
  shift

  local -r assert="shspec:expect:$type"
  type "$assert" &>/dev/null \
    || shspec:bail "unknown expectation: \`$type'" $__spec_caller

  # first argument is exit code, second is the number of arguments to shift
  # to place $1 at the remainder clause, third is the path to the stderr
  # output file, and all remaining arguments are said remainder clause; the
  # shift argument allows the implementation to vary without breaking BC so
  # long as the meaning of the shifted arguments do not change
  $assert $rexit $__SHIFTN "$errpath" "$envpath" "$@" \
    < "$__spec_outpath"
}


##
# Alias for _handle-to
#
# Shows intent to proxy a call and allows proxy implementation to vary.
shspec:proxy-to() { shspec:__handle-to "$@"; }


##
# Declares additional expectations for the preceding premise
and()
{
  __spec_caller="$(caller)"

  # the most recently popped value should be an expect premise, implying
  # that an expectation declaration implicitly popped it
  shspec:stack:_unpop
  shspec:stack:_assert-within :expect and $(caller) \
    "follow an expectation as part of"

  "$@"
}


##
# Outputs failure details and exits
#
# TODO: This is a temporary implementation; we would like to list all
# failures, and the actual display shall be handled by a reporter, not by
# us. This function will ultimately, therefore, simply collect data for
# later processing.
fail()
{
  echo "expected to $*" >&2

  echo '  stdout:'
  sed 's/^/    /g' < <( xxd < "$__spec_outpath" )
  echo
  echo '  stderr:'
  sed 's/^/    /g' < <( xxd < "$__spec_errpath" )
  echo
  echo "  exit code: $__spec_rexit"

  echo
  shspec:bail "expectation failure"
}


##
# Something went wrong; immediately abort processing with an error
#
# This should only be used in the case of a specification parsing error or
# other fatal errors; it should not be used for failing expectations.
#
# If no file and line number are provided, this will default to the current
# spec caller, if any.
shspec:bail()
{
  local -r msg="$1"
  local line="$2"
  local file="$3"

  # default to current caller if no line/file was provided
  if [ -z "$file" -a -n "$__spec_caller" ]; then
    read line file <<< "$__spec_caller"
  fi

  echo -n "error: $msg" >&2
  [ -n "$file" ] && echo -n " at $file:$line" >&2

  echo >&2
  exit 1
}

