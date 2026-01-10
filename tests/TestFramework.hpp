#pragma once
#include <iostream>
#include <string>
#include <vector>
#include <functional>

// Simple test framework to replace XCTest
class TestRunner {
public:
    struct Test {
        std::string name;
        std::function<void()> func;
    };
    
    static TestRunner& instance() {
        static TestRunner runner;
        return runner;
    }
    
    void addTest(const std::string& name, std::function<void()> func) {
        tests.push_back({name, func});
    }
    
    int runAll() {
        int passed = 0;
        int failed = 0;
        
        std::cout << "Running " << tests.size() << " tests...\n" << std::endl;
        
        for (const auto& test : tests) {
            std::cout << "Test: " << test.name << " ... ";
            try {
                test.func();
                std::cout << "PASSED" << std::endl;
                passed++;
            } catch (const std::exception& e) {
                std::cout << "FAILED: " << e.what() << std::endl;
                failed++;
            }
        }
        
        std::cout << "\n========================================" << std::endl;
        std::cout << "Results: " << passed << " passed, " << failed << " failed" << std::endl;
        std::cout << "========================================" << std::endl;
        
        return failed > 0 ? 1 : 0;
    }
    
private:
    std::vector<Test> tests;
};

// Test assertions
class AssertionFailed : public std::exception {
public:
    AssertionFailed(const std::string& msg) : message(msg) {}
    const char* what() const noexcept override { return message.c_str(); }
private:
    std::string message;
};

#define ASSERT_TRUE(condition, message) \
    if (!(condition)) throw AssertionFailed(message)

#define ASSERT_FALSE(condition, message) \
    if (condition) throw AssertionFailed(message)

#define ASSERT_EQUAL(a, b, message) \
    if ((a) != (b)) throw AssertionFailed(message)

#define ASSERT_NOT_NIL(ptr, message) \
    if ((ptr) == nullptr || (ptr) == nil) throw AssertionFailed(message)

#define ASSERT_NIL(ptr, message) \
    if ((ptr) != nullptr && (ptr) != nil) throw AssertionFailed(message)

#define ASSERT_NO_THROW(code, message) \
    try { code; } catch (...) { throw AssertionFailed(message); }

#define TEST(name) \
    void test_##name(); \
    struct TestRegistrar_##name { \
        TestRegistrar_##name() { \
            TestRunner::instance().addTest(#name, test_##name); \
        } \
    } testRegistrar_##name; \
    void test_##name()
