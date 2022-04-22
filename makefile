#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
LIBDIR=
INCDIR=

ifeq ($(LIBDIR),)
    $(error LIBDIR is not set)
endif

ifeq ($(INCDIR),)
    $(error INCDIR is not set)
endif

CFLAGS=-std=c++17

all:
	nim cpp --clibdir:$(LIBDIR) -d:danger -d:globalSymbols --cincludes:$(INCDIR) --passC:"$(CFLAGS)" tests/test_initfin.nim
	mv tests/test_initfin .

clean:
	rm test_initfin
