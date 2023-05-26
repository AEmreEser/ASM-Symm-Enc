.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\Emre Eser\\Desktop\\cs401_term_project\\tables.dat" # put the fullpath name of the file AES.dat here
buffer: .space 12400                    # temporary buffer to read from file

s: .word  0xd82c07cd, 0xc2094cbd, 0x6baa9441, 0x42485e3f
rkey: .word 0x82e2e670, 0x67a9c37d, 0xc8a7063b, 0x4da5e71f

t: .space 16 # 16 bytes = 128 bits = 4 words

.text
#open a file for writing

program_main:
li   $v0, 13       # system call for open file
la   $a0, fin      # file name
li   $a1, 0        # Open for reading
li   $a2, 0
syscall            # open a file (file descriptor returned in $v0)
move $s6, $v0      # save the file descriptor 

#read from file
li   $v0, 14       # system call for read from file
move $a0, $s6      # file descriptor 
la   $a1, buffer   # address of buffer to which to read
li   $a2, 12400    # hardcoded buffer length
syscall            # read from file

move $s0, $v0	   # the number of characters read from the file
la   $s1, buffer   # address of buffer that keeps the characters
addi $sp, $sp, -16
sw $s0, 0($sp) # push s regs
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $s3, 12($sp)

# T0 ITERATION
la $a1, T0
jal table_allocate
move $t1, $v0 # t1: address of T0 (updated after every iter. of get num val
li $t0, 256 # t0: number of iterations per LUT
jal loop

# s1 (points to the byte address of the next character to be read [inside buffer] ) must be the next lut word to be scanned here
# NO NEED TO ADD ANYTHING TO S1 AFTER ITERATIONS
la $a1, T1
jal table_allocate
li $t0, 256
move $t1, $v0 # t1: address of T0 (updated after every iter. of get num val
# addi $s1, $s1, -4
jal loop

la $a1, T2
jal table_allocate
li $t0, 256
move $t1, $v0 # t1: address of T0 (updated after every iter. of get num val
# addi $s1, $s1, -4
jal loop

la $a1, T3
jal table_allocate
li $t0, 256
move $t1, $v0 # t1: address of T0 (updated after every iter. of get num val
# addi $s1, $s1, -4
jal loop

# round key loop begin

li $t0, 0 # t0: keeps index of round key loop iteration --> terminate if equal to 4

round_loop:
move $a1, $t0

# push s regs before procedure call
addi $sp, $sp, -4
sw $s0, 0($sp)

jal round_op

la $t2, t
sll $t1, $t0, 2 # address to save $v0 in rkey array
add $t2, $t2, $t1
sw $v0, 0($t2) # save returned value in rkey array

# pop s regs after procedure call
lw $s0, 0($sp)
addi $sp, $sp, 4

addi $t0, $t0, 1 # increment loop index

li $t1, 4
blt $t0, $t1, round_loop # if t0 == 4, terminate loop
# round key loop end

##### JUMPS FOR PHASE 2 IMPLEMENT HERE!!!

j Exit # END OF MAIN

#~~~phase 2~~~#

round_op:
# args: $a1: t index (0,1,2,3)
# used regs: 
#t0 - address of s -> address of the word at t index in s
	# -> address of T3
#t1 - t byte offset
#t2 - word at s[t index]
#s0 - word at T3[ [s[t - index]>>24]

# pushing temp regs
addi $sp, $sp, -12
sw $t0, 0($sp)
sw $t1, 4($sp)
sw $t2, 8($sp)
# end of pushing temp regs

la $t0, s
andi $a1, $a1, 3 # mask off the bits before last two
sll $t1, $a1, 2 # t1 is the byte offset
add $t0, $t0, $t1 # get address of s[t index]
lw $t2, 0($t0) # t2 contains word at s[t index]
srl $t2, $t2, 24 # 24 right shift
andi $t2, $t2, 255 # 0xff
la $t0, T3 
lw $t0, 0($t0)
sll $t2, $t2, 2 # mult by 4 : byte address
add $t0, $t0, $t2 # offsetted addresss in T3
lw $v0, 0($t0) # s0 = T3[s[t - index]>>24]

addi $a1, $a1, 1
andi $a1, $a1, 3 # increment t - index

la $t0, s
sll $t1, $a1, 2 # t1 = t - index * 4 = byte offset
add $t0, $t0, $t1 # t0 = address of s + byte offset => t0 = address of s[t - index + 1 % 4]
lw $t2, 0($t0) # t2 = word at s[t - index + 1 %4]
srl $t2, $t2, 16 # 16 bit right shift
andi $t2, $t2, 255 # 0xff
la $t0, T1
lw $t0, 0($t0)
sll $t2, $t2, 2
add $t0, $t0, $t2 # offset --> T1 --> s[[ t- index + 1 % 4] >> 16]
lw $s0, 0($t0)

xor $v0, $v0, $s0

addi $a1, $a1, 1
andi $a1, $a1, 3 # increment t - index

la $t0, s
sll $t1, $a1, 2 # t1 = t - index * 4 = byte offset
add $t0, $t0, $t1 # t0 = address of s + byte offset => t0 = address of s[t - index + 1 % 4]
lw $t2, 0($t0) # t2 = word at s[t - index + 1 %4]
srl $t2, $t2, 8 # 8 bit right shift
andi $t2, $t2, 255 # 0xff
la $t0, T2
lw $t0, 0($t0)
sll $t2, $t2, 2
add $t0, $t0, $t2 # offset --> T2 --> s[[ t- index + 1 % 4] >> 16]
lw $s0, 0($t0)

xor $v0, $v0, $s0

addi $a1, $a1, 1
andi $a1, $a1, 3 # increment t - index

la $t0, s
sll $t1, $a1, 2 # t1 = t - index * 4 = byte offset
add $t0, $t0, $t1 # t0 = address of s + byte offset => t0 = address of s[t - index + 1 % 4]
lw $t2, 0($t0) # t2 = word at s[t - index + 1 %4]
andi $t2, $t2, 255 # 0xff
la $t0, T0
lw $t0, 0($t0)
sll $t2, $t2, 2
add $t0, $t0, $t2 # offset --> T2 --> s[[ t- index + 1 % 4] >> 16]
lw $s0, 0($t0)

xor $v0, $v0, $s0

addi $a1, $a1, 1
andi $a1, $a1, 3 # increment t - index

la $t0, rkey
sll $t1, $a1, 2
add $t0, $t0, $t1 # byte indexed r key address
lw $t2, 0($t0) # t2 = rkey[t - index (--> same as the initially passed value) ] 

xor $v0, $v0, $t2 # make sure to keep passed argument (t - index) constant outside of function

# restoring temp regs
lw $t0, 0($sp)
lw $t1, 4($sp)
lw $t2, 8($sp)
addi $sp, $sp, 12
# end of restoring temp regs

jr $ra
# end of round op

#~~~end of phase 2~~~#




#~~~PHASE 1~~~~#

loop: #fetch numeric val, save it in a single lut Tn
j get_num_val # function call
loop_cont:
# v0 contains word read from lut
# s1 contains incremented address of the buffer --> points to the end of the LUT word

sw $v0, 0($t1)
addi $t1, $t1, 4 # next word in lut
addi $s1, $s1, 2 # skip ", " between lut vals
addi $t0, $t0, -1 # decrement
bnez $t0, loop

jr $ra # return from loop

lw $s0, 0($sp) # restore s regs
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $s3, 12($sp)
addi $sp, $sp, 16

j Exit

# 1024 LUT values -- each LUT word 4 bytes: total 4096 bytes
# each LUT will contain 256 entries

#### FUNCTION Allocate Space
# a1: address of lut pointer
table_allocate:
addi $sp, $sp, -4
sw $t0, 0($sp)
li $v0, 9 # syscall for dy. mem. alloc
li $a0, 1024 # 1024 bytes = 256 words
syscall
# la $t0, T0
move $t0, $a1
sw $v0, 0($t0)
lw $t0, 0($sp)
addi $sp, $sp, 4
jr $ra

###### END FUNCTION


# S1: ADDRESS OF BUFFER (set inside get_num_val, passed to func in a1)

#### FUNCTION ####
#### gets the numeric value of table entry pointed by $a1
# a1 must point to the 0 character in 0x...
# increments address of buffer: kept in s1
get_num_val:
addi $sp, $sp, -8 # push t regs
# sw $t0, 0($sp)
sw $t1, 0($sp) # push t regs --> DONT PUSH T0, ELSE ERROR!!!!!!!!! , VALUE OF T0 MUST NOT CHANGE!!!
sw $t2, 4($sp)

li $t1, 0
li $s3, 0
# move $s1, $a1
addi $s1, $s1, 2 # initial 0x # every 8 iterations: += 4
func_main:
lbu $a2, 0($s1) # load from buffer location
li $a1, 87 # so that a corresponds to 10
bge $a2, $a1, alpha_hex
li $a1, 48 # so that ascii 0 corresponds to numeric 0
bge $a2, $a1, alpha_hex

main_p2: # s3 in this part: numeric value of the ascii sequence for the hex number that is being read from the buffer
sll $s3, $s3, 4 # one hex digit left shift
or $s3, $s3, $v0 # record the numeric value in s3
addi $s1, $s1, 1 # buffer address increment
addi $t1, $t1, 1 # counter increment
li $t2, 7 # if equal to 8 --> return to loop: 8 = word length / 4 (num of bits in hex digit)
ble $t1, $t2, func_main
move $v0, $s3 # returns in v0

# lw $t0, 0($sp) # restore t regs
lw $t1, 0($sp)
lw $t2, 4($sp)
addi $sp, $sp, 8

j loop_cont # return here

alpha_hex: # args in: $a2, $a1, returns in $v0
sub $a2, $a2, $a1
move $v0, $a2
j main_p2

#### END OF FUNCTION!!!!

Exit:
li $v0,10
syscall             #exits the program

