# dot.s

# switch to the code section of the object file
.text

# make symbol "dot_asm" visible outside the file
.global dot_asm

# meta data for the assembler/linker/debugger, indicates "dot_asm" is a function symbol
.type dot_asm, @function

# calling convention reminder:
#  arg1  ->  rdi
#  arg1  ->  rsi
#  arg1  ->  rdx
#  arg1  ->  rcx
#  arg1  ->  r8
#  arg1  ->  r9
#  arg7...   stack

# Syntax reminder:
# %reg        → register
# $imm        → constant
# (%reg)      → dereference pointer
# op src,dst  → AT&T ordering

# function entry point: dot_asm(float* a, float* b, int n)
dot_asm:
    # rdi = float* a
    # rsi = float* b
    # edx = int n
    # xmm0 = return value

    vxorps %zmm4, %zmm4, %zmm4  # acc1 = 0.0f
    vxorps %zmm5, %zmm5, %zmm5  # acc2 = 0.0f
    vxorps %zmm6, %zmm6, %zmm6  # acc3 = 0.0f
    vxorps %zmm7, %zmm7, %zmm7  # acc4 = 0.0f

loop_start:
    cmpl $64, %edx          # compare i with n: n-64
    jl   cleanup           # jump if: i >= n (jump if %ecx >= %edx)

    # 1. load a[i] into xmm1
    # 2. multiply xmm1 by b[i]
    # 3. add xmm1 to our running total in xmm0 (return value)
    vmovups   0(%rdi), %zmm0         # zmm0 = a[i    : i+16]
    vmovups  64(%rdi), %zmm1         # zmm1 = a[i+16 : i+32]
    vmovups 128(%rdi), %zmm2         # zmm2 = a[i+32 : i+48]
    vmovups 192(%rdi), %zmm3         # zmm3 = a[i+48 : i+64]

    vmulps   0(%rsi), %zmm0, %zmm0    # zmm0 = a[...] * b[...]
    vmulps  64(%rsi), %zmm1, %zmm1    # ...
    vmulps 128(%rsi), %zmm2, %zmm2    #
    vmulps 192(%rsi), %zmm3, %zmm3    #

    vaddps %zmm0, %zmm4, %zmm4        # zmm4 += a[...] * b[...]
    vaddps %zmm1, %zmm5, %zmm5        # ...
    vaddps %zmm2, %zmm6, %zmm6        #
    vaddps %zmm3, %zmm7, %zmm7        #

    # vfmadd132ps   0(%rsi), %zmm0, %zmm4    # zmm4 += a[...] * b[...]
    # vfmadd132ps  64(%rsi), %zmm1, %zmm5    # zmm5 += a[...] * b[...]
    # vfmadd132ps 128(%rsi), %zmm2, %zmm6    # zmm6 += a[...] * b[...]
    # vfmadd132ps 192(%rsi), %zmm3, %zmm7    # zmm7 += a[...] * b[...]

    # update pointers to a[i+64] / b[i+64]
    addq $256, %rdi               # a += 256 bytes (64 floats)
    addq $256, %rsi               # b += 256 bytes (64 floats)
    subl $64, %edx                # n -= 64

    jmp loop_start

cleanup:
    xorps %xmm9, %xmm9

tail_loop:
    testl %edx, %edx           # i == 0?
    jle   finish

    movss (%rdi), %xmm8        # xmm1 = a[i]
    mulss (%rsi), %xmm8        # xmm1 = a[i] * b[i]
    addss %xmm8, %xmm9

    addq $4, %rdi              # a += 4 bytes (1 floats)
    addq $4, %rsi              # b += 4 bytes (1 floats)
    decl %edx                  # n--
    jmp tail_loop

finish:
    # consolidate results into zmm0
    vaddps %zmm4, %zmm5, %zmm1
    vaddps %zmm6, %zmm7, %zmm2
    vaddps %zmm1, %zmm2, %zmm0

    # reduce results into xmm0...
    
    # top half of zmm0 -> ymm1
    vextractf32x8 $1, %zmm0, %ymm1
    
    # vector add ymm0+ymm1 (8 floats) + (8 floats)
    vaddps %ymm1, %ymm0, %ymm0
    
    # top half of ymm0 -> xmm1
    vextractf128 $1, %ymm0, %xmm1
    
    # vector add xmm0+xmm1 (4 floats) + (4 floats)
    vaddps %xmm1, %xmm0, %xmm0
    
    # horizontal add pairs within xmm0:
    # xmm0 = [s0+s1, s2+s3, s0+s1, s2+s3]
    vhaddps %xmm0, %xmm0, %xmm0
    
    # horizontal add again to combine those two pair sums:
    # xmm0 = [(s0+s1)+(s2+s3), same, same, same]
    # low float of xmm0 now contains the full SIMD sum
    vhaddps %xmm0, %xmm0, %xmm0

    # add tail loop result to xmm0
    addss %xmm9, %xmm0

    ret

# assembler metadata, denotes the size of dot_asm
.size dot_asm, .-dot_asm

# marks the stack as not requiring executable permissions
# (avoids linker warning)
.section .note.GNU-stack,"",@progbits


