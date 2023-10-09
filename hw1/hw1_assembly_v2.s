.data
    image_rgb:    .word 0x3F670AFE, 0x3D05BCF6, 0x3F6213FA ,0x3E5B1CEB, 0x3D970A4B, 0x3D2381CA ,0x3E5C712F, 0x3F635DFA, 0x3F48DDED ,0x3F703622, 0x3F247DB9, 0x3D3D140D ,0x3E10B6BE, 0x3EA9568F, 0x3E807326 ,0x3EC44B43, 0x3F308180, 0x3ED24936 ,0x3F647D44, 0x3E179ED9, 0x3F2E6639 ,0x3F6DC7B9, 0x3E6D7818, 0x3E9D2F54 ,0x3F24352A, 0x3EB1B39E, 0x3F03A61E
    coef_rgb:     .word 0x3E991687, 0x3F1645A2, 0x3DE978D5
    result_str:  .string "Gray image: \n"
    endline:    .string "\n"
    
.text
start:
    j    main
    
getbit:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    mv      t0, a4  #value
    mv      t1, a5  #n
    srl     t0, t0, t1
    andi    a0, t0, 1

    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret
    
imul32:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    #a2 = a
    #a3 = b
    mv      t0, zero    #r
    imul_loop:
    beq     a3, zero, imul_done
    andi    t1, a3, 1
    beq     t1, zero, imul_loop_false
    add     t0, t0, a2
    imul_loop_false:
    srli    a3, a3, 1
    srli    t0, t0, 1
    j       imul_loop
    imul_done:
    slli    a0, t0, 1
    
    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret

count_leading_zeros:
    addi    sp, sp, -8
    sw      ra, 0(sp)
    sw      s0, 4(sp)

    mv      s0, a2  #x
    srli    t0, s0, 1
    or      s0, s0, t0
    srli    t0, s0, 2
    or      s0, s0, t0
    srli    t0, s0, 4
    or      s0, s0, t0
    srli    t0, s0, 8
    or      s0, s0, t0
    srli    t0, s0, 16
    or      s0, s0, t0

    srli    t0, s0, 1
    li      t5, 0x55555555
    and     t0, t0, t5
    sub     s0, s0, t0
    srli    t0, s0, 2
    li      t5, 0x33333333
    and     t0, t0, t5  #t0=(x >> 2) & 0x33333333
    and     t1, s0, t5  #t1=(x & 0x33333333)
    add     s0, t0, t1
    srli    t0, s0, 4
    add     t0, t0, s0
    li      t5, 0x0f0f0f0f
    and     s0, t0, t5
    srli    t0, s0, 8
    add     s0, s0, t0
    srli    t0, s0, 16
    add     s0, s0, t0
    andi    s0, s0, 0x7f
    li      t0, 32
    sub     a0, t0, s0

    lw      ra, 0(sp)
    lw      s0, 4(sp)
    addi    sp, sp, 8
    ret

unsigned_fadd32:
    addi    sp, sp, -32
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)
    sw      s4, 20(sp)
    sw      s5, 24(sp)
    sw      s6, 28(sp)

    mv      s0, a4  #a
    mv      s1, a5  #b
    li      t5, 0x7FFFFFFF
    and     t0, s0, t5
    and     t1, s1, t5
    bge     t0, t1, skip_swap # if t0 >= t1 then target
    mv      t0, s0
    mv      s0, s1
    mv      s1, t0
    skip_swap:
    # mantissa
    li      t5, 0x7FFFFF
    li      t6, 0x800000
    and     s2, s0, t5
    or      s2, s2, t6    #ma
    and     s3, s1, t5
    or      s3, s3, t6    #mb
    #exponent
    srli    s4, s0, 23
    li      t0, 0xFF
    and     s4, s4, t0  #ea
    srli    s5, s1, 23
    and     s5, s5, t0  #eb
    sub     t0, s4, s5
    li      t1, 24
    blt     t1, t0, align_24
    mv      t1, t0
    align_24:   #t1 = align
    srl     s3, s3, t1
    xor     t0, s0, s1
    srli    t0, t0, 31
    beq     t0, zero, ma_plus_mb
    sub     s2, s2, s3
    j       mantissa_cal_done
    ma_plus_mb:
    add     s2, s2, s3

    mantissa_cal_done:
    mv      a2, s2
    call    count_leading_zeros
    mv      s6, a0  #clz
    li      t0, 8
    bge     t0, s6, clz_lessthan8
    sub     t1, s6, t0  #shift = clz-8
    sll     s2, s2, t1
    sub     s4, s4, t1
    j       cal_result 
    clz_lessthan8:
    sub     t1, t0, s6  #shift = 8-clz
    srl     s2, s2, t1
    add     s4, s4, t1
    cal_result:
    li      t5, 0x80000000
    and     a0, s0, t5
    slli    t0, s4, 23
    li      t5, 0x7FFFFF
    and     t1, s2, t5
    or      a0, a0, t0
    or      a0, a0, t1

    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    lw      s4, 20(sp)
    lw      s5, 24(sp)
    lw      s6, 28(sp)
    addi    sp, sp, 32
    ret

fmul:
    addi    sp, sp, -48
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)
    sw      s4, 20(sp)
    sw      s5, 24(sp)
    sw      s6, 28(sp)
    sw      s7, 32(sp)
    sw      s8, 36(sp)
    sw      s9, 40(sp)
    sw      s10, 44(sp)

    lw      s0, 0(a2)   #float a(image)
    lw      s1, 0(a3)   #float b(coef)
    
    srli     s2, s0, 31    #sa
    srli     s3, s1, 31    #sb
    li       t0, 0x7FFFFF
    li       t1, 0x800000
    and      s4, s0, t0
    or       s4, s4, t1    # ma
    and      s5, s1, t0
    or       s5, s5, t1    # mb
    li       t0, 0xFF
    srli     s6, s0, 23
    and      s6, s6, t0    #ea
    srli     s7, s1, 23
    and      s7, s7, t0    #eb
    
    mv      a2, s4
    mv      a3, s5
    call    imul32
    mv      a4, a0    #mrtmp
    li      a5, 24
    call    getbit
    mv      t0, a0    #mshift
    srl     s8, a4, t0    #mr
    add     t1, s6, s7
    addi    t1, t1, -127 #ertmp
    add     s9, t0, t1  #er
    xor     s10, s2, s3 #sr

    li      t0, 0xFF
    li      t1, 0x7FFFFF
    slli    a0, s10, 31
    and     t2, s9, t0
    slli    t2, t2, 23
    and     t3, s8, t1
    or      a0, a0, t2
    or      a0, a0, t3

    
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    lw      s4, 20(sp)
    lw      s5, 24(sp)
    lw      s6, 28(sp)
    lw      s7, 32(sp)
    lw      s8, 36(sp)
    lw      s9, 40(sp)
    lw      s10, 44(sp)
    addi    sp, sp, 48
    ret

RGB_to_GRAY:
    addi    sp, sp, -24
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)
    sw      s4, 20(sp)
    li      s0, 0    #initial loop i,j
    li      s1, 0
    li      s2, 3
    li      s3, 0    #address
outer_loop:
    bge     s0, s2, done  
    li      s1, 0      # j = 0
inner_loop:
    bge     s1, s2, inner_done
    #calculate
    
    #calculate address
    slli    t0, s0, 5
    slli    t1, s0, 2
    add     t2, t0, t1  #t2=36*i
    slli    t0, s1, 3
    slli    t1, s1, 2
    add     t3, t0, t1  #t3=12*j
    add     s3, t2, t3   # s3 = i*36+j*12 (adress)
    #calculate
    la      a2, image_rgb
    add     a2, a2, s3    # R
    la      a3, coef_rgb    # R
    call    fmul    # a0=return value 
    mv      s4, a0  #s4 = R*0.299
    
    la      a2, image_rgb
    add     a2, a2, s3
    addi    a2, a2, 4    # G
    la      a3, coef_rgb
    addi    a3, a3, 4    # G
    call    fmul    # a0=return value 
    mv      a4, a0
    mv      a5, s4
    call    unsigned_fadd32  # a0=return value 
    mv      s4, a0
    
    la      a2, image_rgb
    add     a2, a2, s3
    addi    a2, a2, 8    # B
    la      a3, coef_rgb
    addi    a3, a3, 8    # B
    call    fmul    # a0=return value  
    mv      a4, a0
    mv      a5, s4
    call    unsigned_fadd32  # a0=return value 
    mv      s4, a0
    
    #print result
    mv      a0, s4    
    li       a7,  2
    ecall    #print number
    li       a0,  32
    li       a7,  11
    ecall    #print space
    
    addi    s1, s1, 1 # j = j + 1
    j       inner_loop
inner_done:
    la      a0, endline    #printf("\n")
    li      a7, 4
    ecall
    addi    s0, s0, 1  # i = i + 1
    j       outer_loop  
done:
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    lw      s4, 20(sp)
    addi    sp, sp, 24
    ret
    
main:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    la      a0, result_str    #printf("gray image:\n")
    li      a7, 4
    ecall
    
    call    RGB_to_GRAY
    lw      ra, 0(sp)
    addi    sp, sp, 4
    li      a7, 10        #return 0
    ecall
