#!/bin/bash
# Output expectations
#
#  Copyright (C) 2014 Mike Gerwitz
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
##

[ -z $__INC_EXPECT_OUTPUT ] || return
__INC_EXPECT_OUTPUT=1

source util.sh

# reserved for our uses
exec 99<>/dev/null


##
# Generic output expectation processing
#
# This provides a generic facility for processing output on stdout or
# stderr, supporting `on std(err|out)' clauses.
#
# First processes remainder clause for common sub-clauses; any
# expectation-specific sub-clauses should therefore be processed and
# stripped beforehand to prevent errors.
#
# Assuming clause validity, determines (based on the clause) whether to
# assert against stdout or stderr, and then invokes the provided command
# line with an additional parameter representing the user-supplied
# comparison argument; stdout/stderr input is provided via stdin.
#
# This command is successful if and only if both the remainder clause and
# the provided command line complete successfully.
shspec::expect::__output-cmd()
{
  local -r cmd="$1"
  shift

  local -ri shiftn="$2"
  local -r stderr="$3"
  shift "$shiftn"

  # output-specific clauses
  local -r cmp="$1"
  shift
  local -ar clause=("$@")

  local nl
  local intype
  {
    shspec::expect::__output-clause "${clause[@]}" | {
      IFS=\| read nl intype

      if [ "$intype" == stderr ]; then
        shspec::_chk-shiftn 3 "$shiftn"
        exec 99<"$stderr"
      fi

      $cmd "$cmp" <&99 &>/dev/null
    }
  } 99<&0

  aok "${PIPESTATUS[@]}"
}

# parses output remainder clause according to the aforementioned rules
shspec::expect::__output-clause()
{
  [ $# -gt 0 ] || return 0

  local input=

  if [ $# -gt 0 ]; then
    if [[ "$1 $2" =~ ^on\ std(err|out) ]]; then
      [ "$2" == stderr ] && input="$2"
    else
      shspec::bail-clause output "$*"
    fi
  fi

  echo "$nl|$input"
}


##
# Expect that the given string is output on stdout or stderr
#
# Defaults to asserting against stdout; behavior may be overridden with the
# `on stderr' clause. Specifying `on stdout' may be used for clarity, but is
# redundant.
#
# This expectation assumes a trailing newline by default; this behavior can
# be suppressed with the `without newline' clause.
shspec::expect::output()
{
  local -a args=("$@")
  local -i shiftn="$2"
  shift "$shiftn"
  local -r cmp="$1"
  shift
  local nl

  if [ $# -gt 0 ]; then
    # this is not a common clause; process before generic parsing
    if [ "$1 $2" == 'without newline' ]; then
      nl=-n
      unset args[$shiftn+1], args[$shiftn+2]
    fi
  fi

  shspec::expect::__output-cmd "shspec::expect::__output-do -$nl" \
    "${args[@]}"
}

shspec::expect::__output-do()
{
  local -r nl="${1:1}"
  local -r cmp="$2"

  # we will eventually be interested in this output
  # TODO: fast check first, diff if non-match
  diff <( echo $nl "$cmp" ) -
}


##
# Expects that stdout matches the provided extended regular expression (as
# in regex(3))
shspec::expect::match()
{
  shspec::expect::__output-cmd 'shspec::expect::__match-do' "$@"
}

shspec::expect::__match-do()
{
  local -r pat="$1"
  [[ "$(cat)" =~ $pat ]]
}


##
# Expects that both stdin and stderr (if available) are empty
shspec::expect::silent()
{
  local -r stderr="${3:-/dev/null}"
  shift "$2"

  # we accept no arguments
  test $# -eq 0 || shspec::bail-clause silent "$*"

  # quick read using builtins; if we find any single byte, then we know that
  # it is non-empty
  read -N1 || read -N1 <"$stderr" || return 0
  return 1
}
