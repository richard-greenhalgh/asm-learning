#!/bin/bash
set -e
gcc -O3 -shared -fPIC wrapper.cpp dot.s -o libdot.so

