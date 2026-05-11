// wrapper.cpp
// C wrapper for asm functions

// Note: referenced by C wrapper, NOT python wrapper
extern "C" float dot_asm(float* a, float* b, int n);

// Note: python wrapper calls this function
extern "C" float dot_wrapper(float* a, float* b, int n) {
    return dot_asm(a, b, n);
}
