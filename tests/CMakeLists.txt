cmake_minimum_required(VERSION 3.20)

# Engine sources to test (without main.mm)
set(ENGINE_SOURCES
    ../src/engine/Renderer.mm
    ../src/engine/Shader.mm
    ../src/engine/Texture.mm
    ../src/engine/SpriteBatch.mm
)

# Engine sources for unit tests (no Metal dependencies)
set(ENGINE_UNIT_SOURCES
    ../src/engine/FrameTimer.cpp
    ../src/engine/Input.cpp
    ../src/engine/Entity.cpp
    ../src/engine/EntityManager.cpp
    ../src/engine/CollisionSystem.cpp
    ../src/engine/Audio.cpp
)

# Test executables (Metal-dependent)
add_executable(texture-tests TextureTests.mm ${ENGINE_SOURCES})
add_executable(shader-tests ShaderTests.mm ${ENGINE_SOURCES})
add_executable(renderer-tests RendererTests.mm ${ENGINE_SOURCES})

# Test executables (Unit tests - no Metal)
add_executable(frametimer-tests FrameTimerTests.cpp ../src/engine/FrameTimer.cpp)
add_executable(input-tests InputTests.cpp ../src/engine/Input.cpp)
add_executable(entitymanager-tests EntityManagerTests.cpp 
    ../src/engine/Entity.cpp
    ../src/engine/EntityManager.cpp)
add_executable(collision-tests CollisionSystemTests.cpp
    ../src/engine/Entity.cpp
    ../src/engine/EntityManager.cpp
    ../src/engine/CollisionSystem.cpp)
add_executable(audio-tests AudioTests.cpp ../src/engine/Audio.cpp)

# Configure each test executable
foreach(test_target texture-tests shader-tests renderer-tests)
    target_include_directories(${test_target} PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${SDL2_INCLUDE_DIRS}
    )
    
    target_link_libraries(${test_target} PRIVATE
        ${METAL_FRAMEWORK}
        ${QUARTZCORE_FRAMEWORK}
        ${COCOA_FRAMEWORK}
        ${SDL2_LIBRARIES}
    )
    
    set_source_files_properties(
        ../src/engine/Renderer.mm
        ../src/engine/Shader.mm
        ../src/engine/Texture.mm
        PROPERTIES COMPILE_FLAGS "-x objective-c++"
    )
endforeach()

# Configure unit tests
foreach(test_target frametimer-tests input-tests entitymanager-tests collision-tests audio-tests)
    target_include_directories(${test_target} PRIVATE
        ${CMAKE_SOURCE_DIR}/src
        ${SDL2_INCLUDE_DIRS}
        ${SDL2_MIXER_INCLUDE_DIRS}
    )
    
    target_link_libraries(${test_target} PRIVATE
        ${SDL2_LIBRARIES}
    )
endforeach()

# Link SDL2_mixer for audio tests
if(SDL2_MIXER_FOUND)
    target_link_libraries(audio-tests PRIVATE ${SDL2_MIXER_LIBRARIES})
    if(SDL2_MIXER_LIBRARY_DIRS)
        target_link_directories(audio-tests PRIVATE ${SDL2_MIXER_LIBRARY_DIRS})
    endif()
endif()

# Copy test assets to build directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/assets DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

# Add tests
add_test(NAME TextureTests COMMAND texture-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME ShaderTests COMMAND shader-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME RendererTests COMMAND renderer-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME FrameTimerTests COMMAND frametimer-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME InputTests COMMAND input-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME EntityManagerTests COMMAND entitymanager-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME CollisionTests COMMAND collision-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME AudioTests COMMAND audio-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
