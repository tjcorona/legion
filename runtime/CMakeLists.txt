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

set ( PACKAGE_LIB_DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
set ( PACKAGE_BIN_DESTINATION "${CMAKE_INSTALL_PREFIX}/bin")
set ( PACKAGE_INCLUDE_DESTINATION "${CMAKE_INSTALL_PREFIX}/include")

foreach (file ${runtime_HEADERS})
   install (FILES ${file} DESTINATION ${PACKAGE_INCLUDE_DESTINATION})
endforeach()

add_subdirectory(realm)
add_subdirectory(legion)
add_subdirectory(mappers)
