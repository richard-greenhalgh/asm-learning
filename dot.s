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

    xorps %xmm0, %xmm0      # acc = 0.0f

loop_start:
    testl %edx, %edx            # is n == 0? sets CPU flags used by jle next
    jle   loop_done             # if n <= 0, done

    # 1. load a[i] into xmm1
    # 2. multiply xmm1 by b[i]
    # 3. add xmm1 to our running total in xmm0 (return value)
    movss (%rdi), %xmm1         # xmm1 = *a
    mulss (%rsi), %xmm1         # xmm1 *= *b
    addss %xmm1, %xmm0          # acc += xmm1

    # update pointers to a[i+1] / b[i+1]
    addq $4, %rdi               # a += 4 bytes (1 float)
    addq $4, %rsi               # b += 4 bytes (1 float)
    decl %edx                   # n--

    jmp loop_start

loop_done:
    ret

# assembler metadata, denotes the size of dot_asm
.size dot_asm, .-dot_asm

# marks the stack as not requiring executable permissions
# (avoids linker warning)
.section .note.GNU-stack,"",@progbits


/* VERSION USING INDEXING

dot_asm:
    # rdi = float* a
    # rsi = float* b
    # edx = int n
    # xmm0 = return value

    xorps %xmm0, %xmm0      # acc = 0.0f
    xorl  %ecx, %ecx        # i = 0

loop_start:
    cmpl  %edx, %ecx        # compare i with n: ecx - edx
    jge   loop_done         # jump if: i >= n (jump if %ecx >= %edx)

    # indexing/addressing: (ptr,i,nbytes)
    # 1. load next a[i] into xmm1
    # 2. multiply xmm1 by b[i]
    # 3. add xmm1 to our running total in xmm0 (return value)
    movss  (%rdi,%rcx,4), %xmm1     # xmm1 = a[i]
    mulss  (%rsi,%rcx,4), %xmm1     # xmm1 *= b[i]
    addss  %xmm1, %xmm0             # acc += xmm1

    incl  %ecx              # i++
    jmp   loop_start

loop_done:
    ret

*/