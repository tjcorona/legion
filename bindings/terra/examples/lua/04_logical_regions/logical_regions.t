-- Copyright 2015 Stanford University
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

require("legionlib")

-- This example shows how to create index
-- spaces, field spaces, and logical regions.
-- It also shows how to dynamically allocate
-- and free elements in index spaces and fields
-- in field spaces.

TOP_LEVEL_TASK_ID = 0

FID_FIELD_A = 0
FID_FIELD_B = 1

function top_level_task(task, reigons, ctx, runtime)
  -- Logical regions are the core abstraction of data in Legion.
  -- Constructing a logical region involves specifying an index
  -- space and a field space.  We describe how to create these
  -- building blocks first and then show how to create logical
  -- regions from them.

  -- Index spaces are the abstraction in Legion that is used to
  -- describe the row entries in a logical region.  There are two
  -- kinds of index spaces in Legion: unstructured and structured.
  -- Both are created using the 'create_index_space' runtime
  -- call with different parameters.  Both types are represented
  -- by the same IndexSpace type.  Unstructured index spaces are
  -- created by specifying the context and the maximum number of
  -- elements that may be allocated in the index space.  We note
  -- that specifying the upper bound on elements is mildly
  -- restrictive but it significantly simplifies and improves
  -- performance of our runtime implementation.  Furthermore most
  -- programmers usually have an approximation of how big their
  -- data sets are, or can at least approximate it based on some
  -- input parameter.  If you have a sufficiently complex example
  -- which requires an unbounded number of elements we would be
  -- interested in learning more.  Here we create an unstructured
  -- index space that will store at most 1024 elements.
  local unstructured_is = runtime:create_index_space(ctx, 1024)
  printf("Created unstructured index space %x", unstructured_is.id)

  -- We create structured index spaces from Rects which we
  -- convert to Domains (recall example 02).
  local rect = Rect:new(Point:new{0}, Point:new{1023})
  local structured_is = runtime:create_index_space(ctx,
                                  Domain:from_rect(rect))
  printf("Created structured index space %x", structured_is.id)

  -- Structured index spaces by default already have all their
  -- points allocated and they cannot be allocated or deallocated.
  -- Unstructured index spaces must have their elements allocated
  -- using an index space allocator.  Allocators can be used to
  -- allocate or free elements.  They return ptr_t elements which
  -- are Legion's untyped pointer type.  These are opaque pointers
  -- which have no data associated with them.  They can only be
  -- dereferenced using physical instances of logical regions which
  -- store actual data (covered in a later example).  Here we create
  -- an allocator for our unstructured index space and allocate all of
  -- its points.
  do
    local allocator = runtime:create_index_allocator(ctx, unstructured_is)
    local begin = allocator:alloc(1024)
    assert(not begin:is_null())
    printf("Allocated elements in unstructured space at ptr_t %d", begin.value)
    -- When done using the allocator, users should call the 'delete' method
    -- to reclaim resources the allocator was using.
  end

  -- For structured index spaces we can always recover the original
  -- domain for an index space from the runtime.
  local orig_domain = runtime:get_index_space_domain(ctx, structured_is)
  local orig = orig_domain:get_rect()
  assert(orig == rect)

  -- Fields spaces are the abstraction that Legion uses for describing
  -- the column entries in a logical region.  Field spaces are created
  -- using the 'create_field_space' call.
  local fs = runtime:create_field_space(ctx)
  printf("Created field space %x", fs.id)
  -- Fields can be dynamically allocated and destroyed in fields spaces
  -- using field allocators.  For performance reasons there is a compile-time
  -- upper bound placed on the maximum number of fields that can be
  -- allocated in a field space at a time (see 'MAX_FIELDS' at the
  -- top of legion_types.h).  If a program exceeds this maximum then
  -- the Legion runtime will report an error and exit.
  do
    local allocator = runtime:create_field_allocator(ctx, fs)
    -- When fields are allocated they must specify the size of the data
    -- to be stored in the field in bytes.  Users may also optionally
    -- specify the ID for the field being allocated.  If this is done,
    -- the user is responsible for ensuring that each field ID is used
    -- only once for a each field space.  Legion support parallel allocation
    -- of fields in the same field space, but it will result in undefined
    -- behavior if two fields are allocated in the same field space at
    -- the same time with the same user provided ID.
    local fida = allocator:allocate_field(sizeof(double), FID_FIELD_A)
    assert(fida == FID_FIELD_A)
    local fidb = allocator:allocate_field(sizeof(int), FID_FIELD_B)
    assert(fidb == FID_FIELD_B)
    printf("Allocated two fields with Field IDs %d and %d", fida, fidb)
  end

  -- Logical regions are created by passing an index space and a field
  -- space to the 'create_logical_region' runtime method.  Note that
  -- both structured and unstructured index spaces can be used.
  -- Note that we use the same field space for both logical regions
  -- which means they both will have the same set of fields.  Any
  -- modifications to the field space will effect both logical regions.
  local unstructured_lr =
    runtime:create_logical_region(ctx, unstructured_is, fs)
  printf("Created unstructured logical region (%x,%x,%x)",
         unstructured_lr:get_index_space().id,
         unstructured_lr:get_field_space().id,
         unstructured_lr:get_tree_id())
  local structured_lr =
    runtime:create_logical_region(ctx, structured_is, fs)
  printf("Created structured logical region (%x,%x,%x)",
         structured_lr:get_index_space().id,
         structured_lr:get_field_space().id,
         structured_lr:get_tree_id())

  -- Note that logical regions are not uniquely defined by index spaces
  -- and field spaces.  Every call to create_logical_region with the
  -- same index space and field space will return a new logical region
  -- with a different tree ID.
  local no_clone_lr =
    runtime:create_logical_region(ctx, structured_is, fs)
  assert(not (structured_lr:get_tree_id() ==
              no_clone_lr:get_tree_id()))

  -- In the next example we'll show how to create physical instances
  -- of logical regions and how to access data.
  --
  -- The runtime also supports operations for destroying index spaces,
  -- field spaces, and logical regions.  Since Legion operates with
  -- a deferred execution model, the runtime is smart enough to know
  -- how to defer these deletions until they are safe to perform which
  -- means the user does not need to worry about waiting for tasks that
  -- use these resources before destroying them.
  runtime:destroy_logical_region(ctx, unstructured_lr)
  runtime:destroy_logical_region(ctx, structured_lr)
  runtime:destroy_logical_region(ctx, no_clone_lr)
  runtime:destroy_field_space(ctx, fs)
  runtime:destroy_index_space(ctx, unstructured_is)
  runtime:destroy_index_space(ctx, structured_is)
  print("Successfully cleaned up all of our resources")
end

function legion_main(arg)
  legion:set_top_level_task_id(TOP_LEVEL_TASK_ID)
  legion:register_lua_task_void("top_level_task",
    TOP_LEVEL_TASK_ID, legion.LOC_PROC, true,  false)
  legion:start(arg)
end

if rawget(_G, "arg") then
  legion_main(arg)
end
