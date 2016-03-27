#!/bin/bash
#====================================================================
# This script builds the MOOS and proj4 libraries in an out-of-source
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

_build_dir="${_script_dir}/build/MOOS"
_bin_dir="${_script_dir}/bin"


cmake_build_type="RelWithDebInfo"
cmd_args=

for ARGI; do
    case ${ARGI} in
       --help|-h)
          printf "%s [SWITCHES]  \n" $0
          printf "  --help, -h                                   \n"
          printf "  --debug, -d                                  \n"
          printf "  --release, -r                                \n"
          printf "Any other switches passed directly to \"make\" \n"
          printf "Recommended:                                   \n"
          printf " -j12   Speed up compile on multi-core machines. \n"
          printf " -k     Keep building after failed component.    \n"
          printf " clean  Clean/remove any previous build.         \n"
          exit 0;;
   
      --debug|-d)
          cmake_build_type="Debug";;
   
      --release|-r)
          cmake_build_type="Release";;
   
      clean)
          echo "Cleaning..."
          rm -rf ${_build_dir}/* >/dev/null;;
   
      *) cmd_args+="${ARGI}";;
   esac
done


bar="================================================================"

# Determine host platform
build_platform=
case $(uname) in
   Darwin) build_platform="Apple";;
   *) build_platform="Linux"
esac

echo "
${bar}
Building MOOS for ${build_platform}
CMake build type is '${cmake_build_type}'
${bar}
"


# Set up the build directory
mkdir -p ${_build_dir}

 

cmake_build_args=( 
                   "-DCMAKE_BUILD_TYPE=${cmake_build_type}"
                   "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${_bin_dir}"
                   "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${_bin_dir}"
                   "-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY=${_bin_dir}"
                 )


#===================================================================
# Part #1:  BUILD CORE
#===================================================================
moos_core_dir="${_script_dir}/MOOS/MOOSCore"
moos_core_build_dir="${_build_dir}/MOOSCore"
echo "${bar}
***  Building MOOSCore  ***
${bar}"
(
mkdir -p ${moos_core_build_dir}
cd ${moos_core_build_dir}
echo "Configuring CMake..."
cmake ${cmake_build_args[@]} \
      -DENABLE_EXPORT=ON \
      -DUSE_ASYNC_COMMS=ON \
      -DTIME_WARP_AGGLOMERATION_CONSTANT=0.4 \
      ${moos_core_dir} >/dev/null

echo "
Invoking make..."
make ${cmd_args}
)


#===================================================================
# Part #2:  BUILD ESSENTIALS
#===================================================================
moos_essentials_dir="${_script_dir}/MOOS/MOOSEssentials"
moos_essentials_build_dir="${_build_dir}/MOOSEssentials"
echo -e "\n\n
${bar}
***  Building MOOSEssentials  ***
${bar}"
(
mkdir -p ${moos_essentials_build_dir}
cd ${moos_essentials_build_dir}
echo "Configuring CMake..."
cmake ${cmake_build_args[@]} \
      ${moos_essentials_dir} \
         >/dev/null

echo "
Invoking make..."
make ${cmd_args}
)


#===================================================================
# Part #3:  BUILD MOOS GUI TOOLS
#===================================================================
moos_gui_tools_dir="${_script_dir}/MOOS/MOOSToolsUI"
moos_gui_tools_build_dir="${_build_dir}/MOOSToolsUI"
echo -e "\n\n
${bar}
***  Building MOOS GUI Tools  ***
${bar}"
(
mkdir -p ${moos_gui_tools_build_dir}
cd ${_build_dir}
echo "Configuring CMake..."
cmake -DBUILD_CONSOLE_TOOLS=ON \
      -DBUILD_GRAPHICAL_TOOLS=ON \
      -DBUILD_UPB=ON \
      ${cmake_build_args[@]} \
      ${moos_gui_tools_dir} \
         >/dev/null

echo "
Invoking make..."
make ${cmd_args}
)


#===================================================================
# Part #4:  BUILD PROJ4
#===================================================================
libproj4_dir="${_script_dir}/MOOS/proj-4.8.0"
libproj4_build_dir="${_build_dir}/libproj4"
echo -e "\n\n
${bar}
***  Building libproj4  ***
${bar}"
(
mkdir -p ${libproj4_build_dir}
cd ${libproj4_build_dir}

if [ -e lib/libproj.dylib ] && \
   [ -e lib/libproj.a ] 
then
   echo "Using system libproj4"
else
   echo "Building libproj4 from included sources"
   echo "Configuring libproj4..."
   ${libproj4_dir}/configure \
      --exec-prefix='' \
      --libexecdir=${_bin_dir} \
      --libdir=${_bin_dir} \
      --bindir=${_bin_dir} \
         >/dev/null
   echo -e "Building libproj4..."
   make ${cmd_args} >/dev/null
   echo -e "Installing libproj4 in the build tree..."
   make install >/dev/null
fi
)


#===================================================================
# Part #5:  BUILD MOOS GEODESY
#===================================================================
moos_geodesy_dir="${_script_dir}/MOOS/MOOSGeodesy"
moos_geodesy_build_dir="${_build_dir}/MOOS/MOOSGeodesy"
echo -e "\n\n
${bar}
***  Building MOOSGeodesy  ***
${bar}"

(
mkdir -p ${moos_geodesy_build_dir}
cd ${moos_geodesy_build_dir}
echo "Configuring CMake..."
cmake -DPROJ4_INCLUDE_DIRS="${libproj4_dir}/include;${libproj4_build_dir}/include" \
      -DPROJ4_LIB_PATH=${_bin_dir} \
      -DENABLE_EXPORT=ON \
      ${cmake_build_args} \
      ${moos_geodesy_dir} \
         >/dev/null

echo "
Invoking make..."
make ${cmd_args}
)

echo -e "\n\nMOOS libraries were built successfully"
echo "Binaries have been written to '${_bin_dir}'"
exit 0

