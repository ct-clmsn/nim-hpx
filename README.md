<!-- Copyright (c) 2022 Christopher Taylor                                          -->
<!--                                                                                -->
<!--   Distributed under the Boost Software License, Version 1.0. (See accompanying -->
<!--   file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)        -->
# [nim-hpx - STE||AR HPX wrapper for Nim](https://github.com/ct-clmsn/nim-hpx)

[Nim](https://nim-lang.org) is a system language emphasizing productivity. [STE||AR HPX](https://github.com/STEllAR-GROUP/hpx)
is a high performance computing (HPC)/supercomputing runtime
system.

Nim developers can implement HPC applications targeting single
node/multicore systems and distributed memory systems (multi-node/multicore
systems). `nim-hpx` exposes STE||AR HPX's asynchronous
global address space and parallelism feature set.

### Supports

* futures
* local asynchronous function execution
* parallel algorithms (foreach, etc)
* partitioned sequences

### TODO

* promises
* remote asynchronous function execution (50%)
* more parallel algorithms (reduce, transform, etc)
* collective communications

### Installation Requirements

Dependencies:

* pkg-config
* cmake
* hwloc
* papi
* APEX
* tcmalloc
* boost
* STE||AR HPX

### Application compilation

* make sure all dependencies are installed
* update `PKG_CONFIG_PATH` making sure it points to `hpx_applications.pc` (usually `$(HPX_INSTALL_DIR)/lib/pkgconfig`)
* modify the `makefile` provided to compile the test program suite

### Running Programs

```
srun -n4 --mpi=pmi2 ./test_initfin
```

This library is designed to be run on an HPC system that manages
jobs using the following workload managers: [Slurm](https://slurm.schedmd.com), PBS, etc.

### Examples

The directory 'tests/' provides several examples regarding how to utilize this library.

### Licenses

* Boost Version 1.0 (2022-)

### Date

20 April 2022

### Author

Christopher Taylor

### Special Thanks

* The STE||AR HPX Group
* The Nim community

### Dependencies

* [STE||AR HPX](https://github.com/STEllAR-GROUP/hpx)
* [nim 1.6.4](https://nim-lang.org)
