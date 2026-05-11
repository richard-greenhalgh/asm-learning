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
n = int(1024)
a = RNG.standard_normal(n).astype(np.float32)
b = RNG.standard_normal(n).astype(np.float32)

def ptr(arr: np.ndarray, ctype=p_float):
    return arr.ctypes.data_as(ctype)

result = dot(ptr(a), ptr(b), n)

print(f"result: {result:.4f}")
