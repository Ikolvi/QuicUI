cmake_minimum_required(VERSION 3.16)
project(quicui_codepush_tests)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Google Test
find_package(GTest REQUIRED)

# Include directories
include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR}/../src
  ${GTEST_INCLUDE_DIRS}
)

# Source files
set(SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/../src/codepush_loader.cc
  codepush_loader_test.cc
)

# Create test executable
add_executable(codepush_tests ${SOURCES})

# Link libraries
target_link_libraries(codepush_tests
  ${GTEST_LIBRARIES}
  ${GTEST_MAIN_LIBRARIES}
  pthread
)

# Enable testing
enable_testing()
add_test(
  NAME CodePushLoaderTests
  COMMAND codepush_tests
)

# Code coverage (optional)
if(ENABLE_COVERAGE)
  target_compile_options(codepush_tests PRIVATE --coverage)
  target_link_options(codepush_tests PRIVATE --coverage)
endif()

# Verbose output
set(CMAKE_VERBOSE_MAKEFILE ON)
