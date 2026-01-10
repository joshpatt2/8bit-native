cmake_minimum_required(VERSION 3.20)
project(8bit-native LANGUAGES CXX OBJCXX)

# C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable testing
enable_testing()

# Find SDL2
find_package(SDL2 REQUIRED)

# Find Apple frameworks
find_library(METAL_FRAMEWORK Metal REQUIRED)
find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)
find_library(COCOA_FRAMEWORK Cocoa REQUIRED)

# Source files
set(SOURCES
    src/main.mm
    src/engine/Renderer.mm
    src/engine/Shader.mm
    src/engine/Texture.mm
    src/engine/FrameTimer.cpp
    src/engine/SpriteBatch.mm
)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${SDL2_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/src
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    ${SDL2_LIBRARIES}
    ${METAL_FRAMEWORK}
    ${QUARTZCORE_FRAMEWORK}
    ${COCOA_FRAMEWORK}
)

# Objective-C++ flags for .mm files
set_source_files_properties(
    src/main.mm
    src/engine/Renderer.mm
    src/engine/Shader.mm
    src/engine/Texture.mm
    PROPERTIES COMPILE_FLAGS "-x objective-c++"
)

# Copy shaders to build directory
file(COPY ${CMAKE_SOURCE_DIR}/shaders DESTINATION ${CMAKE_BINARY_DIR})

# Copy assets to build directory
file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR})

# Add tests
add_subdirectory(tests)
