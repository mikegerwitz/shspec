#!/bin/bash
# Core expectations
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

[ -z $__INC_EXPECT_CORE ] || return
__INC_EXPECT_CORE=1

source expect/output.sh
source expect/env.sh


##
# Shorthand for bailing out on unrecognized clauses
shspec::bail-clause()
{
  local -r type="$1"
  local -r clause="$2"

  shspec::bail "unrecognized \`$type' clause: \`$2'"
}


##
# Asserts that at least the given argument shift count was provided
#
# The shift count is used to determine where shspec's arguments end and
# where the remainder clause begins; this ensures that shspec can continue
# to evolve in the future without BC breaks in properly designed expection
# handlers.
shspec::_chk-shiftn()
{
  local -ri expect="$1"
  local -ri given="$2"

  test "$given" -ge "$expect" || shspec::bail \
    "internal: expected shift of at least $expect, but given $given"
}


##
# Purely gramatical to make certain expectations flow more naturally when
# spoken
#
# For example, "to be silent".
shspec::expect::be() { shspec::proxy-to "$@"; }


##
# Basic success and failure (zero or non-zero exit code)
shspec::expect::succeed() { test "$1" -eq 0; }
shspec::expect::fail()    { test "$1" -ne 0; }


##
# Inverts the result of an expectation represented by the remainder clause
shspec::expect::not() { ! shspec::proxy-to "$@"; }

