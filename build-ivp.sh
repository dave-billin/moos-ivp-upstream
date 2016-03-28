#!/bin/bash
#====================================================================
# This script builds IvP utilities and libraries in an out-of-source
# build.  Build artifacts (CMake files, etc.) are written to
# <SCRIPT_DIR>/build/MOOS, where SCRIPT_DIR indicates the directory
# where this script resides.  Similarly, all binaries (libraries, 
# executables) are written to <SCRIPT_DIR>/bin
#====================================================================
set -o nounset   # Disallow unset variables
set -o errexit   # Exit on error
#set -o xtrace    # Print commands as they are executed

_script_name="$(basename ${0})"
_script_dir="$(readlink -f $(dirname ${0}))"



#--------------------------------------------------------------------
# DESCRIPTION: Prints script usage and exits
#--------------------------------------------------------------------
print_usage_and_exit()
{
echo "
USAGE:  ${_script_name} [OPTIONS] [MAKE ARGS]

OPTIONS:
  --help, -h       Print usage info and exit
  --nodebug        Build without debug symbols
  --noopt          Build with no compiler optimizations
  --fast, -f       Build without optimization or debug symbols
  --nogui, -n      Do not build GUI-related apps
  --minrobot, -m   Build only minimal robot apps (smaller than --nogui)
  --purge, -p      Remove existing build artifacts before building

By default, all code is built, and the debug and optimization
compiler flags are invoked.

Note: By default -j12 is provided to make to utilize up to 12
      processors in the build. This can be overridden simply
      by using -j1 on the command line instead. This will give
      more reasonable output if there should be a build error.
"
    exit 1
}


#===================================
# Parse command line arguments
#===================================
purge_requested='no'
BUILD_DEBUG="yes"  
BUILD_OPTIM="yes"
CMD_ARGS=
BUILD_GUI_CODE="ON"
BUILD_BOT_CODE_ONLY="OFF"

for ARGI; do
   case ${ARGI} in
      --help|-h)
           print_usage_and_exit;;

      --nodebug)
           BUILD_DEBUG="no";;

      --noopt)
           BUILD_OPTIM="no";;

      --fast|-f)
           BUILD_DEBUG="no"
           BUILD_OPTIM="no";;

      --purge|-p)
           purge_requested='yes';;

      --nogui|-n)
           BUILD_GUI_CODE="no";;

      --minrobot|-m)
           BUILD_BOT_CODE_ONLY="ON"
           BUILD_GUI_CODE="OFF";;

      *)   set +o nounset
           if [ -z "${CMD_ARGS}" ]
           then
              CMD_ARGS+=" ${ARGI}"
           else
              CMD_ARGS=$CMD_ARGS" "$ARGI
           fi
           set -o nounset;;
   esac
done

################################################################################
CMAKE_CXX_FLAGS="-Wall -Wno-long-long -pedantic -Wunreachable-code -Wmissing-declarations -fPIC"
if [ ${BUILD_DEBUG} = "yes" ] ; then
    CMAKE_CXX_FLAGS=$CMAKE_CXX_FLAGS" -g"
fi
if [ ${BUILD_OPTIM} = "yes" ] ; then
    CMAKE_CXX_FLAGS=$CMAKE_CXX_FLAGS" -O3"
fi



################################################################################
# For back compatability, if user has environment variable IVP_BUILD_GUI_CODE 
# set to "OFF" then honor it here as if --nogui were set on the command line

set +o nounset
if [ "${IVP_BUILD_GUI_CODE}" = "OFF" ] ; then
    BUILD_GUI_CODE="OFF"
    echo "IVP GUI Apps will not be built. IVP_BUILD_GUI_CODE env var is OFF"
fi
set -o nounset



################################################################################
_build_dir="${_script_dir}/build/IvP"
_bin_dir="${_script_dir}/bin"
_lib_dir="${_script_dir}/lib"
_ivp_src_dir="${_script_dir}/ivp/src"

echo "
Compiler flags: ${CMAKE_CXX_FLAGS}
BUILD_GUI_CODE = ${BUILD_GUI_CODE}
BUILD_BOT_CODE_ONLY: ${BUILD_BOT_CODE_ONLY}

Build artifacts will be written to the following directories:
Intermediate build files: ${_build_dir}
Libraries:                ${_lib_dir}
Programs:                 ${_bin_dir}
"

# Create build and output directories
mkdir -p "${_build_dir}"
mkdir -p "${_lib_dir}"
mkdir -p "${_bin_dir}"


# Implement purge
if [ "${purge_requested}" = 'yes' ]
then
    echo "Purging build artifacts in '${_build_dir}'"
    (cd ${_build_dir} && make clean) || true
    rm -rf ${_build_dir}
    exit 0
else
   (
   cd ${_build_dir}
   echo "Configuring CMake..."
   cmake -DIVP_BUILD_GUI_CODE=${BUILD_GUI_CODE} \
         -DIVP_BUILD_BOT_CODE_ONLY=${BUILD_BOT_CODE_ONLY} \
         -DIVP_LIB_DIRECTORY="${_lib_dir}" \
         -DIVP_BIN_DIRECTORY="${_bin_dir}" \
         -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
         -DUSE_UTM=ON \
         "${_ivp_src_dir}" \
            >/dev/null
 
#         -DPROJ4_INCLUDE_SEARCH_PATHS="${_script_dir}/MOOS/proj-4.8.0" \
#         -DPROJ4_LIBRARY_SEARCH_PATHS="${_lib_dir}" \
   echo "Running 'make ${CMD_ARGS}'"
   make -j12 ${CMD_ARGS}
   )
fi

