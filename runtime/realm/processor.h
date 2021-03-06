/* Copyright 2015 Stanford University, NVIDIA Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// processors for Realm

#ifndef REALM_PROCESSOR_H
#define REALM_PROCESSOR_H

#include "lowlevel_config.h"

#include "event.h"

#include <vector>
#include <map>

namespace Realm {

    typedef unsigned int AddressSpace;

    class ProfilingRequestSet;

    class Processor {
    public:
      typedef ::legion_lowlevel_id_t id_t;

      id_t id;
      bool operator<(const Processor& rhs) const { return id < rhs.id; }
      bool operator==(const Processor& rhs) const { return id == rhs.id; }
      bool operator!=(const Processor& rhs) const { return id != rhs.id; }

      static const Processor NO_PROC;

      bool exists(void) const { return id != 0; }

      typedef ::legion_lowlevel_task_func_id_t TaskFuncID;
      typedef void (*TaskFuncPtr)(const void *args, size_t arglen, Processor proc);
      typedef std::map<TaskFuncID, TaskFuncPtr> TaskIDTable;

      // Different Processor types
      // Keep this in sync with legion_processor_kind_t in lowlevel_config.h
      enum Kind {
        TOC_PROC = ::TOC_PROC, // Throughput core
        LOC_PROC = ::LOC_PROC, // Latency core
        UTIL_PROC = ::UTIL_PROC, // Utility core
        IO_PROC = ::IO_PROC, // I/O core
        PROC_GROUP = ::PROC_GROUP, // Processor group
      };

      // Return what kind of processor this is
      Kind kind(void) const;
      // Return the address space for this processor
      AddressSpace address_space(void) const;
      // Return the local ID within the address space
      id_t local_id(void) const;

      static Processor create_group(const std::vector<Processor>& members);
      void get_group_members(std::vector<Processor>& members);

      // special task IDs
      enum {
        // Save ID 0 for the force shutdown function
	TASK_ID_REQUEST_SHUTDOWN   = 0,
	TASK_ID_PROCESSOR_INIT     = 1,
	TASK_ID_PROCESSOR_SHUTDOWN = 2,
	TASK_ID_FIRST_AVAILABLE    = 4,
      };

      Event spawn(TaskFuncID func_id, const void *args, size_t arglen,
		  Event wait_on = Event::NO_EVENT, int priority = 0) const;

      // Same as the above but with requests for profiling
      Event spawn(TaskFuncID func_id, const void *args, size_t arglen,
                  const ProfilingRequestSet &requests,
                  Event wait_on = Event::NO_EVENT, int priority = 0) const;

      static Processor get_executing_processor(void);
    };

    inline std::ostream& operator<<(std::ostream& os, Processor p) { return os << std::hex << p.id << std::dec; }
	
}; // namespace Realm

#include "processor.inl"

#endif // ifndef REALM_PROCESSOR_H

