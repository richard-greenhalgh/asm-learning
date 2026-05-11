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

    xorps %xmm0, %xmm0      # tmp1 = 0.0f
    xorps %xmm1, %xmm1      # tmp2 = 0.0f
    xorps %xmm2, %xmm2      # tmp3 = 0.0f
    xorps %xmm3, %xmm3      # tmp4 = 0.0f
    xorps %xmm4, %xmm4      # acc1 = 0.0f
    xorps %xmm5, %xmm5      # acc2 = 0.0f
    xorps %xmm6, %xmm6      # acc3 = 0.0f
    xorps %xmm7, %xmm7      # acc4 = 0.0f

loop_start:
    cmpl $4, %edx          # compare i with n: n-4
    jl   cleanup           # jump if: i >= n (jump if %ecx >= %edx)

    # 1. load a[i] into xmm1
    # 2. multiply xmm1 by b[i]
    # 3. add xmm1 to our running total in xmm0 (return value)
    movss  0(%rdi), %xmm0        # xmm0 = a[i+0]
    movss  4(%rdi), %xmm1        # xmm1 = a[i+1]
    movss  8(%rdi), %xmm2        # xmm2 = a[i+2]
    movss 12(%rdi), %xmm3        # xmm3 = a[i+3]
    
    mulss  0(%rsi), %xmm0        # xmm0 = a[i+0] * b[i+0]
    mulss  4(%rsi), %xmm1        # xmm1 = a[i+1] * b[i+1]
    mulss  8(%rsi), %xmm2        # xmm2 = a[i+2] * b[i+2]
    mulss 12(%rsi), %xmm3        # xmm3 = a[i+3] * b[i+3]

    addss %xmm0, %xmm4           # acc1 += xmm0
    addss %xmm1, %xmm5           # acc2 += xmm1
    addss %xmm2, %xmm6           # acc1 += xmm2
    addss %xmm3, %xmm7           # acc2 += xmm3

    # update pointers to a[i+4] / b[i+4]
    addq $16, %rdi               # a += 16 bytes (4 floats)
    addq $16, %rsi               # b += 16 bytes (4 floats)
    subl $4, %edx                # n -= 4

    jmp loop_start

cleanup:
    xorps %xmm0, %xmm0

tail_loop:
    testl %edx, %edx           # i == 0?
    jle   finish

    movss (%rdi), %xmm1        # xmm1 = a[i]
    mulss (%rsi), %xmm1        # xmm1 = a[i] * b[i]
    addss %xmm1, %xmm0

    addq $4, %rdi              # a += 4 bytes (1 floats)
    addq $4, %rsi              # b += 4 bytes (1 floats)
    decl %edx                  # n--
    jmp tail_loop

finish:
    addss %xmm4, %xmm0
    addss %xmm5, %xmm0
    addss %xmm6, %xmm0
    addss %xmm7, %xmm0
    ret

# assembler metadata, denotes the size of dot_asm
.size dot_asm, .-dot_asm

# marks the stack as not requiring executable permissions
# (avoids linker warning)
.section .note.GNU-stack,"",@progbits


