# dot.s

# switch to the code section of the object file
.text

# make symbol "dot_asm" visible outside the file
.global dot_asm

# meta data for the assembler/linker/debugger, indicates "dot_asm" is a function symbol
.type dot_asm, @function

# function entry point
dot_asm:
    # MVP: ignore a, b, n
    # Return 0.0f in xmm0
    # xorps: single-precision vector xor
    # (xor'ing register with itself a fast way to zero)
    xorps %xmm0, %xmm0
    
    # return
    ret

# assembler metadata, denotes the size of dot_asm
.size dot_asm, .-dot_asm

# marks the stack as not requiring executable permissions
# (avoids linker warning)
.section .note.GNU-stack,"",@progbits
