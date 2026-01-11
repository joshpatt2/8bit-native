cmake_minimum_required(VERSION 3.20)
project(8bit-native LANGUAGES CXX OBJCXX)

# C++17 standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable testing
enable_testing()

# Find SDL2
find_package(SDL2 REQUIRED)

# Try to find SDL2_mixer using pkg-config
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(SDL2_MIXER QUIET SDL2_mixer)
endif()

# Fallback for direct library search
if(NOT SDL2_MIXER_FOUND)
    find_library(SDL2_MIXER_LIBRARY SDL2_mixer)
    if(SDL2_MIXER_LIBRARY)
        set(SDL2_MIXER_LIBRARIES ${SDL2_MIXER_LIBRARY})
        # Try to find include directory
        find_path(SDL2_MIXER_INCLUDE_DIR SDL2/SDL_mixer.h
            PATHS /opt/homebrew/include /usr/local/include)
        if(SDL2_MIXER_INCLUDE_DIR)
            set(SDL2_MIXER_INCLUDE_DIRS ${SDL2_MIXER_INCLUDE_DIR})
        endif()
        set(SDL2_MIXER_FOUND TRUE)
    endif()
endif()

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
    src/engine/Entity.cpp
    src/engine/EntityManager.cpp
    src/engine/Input.cpp
    src/engine/CollisionSystem.cpp
    src/engine/Animator.cpp
    src/engine/Audio.cpp
    src/engine/TextRenderer.mm
    src/game/Player.cpp
    src/game/Enemy.cpp
    src/game/PlayerAttack.cpp
)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${SDL2_INCLUDE_DIRS}
    ${SDL2_MIXER_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/src
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    ${SDL2_LIBRARIES}
    ${METAL_FRAMEWORK}
    ${QUARTZCORE_FRAMEWORK}
    ${COCOA_FRAMEWORK}
)

# Link SDL2_mixer if found
if(SDL2_MIXER_FOUND)
    target_link_libraries(${PROJECT_NAME} PRIVATE ${SDL2_MIXER_LIBRARIES})
    # Add library directory for linker
    if(SDL2_MIXER_LIBRARY_DIRS)
        target_link_directories(${PROJECT_NAME} PRIVATE ${SDL2_MIXER_LIBRARY_DIRS})
    endif()
    message(STATUS "SDL2_mixer found and linked: ${SDL2_MIXER_LIBRARIES}")
else()
    message(WARNING "SDL2_mixer not found. Install with: brew install sdl2_mixer")
endif()

# Objective-C++ flags for .mm files
set_source_files_properties(
    src/main.mm
    src/engine/Renderer.mm
    src/engine/Shader.mm
    src/engine/Texture.mm    src/engine/TextRenderer.mm    PROPERTIES COMPILE_FLAGS "-x objective-c++"
)

# Copy shaders to build directory
file(COPY ${CMAKE_SOURCE_DIR}/shaders DESTINATION ${CMAKE_BINARY_DIR})

# Copy assets to build directory
file(COPY ${CMAKE_SOURCE_DIR}/assets DESTINATION ${CMAKE_BINARY_DIR})

# Add tests
add_subdirectory(tests)
