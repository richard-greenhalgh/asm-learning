# wrap.py
# python wrapper for functions written in asm

import ctypes
import numpy as np

from ctypes import c_int, c_float
p_float = ctypes.POINTER(c_float) # "pointer to 32bit float" type

lib = ctypes.CDLL("./libdot.so")

dot = lib.dot_wrapper
dot.argtypes = [p_float, p_float, c_int]
dot.restype = c_float

RNG = np.random.default_rng(seed=42)
n = int(1_000_000)
a = RNG.standard_normal(n).astype(np.float32)
b = RNG.standard_normal(n).astype(np.float32)

def ptr(arr: np.ndarray, ctype=p_float):
    return arr.ctypes.data_as(ctype)
a_ptr = ptr(a)
b_ptr = ptr(b)

# Correctness check
result = dot(a_ptr, b_ptr, n)
expected = np.dot(a, b)

print(f"expected: {expected:.4f}")
print(f"result:   {result:.4f}")
print(f"diff:     {abs(expected - result):.6f}")

# Timing
import time

N_REPEATS = 1_000

# Warm-up
for _ in range(1_000):
    dot(a_ptr, b_ptr, n)
    np.dot(a, b)

# Time asm
t0 = time.perf_counter()
for _ in range(N_REPEATS):
    asm_result = dot(a_ptr, b_ptr, n)
t1 = time.perf_counter()

# Time numpy
t2 = time.perf_counter()
for _ in range(N_REPEATS):
    np_result = np.dot(a, b)
t3 = time.perf_counter()

asm_time = t1 - t0
np_time = t3 - t2

print()
print(f"repeats:       {N_REPEATS:,}")
print(f"asm total:     {asm_time:.6f}s")
print(f"numpy total:   {np_time:.6f}s")
print(f"asm per call:  {asm_time / N_REPEATS * 1e6:.3f} µs")
print(f"numpy per call:{np_time / N_REPEATS * 1e6:.3f} µs")
print(f"speed ratio:   {np_time / asm_time:.2f}x numpy/asm")

expected_grouped = (
    np.dot(a[0::4], b[0::4])
    + np.dot(a[2::4], b[2::4])
    + np.dot(a[1::4], b[1::4])
    + np.dot(a[3::4], b[3::4])
)

print(f"grouped expected: {expected_grouped:.4f}")
print(f"asm result:       {result:.4f}")
print(f"grouped diff:     {abs(expected_grouped - result):.6f}")