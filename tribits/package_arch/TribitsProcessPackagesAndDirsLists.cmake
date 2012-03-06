# @HEADER
# ************************************************************************
#
#            Trilinos: An Object-Oriented Solver Framework
#                 Copyright (2001) Sandia Corporation
#
#
# Copyright (2001) Sandia Corporation. Under the terms of Contract
# DE-AC04-94AL85000, there is a non-exclusive license for use of this
# work by or on behalf of the U.S. Government.  Export of this program
# may require a license from the United States Government.
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the Corporation nor the names of the
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY SANDIA CORPORATION "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL SANDIA CORPORATION OR THE
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# NOTICE:  The United States Government is granted for itself and others
# acting on its behalf a paid-up, nonexclusive, irrevocable worldwide
# license in this data to reproduce, prepare derivative works, and
# perform publicly and display publicly.  Beginning five (5) years from
# July 25, 2001, the United States Government is granted for itself and
# others acting on its behalf a paid-up, nonexclusive, irrevocable
# worldwide license in this data to reproduce, prepare derivative works,
# distribute copies to the public, perform publicly and display
# publicly, and to permit others to do so.
#
# NEITHER THE UNITED STATES GOVERNMENT, NOR THE UNITED STATES DEPARTMENT
# OF ENERGY, NOR SANDIA CORPORATION, NOR ANY OF THEIR EMPLOYEES, MAKES
# ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL LIABILITY OR
# RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY
# INFORMATION, APPARATUS, PRODUCT, OR PROCESS DISCLOSED, OR REPRESENTS
# THAT ITS USE WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
#
# ************************************************************************
# @HEADER


INCLUDE(SetCacheOnOffEmpty)
INCLUDE(MultilineSet)
INCLUDE(AdvancedOption)
INCLUDE(TribitsListHelpers)


#
# Helper functions
#

MACRO(TRIBITS_ALLOW_MISSING_EXTERNAL_PACKAGES)
  FOREACH(TRIBITS_PACKAGE ${ARGN})
    SET(${TRIBITS_PACKAGE}_ALLOW_MISSING_EXTERNAL_PACKAGE TRUE)
  ENDFOREACH()
ENDMACRO()



#
# Below, we change the value of user cache values like
# ${PROJECT_NAME}_ENABLE_${PACKAGE_NAME},
# ${PACKAGE_NAME}_ENABLE_TESTS, and ${PACKAGE_NAME}_ENABLE_EXAMPLES by
# just setting them to regular variables that live in the top scope
# instead of putting them back in the cache.  That means that they are
# used as global variables but we don't want to disturb the cache
# since that would change the behavior for future invocations of cmake
# (which is very confusing).  Because of this, these macros must all
# be called from the top-level ${PROJECT_NAME} CMakeLists.txt file and
# macros must call macros as not to change the variable scope.
#
# I had to do it this way in order to be able to get the right behavior which
# is:
#
# 1) Override the value of these variables in all CMake processing
#
# 2) Avoid changing the user cache values because that would be confusing and
# would make it hard to change package enables/disable later without blowing
# away the cache
# 


#
# Macro that sets up standard user options for each package
#

MACRO(TRIBITS_INSERT_STANDARD_PACKAGE_OPTIONS  PACKAGE_NAME  PACKAGE_CLASSIFICATION)

  #MESSAGE("TRIBITS_INSERT_STANDARD_PACKAGE_OPTIONS: ${PACKAGE_NAME} ${PACKAGE_CLASSIFICATION}")

  IF (${PACKAGE_CLASSIFICATION} STREQUAL PS OR ${PACKAGE_CLASSIFICATION} STREQUAL SS) 
    #MESSAGE("PS or SS")
    SET(PACKAGE_ENABLE "")
  ELSEIF (${PACKAGE_CLASSIFICATION} STREQUAL EX)
    #MESSAGE("EX")
    SET(PACKAGE_ENABLE OFF)
  ELSE()
    MESSAGE(FATAL_ERROR "Error the package classification '${PACKAGE_CLASSIFICATION}'"
      " for the package ${PACKAGE_NAME} is not a valid classification." )
  ENDIF()
  #PRINT_VAR(PACKAGE_ENABLE)

  IF (NOT ${PACKAGE_NAME}_CLASSIFICATION) # Allow testing override
    SET(${PACKAGE_NAME}_CLASSIFICATION "${PACKAGE_CLASSIFICATION}")
  ENDIF()

  MULTILINE_SET(DOCSTR
    "Enable the package ${PACKAGE_NAME}.  Set to 'ON', 'OFF', or leave"
    " empty to allow for other logic to decide."
    )
  SET_CACHE_ON_OFF_EMPTY( ${PROJECT_NAME}_ENABLE_${PACKAGE_NAME}
    "${PACKAGE_ENABLE}" ${DOCSTR} )

ENDMACRO()


#
# Function that determines if it is okay to allow an implicit package enable
# based on its classification.
#

FUNCTION(TRIBITS_IMPLICIT_PACKAGE_ENABLE_IS_ALLOWED PACKAGE_NAME_IN
  IMPLICIT_PACKAGE_ENABLE_ALLOWED_OUT
  )
  IF (${PACKAGE_NAME_IN}_CLASSIFICATION STREQUAL PS)
    SET(IMPLICIT_PACKAGE_ENABLE_ALLOWED TRUE)
  ELSEIF (${PACKAGE_NAME_IN}_CLASSIFICATION STREQUAL SS
    AND ${PROJECT_NAME}_ENABLE_SECONDARY_STABLE_CODE
    )
    SET(IMPLICIT_PACKAGE_ENABLE_ALLOWED TRUE)
  ELSE()
    SET(IMPLICIT_PACKAGE_ENABLE_ALLOWED FALSE)
  ENDIF()
  SET(${IMPLICIT_PACKAGE_ENABLE_ALLOWED_OUT} ${IMPLICIT_PACKAGE_ENABLE_ALLOWED}
    PARENT_SCOPE )
ENDFUNCTION()


#
# Macro that processes ${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS into
# ${PROJECT_NAME}_PACKAGES, ${PROJECT_NAME}_PACKAGE_DIRS, ${PROJECT_NAME}_NUM_PACKAGES,
# ${PROJECT_NAME}_LAST_PACKAGE_IDX, and ${PROJECT_NAME}_REVERSE_PACKAGES.
#
# This macro also sets up the standard package options along with
# default enables/disables.
#

MACRO(TRIBITS_PROCESS_PACKAGES_AND_DIRS_LISTS  REPOSITORY_NAME  REPOSITORY_DIR)

  #MESSAGE("TRIBITS_PROCESS_PACKAGES_AND_DIRS_LISTS:  '${REPOSITORY_NAME}'  '${REPOSITORY_DIR}'")

  #
  # Separate out separate lists of package names and directoires
  #

  # Get the total number of packages defined  

  ASSERT_DEFINED(${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS)
  #PRINT_VAR(${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS)
  LIST(LENGTH ${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS
    ${REPOSITORY_NAME}_NUM_PACKAGES_AND_FIELDS )
  MATH(EXPR ${REPOSITORY_NAME}_NUM_PACKAGES
    "${${REPOSITORY_NAME}_NUM_PACKAGES_AND_FIELDS}/${PLH_NUM_FIELDS_PER_PACKAGE}")
  #PRINT_VAR(${REPOSITORY_NAME}_NUM_PACKAGES)
  MATH(EXPR ${REPOSITORY_NAME}_LAST_PACKAGE_IDX "${${REPOSITORY_NAME}_NUM_PACKAGES}-1")
 
  # Process each of the packages defined

  IF (${REPOSITORY_NAME}_NUM_PACKAGES GREATER 0)
  
    FOREACH(PACKAGE_IDX RANGE ${${REPOSITORY_NAME}_LAST_PACKAGE_IDX})
  
      #PRINT_VAR(${PROJECT_NAME}_PACKAGES)
  
      MATH(EXPR PACKAGE_NAME_IDX "${PACKAGE_IDX}*${PLH_NUM_FIELDS_PER_PACKAGE}+0")
      LIST(GET ${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS
        ${PACKAGE_NAME_IDX} TRIBITS_PACKAGE )
      #PRINT_VAR(TRIBITS_PACKAGE)
  
      MATH(EXPR PACKAGE_DIR_IDX
        "${PACKAGE_IDX}*${PLH_NUM_FIELDS_PER_PACKAGE}+${PLH_NUM_PACKAGE_DIR_OFFSET}")
      LIST(GET ${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS
        ${PACKAGE_DIR_IDX} PACKAGE_DIR )
      #PRINT_VAR(PACKAGE_DIR)
  
      MATH(EXPR PACKAGE_CLASSIFICATION_IDX
        "${PACKAGE_IDX}*${PLH_NUM_FIELDS_PER_PACKAGE}+${PLH_NUM_PACKAGE_CLASSIFICATION_OFFSET}")
      LIST(GET ${REPOSITORY_NAME}_PACKAGES_AND_DIRS_AND_CLASSIFICATIONS
        ${PACKAGE_CLASSIFICATION_IDX} PACKAGE_CLASSIFICATION )
      #PRINT_VAR(PACKAGE_CLASSIFICATION)
  
      IF ("${REPOSITORY_DIR}" STREQUAL ".")
        SET(REPOSITORY_DIR_SEP "")
      ELSE()
        SET(REPOSITORY_DIR_SEP "${REPOSITORY_DIR}/")
      ENDIF()
      #PRINT_VAR(REPOSITORY_DIR_SEP)
  
      SET(PACKAGE_ABS_DIR "${PROJECT_SOURCE_DIR}/${REPOSITORY_DIR_SEP}${PACKAGE_DIR}")
      #PRINT_VAR(PACKAGE_ABS_DIR)
  
      IF (EXISTS ${PACKAGE_ABS_DIR})
        SET(PACKAGE_EXISTS TRUE)
      ELSE()
        SET(PACKAGE_EXISTS FALSE)
      ENDIF()
  
      IF (${PROJECT_NAME}_ASSERT_MISSING_PACKAGES AND NOT PACKAGE_EXISTS)
        MESSAGE(
          "\n***"
          "\n*** Error, the package ${TRIBITS_PACKAGE} directory ${PACKAGE_ABS_DIR} does not exist!"
          "\n***\n" )
        MESSAGE(FATAL_ERROR "Stopping due to above error!")
      ENDIF()
  
      IF (PACKAGE_EXISTS OR ${PROJECT_NAME}_IGNORE_PACKAGE_EXISTS_CHECK)
        LIST(APPEND ${PROJECT_NAME}_PACKAGES ${TRIBITS_PACKAGE})
        LIST(APPEND ${PROJECT_NAME}_PACKAGE_DIRS "${REPOSITORY_DIR_SEP}${PACKAGE_DIR}")
        TRIBITS_INSERT_STANDARD_PACKAGE_OPTIONS(${TRIBITS_PACKAGE} ${PACKAGE_CLASSIFICATION})
        SET(${TRIBITS_PACKAGE}_PARENT_PACKAGE "")
      ELSE()
        IF (${PROJECT_NAME}_VERBOSE_CONFIGURE)
          MESSAGE(
            "\n***"
            "\n*** WARNING: Excluding package ${TRIBITS_PACKAGE} because ${PACKAGE_ABS_DIR}"
              " does not exist!"
            "\n***\n" )
        ENDIF()
      ENDIF()
  
      #PRINT_VAR(${PROJECT_NAME}_PACKAGES)
  
    ENDFOREACH()
  
    # Get the actual number of packages that actually exist
  
    LIST(LENGTH ${PROJECT_NAME}_PACKAGES ${PROJECT_NAME}_NUM_PACKAGES )
    MATH(EXPR ${PROJECT_NAME}_LAST_PACKAGE_IDX "${${PROJECT_NAME}_NUM_PACKAGES}-1")
    
    # Create a reverse list for later use
    
    SET(${PROJECT_NAME}_REVERSE_PACKAGES ${${PROJECT_NAME}_PACKAGES})
    LIST(REVERSE ${PROJECT_NAME}_REVERSE_PACKAGES)

  ELSE()

    SET(${REPOSITORY_NAME}_NUM_PACKAGES 0)

  ENDIF()

  IF (${PROJECT_NAME}_VERBOSE_CONFIGURE)
    PRINT_VAR(${REPOSITORY_NAME}_NUM_PACKAGES)
  ENDIF()

  PRINT_VAR(${PROJECT_NAME}_NUM_PACKAGES)
  
  # Print the final set of packages in debug mode

  IF (${PROJECT_NAME}_VERBOSE_CONFIGURE)
    PRINT_VAR(${PROJECT_NAME}_PACKAGES)
    PRINT_VAR(${PROJECT_NAME}_PACKAGE_DIRS)
  ENDIF()

ENDMACRO()
