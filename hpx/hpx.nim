#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
{.deadCodeElim: on.}
{.experimental: "dynamicBindSym".}
{.passC: gorge("pkg-config --cflags hwloc hpx_application").}
{.passL: gorge("pkg-config --libs hwloc hpx_application").}
{.passL: "-lhpx_iostreams -lhpx_component_storage -lhpx_partitioned_vector -lhpx_unordered".}

{.emit: """
#include <hpx/config.hpp>
#define HPX_COMPUTE_HOST_CODE
#include <hpx/hpx_main.hpp>
#include <hpx/logging/manipulator.hpp>
#include <hpx/logging/format/destinations.hpp>
#include <hpx/iostream.hpp>
#include <hpx/include/actions.hpp>
#include <hpx/include/components.hpp>
#include <hpx/include/lcos.hpp>
#include <hpx/include/parallel_executors.hpp>
#include <hpx/include/runtime.hpp>
#include <hpx/include/util.hpp>
#include <hpx/include/partitioned_vector.hpp>
#include <hpx/modules/actions_base.hpp>
#include <hpx/modules/executors.hpp>
#include <hpx/modules/algorithms.hpp>
#include <hpx/modules/async_distributed.hpp>
#include <hpx/modules/executors_distributed.hpp>
#include <hpx/iostream.hpp>
#include <mutex>
#include <cassert>

using namespace hpx;
using namespace hpx::lcos;
using namespace hpx::lcos::local;
using namespace hpx::naming;
using namespace hpx::execution;

using std_lock_guard = std::lock_guard<hpx::lcos::local::spinlock>;

void find_all_localities_ptr(size_t value, hpx::id_type * iidents) {
    std::vector<hpx::id_type> idents = hpx::find_all_localities();
    assert(idents.size() == value);
    for(std::size_t i = 0; i < value; ++i) {
        (*(iidents+i)) = idents[i];
    }
}

""".}

import std/macros

proc plain_action_code(n : NimNode) : NimNode =
    result = newStmtList()
    let fnname : string = $name(n)
    let val : string = "HPX_PLAIN_ACTION(" & $fnname & ", " & $fnname & "_action)"
    var newn = n.copy
    newn.addPragma(newIdentNode("cdecl"))
    newn.addPragma(newNimNode(nnkExprColonExpr).add(
            newIdentNode("exportc"),
            newLit($fnname)))

    result.add(newn)
    result.add( parseStmt("{.emit : [\"" & val & "\"].}") )

macro plain_action*(n : typed) : untyped = n.plain_action_code

template register_partitioned_seq*(V:typedesc) =
    {.emit: ["""HPX_REGISTER_PARTITIONED_VECTOR(""", V,""")"""].}

template register_unordered_map*(K : typedesc, V:typedesc) =
    {.emit: ["""HPX_REGISTER_UNORDERED_MAP(""", K, """,""", V,""")"""].}

type
   id_type* {.importcpp: "hpx::id_type", header: "<hpx/naming_base/id_type.hpp>".} = object
   gid_type* {.importcpp: "hpx::naming::gid_type", header: "<hpx/naming_base/gid_type.hpp>".} = object

   spinlock* {.importcpp: "hpx::locs::local::spinlock".} = object
   lockguard* {.importcpp: "std_lock_guard".} = object

   future*[V] {.importcpp: "hpx::future<'0>", header: "<hpx/future.hpp>".} = object

   partitioned_seq*[V] {.importcpp: "hpx::partitioned_vector<'0>", header: "<hpx/include/partitioned_vector.hpp>".} = object
   unordered_map*[K, V] {.importcpp: "hpx::unordered_map<'0, '1>", header: "<hpx/include/unordered_map.hpp>".} = object

   container_distribution* {.importcpp: "hpx::container_distribution_policy", header: "<hpx/modules/distribution_policies.hpp>".} = object

   sequenced_policy* {.importcpp: "hpx::execution::sequenced_policy", header: "<hpx/modules/executors.hpp>".} = object
   parallel_policy* {.importcpp: "hpx::execution::parallel_policy", header: "<hpx/modules/executors.hpp>".} = object
   parallel_unsequenced_policy* {.importcpp: "hpx::execution::parallel_unsequenced_policy", header: "<hpx/modules/executors.hpp>".} = object
   unsequenced_policy* {.importcpp: "hpx::execution::unsequenced_policy", header: "<hpx/modules/executors.hpp>".} = object

var seq_exec* {.importcpp: "hpx::execution::seq", header: "<hpx/modules/executors.hpp>".} : sequenced_policy
var par_exec* {.importcpp: "hpx::execution::par", header: "<hpx/modules/executors.hpp>".} : parallel_policy
var par_seq_exec* {.importcpp: "hpx::execution::par_seq", header: "<hpx/modules/executors.hpp>".} : parallel_unsequenced_policy
var unseq_exec* {.importcpp: "hpx::execution::unseq", header: "<hpx/modules/executors.hpp>".} : unsequenced_policy

type SomeExecutionPolicy* = sequenced_policy | parallel_policy | parallel_unsequenced_policy | parallel_unsequenced_policy

##########
# id_type
#
proc gid*(self : id_type) : gid_type {.importcpp: "#.get_gid()", header : "<hpx/naming_base/gid_type.hpp>".}

##########
# gid_type
#
proc msb*(self : gid_type) : uint64 {.importcpp: "#.get_msb()", header : "<hpx/naming_base/gid_type.hpp>".}
proc lsb*(self : gid_type) : uint64 {.importcpp: "#.get_lsb()", header : "<hpx/naming_base/gid_type.hpp>".}

##########
# future[V]
#
proc get*[V](self : future[V]) : V {.importcpp: "#.get()", header : "<hpx/future.hpp>".}

#[
# https://gist.github.com/oltolm/1738289b5ac866ec6a7e4ef20095178e
# https://gist.github.com/fowlmouth/48f3340b797c12cb3043
# https://web.mit.edu/nim-lang_v0.16.0/nim-0.16.0/doc/manual/pragmas.txt
# https://scripter.co/binding-nim-to-c-plus-plus-std-list/
# https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma
#
# dynamically generate the import for async using a macro
# template async*(fn, args : varargs[expr]) : stmt =
]#

proc newContainerDistribution*(seg : int) : container_distribution {.importcpp: "hpx::container_layout(#, hpx::find_all_localities())", header: "<hpx/modules/distribution_policies.hpp>".}

##########
# partitioned_seq
# 
proc newPartitionedSeq*[V]() : partitioned_seq[V] {.importcpp: "{}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newPartitionedSeq*[V](count : int) : partitioned_seq[V] {.importcpp: "{@}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newPartitionedSeq*[V](count : int, ini: V) : partitioned_seq[V] {.importcpp: "{@}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newPartitionedSeq*[V](count : int, ini : V, dist : container_distribution) : partitioned_seq[V] {.importcpp: "{#, #, #}", header : "<hpx/include/partitioned_vector.hpp>".}

proc register_as_impl[V](self : partitioned_seq[V], symbolic_name : cstring) : future[void] {.importcpp: "#.register_as(std::string{@})", header : "<hpx/include/partitioned_vector.hpp>".}

proc register_as*[V](self : partitioned_seq[V], symbolic_name : string) : future[void] =
    result = register_as_impl[V](self, cstring(symbolic_name))

proc connect_to_impl[V](self : partitioned_seq[V], symbolic_name : cstring) : future[void] {.importcpp: "#.connect_to(std::string{@})", header : "<hpx/include/partitioned_vector.hpp>".}

proc connect_to*[V](self : partitioned_seq[V], symbolic_name : string) : future[void] =
    result = connect_to_impl[V](self, cstring(symbolic_name))

proc get_num_partitions*[V](self : partitioned_seq[V]) : csize_t {.importcpp: "#.get_num_partitions()", header : "<hpx/include/partitioned_vector.hpp>".}

proc get_value*[V](self : partitioned_seq[V], pos : int) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}
proc get_value*[V](self : partitioned_seq[V], part : int, pos : int) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}

proc set_value*[V](self : partitioned_seq[V], pos : int, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}
proc set_value*[V](self : partitioned_seq[V], part : int, pos : int, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}

proc size*[V](self : partitioned_seq[V]) : csize_t {.importcpp: "#.size()", header: "<hpx/include/partitioned_vector.hpp>".}

proc `[]`*[V](self : partitioned_seq[V], pos : int) : V {.importcpp: "#[@]", header: "<hpx/include/partitioned_vector.hpp>".}

##########
# unordered_map
# 
proc newUnorderedMap*[K,V]() : unordered_map[K,V] {.importcpp: "{}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newUnorderedMap*[K,V](count : int) : unordered_map[K,V] {.importcpp: "{@}", header : "<hpx/include/partitioned_vector.hpp>".}

proc register_as_impl[K, V](self : unordered_map[K, V], symbolic_name : cstring) : future[void] {.importcpp: "#.register_as(std::string{@})", header : "<hpx/include/unordered_map.hpp>".}

proc register_as*[K,V](self : unordered_map[K,V], symbolic_name : string) : future[void] =
    result = register_as_impl[K,V](self, cstring(symbolic_name))

proc connect_to_impl[K, V](self : unordered_map[K, V], symbolic_name : cstring) : future[void] {.importcpp: "#.connect_to(std::string{@})", header : "<hpx/include/unordered_map.hpp>".}

proc connect_to*[K,V](self : unordered_map[K,V], symbolic_name : string) : future[void] =
    result = connect_to_impl[K,V](self, cstring(symbolic_name))

proc get_num_partitions*[K,V](self : unordered_map[K,V]) : csize_t {.importcpp: "#.get_num_partitions()", header : "<hpx/include/unordered_map.hpp>".}

proc get_value*[K,V](self : unordered_map[K,V], pos : K) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/unordered_map.hpp>".}
proc get_value*[K,V](self : unordered_map[K,V], part : int, pos : K) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/unordered_map.hpp>".}

proc set_value*[K,V](self : unordered_map[K,V], pos : K, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/unordered_map.hpp>".}
proc set_value*[K,V](self : unordered_map[K,V], part : int, pos : K, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/unordered_map.hpp>".}

proc `[]`*[K,V](self : unordered_map[K,V], pos : K) : V {.importcpp: "#[@]", header: "<hpx/include/unordered_map.hpp.hpp>".}

proc erase*[K,V](self : unordered_map[K,V], pos : K) : future[csize_t] {.importcpp: "#.erase(@)", header: "<hpx/include/unordered_map.hpp>".}

proc size*[K,V](self : unordered_map[K,V]) : csize_t {.importcpp: "#size()", header: "<hpx/include/unordered_map.hpp>".}
proc size_async*[K,V](self : unordered_map[K,V]) : future[csize_t] {.importcpp: "#size_async()", header: "<hpx/include/unordered_map.hpp>".}

##########
# get runtime information
#
proc get_worker_thread_num*() : csize_t {.importcpp: "hpx::get_worker_thread_num", header: "<hpx/runtime_local/get_worker_thread_num.hpp>".}
proc get_os_thread_count*()   : csize_t {.importcpp: "hpx::get_os_thread_count", header: "<hpx/runtime_local/get_worker_thread_num.hpp>".}
proc get_locality_id*()       : cuint {.importcpp: "hpx::get_locality_id", header: "<hpx/runtime_local/get_locality_id.hpp>".}
proc get_num_localities*()    : future[cuint] {.importcpp: "hpx::get_num_localities", header: "<hpx/runtime_local/runtime_local.hpp>".}

proc find_all_localities_impl(sz : csize_t, idents : ptr id_type) {.importcpp: "find_all_localities_ptr(@)", header: "<hpx/runtime_local/get_num_all_localities.hpp>".}

template `+`(p: ptr id_type, off: int): ptr id_type =
  cast[ptr type(p[])]( cast[ByteAddress](p) +% (off * sizeof(p[])) )

template `[]`(p: ptr id_type, off: int): id_type =
  (p + off)[]

proc find_all_localities*() : seq[id_type] =
   var numl = get_num_localities()
   var sz : csize_t = csize_t(numl.get())
   result = newSeq[id_type](sz)
   find_all_localities_impl(sz, result[0].addr)

##########
# parallel algorithms
#
# proc par_foreachn_impl[V]( vals : ptr V, n : int, fn : proc(v: var V) {.cdecl.} ) {.importcpp: "hpx::for_each_n(par, #, #, #)", header : "hpx/modules/algorithms.hpp".}
#
# proc par_foreach*[V]( vals : var openArray[V], fn : proc(v: var V) {.cdecl.} ) = 
#     par_foreachn_impl[V](cast[ptr V](vals[0].addr), vals.len, fn)
#
# proc par_foreach_n*[V]( vals : var openArray[V], n : int, fn : proc(v: var V) {.cdecl.} ) = 
#     par_foreachn_impl[V](cast[ptr V](vals[0].addr), n, fn)
#
# proc seq_foreachn_impl[V]( vals : ptr V, n : int, fn : proc(v: var V) {.cdecl.} ) {.importcpp: "hpx::for_each_n(seq, #, #, #)", header : "hpx/modules/algorithms.hpp".}
#
# proc seq_foreach*[V]( vals : var openArray[V], fn : proc(v: var V) {.cdecl.} ) = 
#     seq_foreachn_impl[V](cast[ptr V](vals[0].addr), vals.len, fn)
#
# proc seq_foreach_n*[V]( vals : var openArray[V], n : int, fn : proc(v: var V) {.cdecl.} ) = 
#     seq_foreachn_impl[V](cast[ptr V](vals[0].addr), n, fn)
#

proc foreachn_impl[V]( policy : SomeExecutionPolicy, vals : ptr V, n : int, fn : proc(v: var V) {.cdecl.} ) {.importcpp: "hpx::for_each_n(#, #, #, #)", header : "hpx/modules/algorithms.hpp".}

proc foreach*[V]( policy : SomeExecutionPolicy, vals : var openArray[V], fn : proc(v: var V) {.cdecl.} ) =
    foreachn_impl[V](policy, cast[ptr V](vals[0].addr), vals.len, fn)

proc foreach_n*[V]( policy : SomeExecutionPolicy, vals : var openArray[V], n : int, fn : proc(v: var V) {.cdecl.} ) =
    foreachn_impl[V](policy, cast[ptr V](vals[0].addr), n, fn)

##########
# asynchronous function execution
#
proc async*(fn : proc() {.cdecl.}) : future[void] {.importcpp : "hpx::async(@)", header: "<hpx/hpx.hpp>".}
proc async*[V](fn : proc() : V {.cdecl.}) : future[V] {.importcpp : "hpx::async(@)", header: "<hpx/hpx.hpp>".}
