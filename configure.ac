## For use by automake and autoconf
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

AC_INIT([shspec], [0.0.1-dev], [mikegerwitz@gnu.org])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign])

AC_CHECK_PROGS(XXD, [xxd])
test "$XXD" || AC_MSG_ERROR([missing xxd])

# generate files from their *.in counterparts
AC_CONFIG_FILES([Makefile])
AC_OUTPUT

