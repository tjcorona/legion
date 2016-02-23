set(runtime_HEADERS
  lowlevel.h
  lowlevel_impl.h
  accessor.h
  lowlevel_config.h
  activemsg.h
  arrays.h
  atomics.h
  common.h
  lowlevel_dma.h
  utilities.h
  lowlevel_dma.inl
  )

set(runtime_SOURCES
  activemsg.cc
  lowlevel_disk.cc
  shared_lowlevel.cc
  lowlevel.cc
  lowlevel_dma.cc
  )

#add_library(runtime ${runtime_SOURCES})
#target_include_directories(runtime
#  PRIVATE
#    ${CMAKE_SOURCE_DIR}/runtime
#    ${CMAKE_SOURCE_DIR}/runtime/legion
#    ${CMAKE_SOURCE_DIR}/runtime/realm)

set ( PACKAGE_LIB_DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
set ( PACKAGE_BIN_DESTINATION "${CMAKE_INSTALL_PREFIX}/bin")
set ( PACKAGE_INCLUDE_DESTINATION "${CMAKE_INSTALL_PREFIX}/include")

#install(TARGETS runtime EXPORT legion_TARGETS
#  ARCHIVE DESTINATION ${PACKAGE_LIB_DESTINATION}
#  LIBRARY DESTINATION ${PACKAGE_LIB_DESTINATION}
#  RUNTIME DESTINATION ${PACKAGE_BIN_DESTINATION}
#)

foreach (file ${runtime_HEADERS})
   install (FILES ${file} DESTINATION ${PACKAGE_INCLUDE_DESTINATION})
endforeach()

add_subdirectory(realm)
add_subdirectory(legion)
add_subdirectory(mappers)
