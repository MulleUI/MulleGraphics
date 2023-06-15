cmake_minimum_required( VERSION 3.15)

project( demos C)

#
# Turn an "Executable" into a "Library"
# * mulle-sde test init
# * mv src/main.m test/10_test/test.m
# Then set MULLE_PROJECT_TYPE to "Library".
# * mulle-sde reflect
# * mulle-sde test
#
set( MULLE_PROJECT_TYPE "Executable")

### mulle-sde environment

# add cmake module paths to search path
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/share")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/reflect")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake")

include( Environment)

include( Files)

include( Dependencies OPTIONAL)

# remove this, we have freeglut or ?
list( REMOVE_ITEM OS_SPECIFIC_LIBRARIES ${GLU_LIBRARY})

foreach( MAIN_SOURCE ${SOURCES})
   # get rid off src/main- prefix and .m suffix
   #             offset 9  length -9 - 2
   string( LENGTH "${MAIN_SOURCE}" MAIN_SOURCE_LENGTH)
   math( EXPR MAIN_SOURCE_LENGTH "${MAIN_SOURCE_LENGTH} - 11")
   string( SUBSTRING "${MAIN_SOURCE}" 9 ${MAIN_SOURCE_LENGTH} EXECUTABLE_NAME)

   set( SOURCES ${MAIN_SOURCE})
#   set( OTHER_EXECUTABLE_OBJECT_FILES $<TARGET_OBJECTS:MulleUI>)

   include( Executable)

   if( UNIX)
      message( STATUS "is UNIX")
   endif()
   if( NOT (APPLE OR COSMOPOLITAN OR MUSL_STATIC_ONLY))
      if( UNIX)
         message( STATUS "is glibc")
      endif()
   endif()

   if( LINK_PHASE)
      target_link_options( "${EXECUTABLE_LINK_TARGET}"
         PUBLIC
            "SHELL:LINKER:--export-dynamic"
      )
   endif()

   include( InstallExecutable)
   include( FinalOutput OPTIONAL)
# only for Executable
   include( Motd OPTIONAL)
endforeach()

