#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Package
version       = "0.0.1"
author        = "Christopher Taylor"
description   = "nim-hpx a STE||AR HPX wrapper"
license       = "boost"

# Dependencies
requires "nim >= 0.18.0"

backend = "cpp"
requires "cppstl"
requires "jsony"

task gendoc, "Generate documentation":
  exec("nimble doc --project hpx.nim --out:docs/")
