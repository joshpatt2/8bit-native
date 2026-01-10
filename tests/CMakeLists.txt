cmake_minimum_required(VERSION 3.20)

# Engine sources to test (without main.mm)
set(ENGINE_SOURCES
    ../src/engine/Renderer.mm
    ../src/engine/Shader.mm
    ../src/engine/Texture.mm
    ../src/engine/SpriteBatch.mm
)

# Test executables
add_executable(texture-tests TextureTests.mm ${ENGINE_SOURCES})
add_executable(shader-tests ShaderTests.mm ${ENGINE_SOURCES})
add_executable(renderer-tests RendererTests.mm ${ENGINE_SOURCES})

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

# Copy test assets to build directory
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/assets DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

# Add tests
add_test(NAME TextureTests COMMAND texture-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME ShaderTests COMMAND shader-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
add_test(NAME RendererTests COMMAND renderer-tests WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
