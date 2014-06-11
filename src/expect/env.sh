#!/bin/bash
# Environment expectations
#
#  Copyright (C) 2014 Mike Gewitz
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

[ -z $__INC_EXPECT_ENV ] || return
__INC_EXPECT_ENV=1


##
# Expect that an environment variable is set to a particular value
#
# The variable need not be exported.
#
_expect--set()
{
  local -ri shiftn="$2"
  local -r  envpath="$4"
  shift "$shiftn"

  # ensure envpath is available
  __chk-shiftn 4 "$shiftn"

  local -r var="$1" cmp="$2"
  shift 2
  local -r expect="$@"

  # TODO: support escaped newlines; use awk (do not source the file)
  local -r line="$( grep "^declare \.*-- $var=" "$envpath" )"
  local -r valq="${line##*=\"}"
  local -r val="${valq%%\"}"

  # cannot quote regex without causing problems, and [[ syntax does not
  # allow a variable comparison operator; further, argument order varies
  # with certain operators; whitelist to explicitly document support and
  # prevent oddities
  case "$cmp" in
    =~)
      [[ "$val" =~ $expect ]];;

    -[nz])
      test "$cmp" "$val";;

    =|==|!=|-eq|-ne|-lt|-le|-gt|-ge)
      test "$val" $cmp "$expect";;

    *) false;;
  esac
}


##
# Alias for `set`
#
_expect--declare()
{
  _expect--set "$@"
}

