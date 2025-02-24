### If you want to edit this, copy it from cmake/share to cmake. It will be
### picked up in preference over the one in cmake/share. And it will not get
### clobbered with the next upgrade.

cmake_minimum_required( VERSION 3.13)

#
# MEMO this may have to run multiple times for multiple executables!
#
   if( MULLE_TRACE_INCLUDE)
      message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
   endif()

   if( NOT EXECUTABLE_NAME)
      set( EXECUTABLE_NAME "${PROJECT_NAME}")
   endif()

   #
   # need this for .aam projects
   #
   set_target_properties( "${EXECUTABLE_NAME}"
      PROPERTIES LINKER_LANGUAGE C
   )

   #
   # only for mulle-clang
   #
   message( STATUS "considering --export_dynamic")
   if( UNIX AND NOT (APPLE OR COSMOPOLITAN OR MUSL_STATIC_ONLY))
      message( STATUS "considering --export_dynamic if in link")
      if( LINK_PHASE)
         message( STATUS "set --export_dynamic for \"${EXECUTABLE_LINK_TARGET}\"")
         target_link_options( "${EXECUTABLE_LINK_TARGET}"
            PUBLIC
               "SHELL:LINKER:--export-dynamic"
         )
         message( STATUS "added --export-dynamic")
      else()
         message( STATUS "but not in link")
      endif()
   else()
         message( STATUS "but right system")
   endif()

   if( APPLE AND MULLE_OBJC)
      if( LINK_PHASE)
         target_link_options( "${EXECUTABLE_LINK_TARGET}"
            PUBLIC
               "SHELL:LINKER:-exported_symbol,___register_mulle_objc_universe"
         )
         message( STATUS "added -exported_symbol")

         if( MULLE_TEST)
            target_link_options( "${EXECUTABLE_LINK_TARGET}"
               PUBLIC
                  "SHELL:LINKER:-exported_symbol,__mulle_atinit"
                  "SHELL:LINKER:-exported_symbol,_mulle_atexit"
            )
            message( STATUS "added two more -exported_symbol")
         endif()
      endif()
   endif()

   include( ExecutableAuxObjC OPTIONAL)

