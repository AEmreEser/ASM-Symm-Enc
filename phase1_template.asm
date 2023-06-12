.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\Emre Eser\\Desktop\\cs401_term_project\\tables.dat" # put the fullpath name of the file AES.dat here
buffer: .space 12400                    # temporary buffer to read from file

s: .word  0xd82c07cd, 0xc2094cbd, 0x6baa9441, 0x42485e3f
rcon: .byte 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01
rkey: .space 128 # check vals: 0x82e2e670, 0x67a9c37d, 0xc8a7063b, 0x4da5e71f
key: .word 0x2b7e1516, 0x28aed2a6, 0xabf71588, 0x09cf4f3c
t: .space 64
message: .space 64 # .word 0x6bc1bee2, 0x2e409f96, 0xe93d7e11, 0x7393172a, 0x00000000, 0x00000000, 0x00000000, 0x00000000 # .space 64 # 8 word space
ciphertext: .space 64
newline: .asciiz "\n"

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

# initialize rkey with key before round loop executions:
la $a0, key
la $a1, rkey
jal transfer # for i = 0,1,2,3 : rkey[i] = key[i] after this line
# end of rkey initalization


main_loop: # here: re-genearate rkey, generate round value, repeat 8 times


# READ INPUT PART
la $a0, message
li $a1, 32 # 32 chars read
li $v0, 8 # read string syscall
syscall




jal whiten

# RKEY GENERATION PART:

li $t0, 0 #to: r_key_loop index 0 to 7
r_key_generation_loop:

move $a1, $t0 # iteration index passed as argument

addi $sp, $sp, -12 # push s regs
sw $s0, 0($sp)
sw $s1, 4($sp)
sw $s2, 8($sp)

jal generate_r_key

addi $sp, $sp, 12 # restore s regs
lw $s0, 0($sp)
lw $s1, 4($sp)
lw $s2, 8($sp)

# ROUND VALUE GENERATION PART:

li $t3,0 # t3: round loop index: 0 to 3
round_loop:
move $a1, $t3

# push s regs before procedure call
addi $sp, $sp, -4
sw $s0, 0($sp)

jal round_op

la $t2, t
sll $t1, $t3, 2 # address to save $v0 in rkey array
add $t2, $t2, $t1
sw $v0, 0($t2) # save returned value in rkey array

# pop s regs after procedure call
lw $s0, 0($sp)
addi $sp, $sp, 4

addi $t3, $t3, 1 # increment loop index

li $t1, 4
blt $t3, $t1, round_loop # if t0 == 4, terminate loop
# round key loop end

la $a0, t
la $a1, s
jal transfer # transfer t -> s
# end of round value part

li $t1, 8
addi $t0, $t0, 1
blt $t0, $t1, r_key_generation_loop

# message label is where the program stores the intermediary strings until completion:
# need to transfer it back to the ciphertext label
# and print it

la $t0, ciphertext
la $t1, t
lw $t3, 0($t1)
sw $t3, 0($t0)

lw $t3, 4($t1)
sw $t3, 4($t0)

lw $t3, 8($t1)
sw $t3, 8($t0)

lw $t3, 12($t1)
sw $t3, 12($t0)


# PRINTING: 
# first prints the ciphertext in ascii, then prints the words in hex
# important: the words of the ciphertext array are printed with a new line in between for ease of reading
li $v0, 4
la $a0, ciphertext
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
la $t0, ciphertext
lw $a0, 0($t0)
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 4($t0)
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 8($t0)
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 12($t0)
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 16($t0)
syscall


li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 20($t0)
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 24($t0)
syscall

li $v0, 4
la $a0, newline
syscall

li $v0, 34
lw $a0, 28($t0)
syscall

j Exit

# round key generation loop end

# END OF MAIN




# PHASE 3:

# WHITEN FUNCTION
whiten:

addi $sp, $sp, -20

sw $s0, 0($sp)
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $t0, 12($sp)
sw $t1, 16($sp)
sw $t2, 20($sp)

la $s0, key
la $s1, message
la $s2, s
li $t0, 0 # index i


whiten_loop:

lw $t1, 0($s0) # t1: key[i]
lw $t2, 0($s1) # t2: message[i]
xor $t2, $t2, $t1
sw $t2, 0($s2) # s[i] = result

addi $s0, $s0, 4
addi $s1, $s1, 4
addi $s2, $s2, 4

addi $t0, $t0, 1
li $t1, 4
blt $t0, $t1, whiten_loop

lw $s0, 0($sp)
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $t0, 12($sp)
lw $t1, 16($sp)
lw $t2, 20($sp)

addi $sp, $sp, 20


jr $ra







#~~~phase 2~~~#





generate_r_key:
# a0: argument for i --> loop index??
# t0: address of rkey + 8 = address of rkey[2] --> becomes d
# t1: contains value of rkey[2]
# t3: contains temporary result
# v0: contains tmp until 
# s0: a, s1: b, s2: c

addi $sp, $sp, -20 # push t regs
sw $t0, 0($sp) 
sw $t1, 4($sp)
sw $t2, 8($sp)
sw $t3, 12($sp)
sw $t4, 16($sp)


la $t0, rkey 
addi $t0, $t0, 8 # rkey[2]
lw $t1, 0($t0)

la $t3, T2
lw $t3, 0($t3) # t3 contains the array address pointed to by value at T2

srl $s1, $t1, 16 # b
andi $s1, $s1, 255

# calculation of e
sll $s1, $s1, 2 # byte offset
add $t3, $t3, $s1 # address of T2[b]
lw $t3, 0($t3) # t3 = value at T2[b]
andi $t3, $t3, 255

# sll $a1, $a1, 2 # a1 * 4 = byte offset to rcon
la $t4, rcon
add $t4, $t4, $a1 # t4 = address of rcon[i]
lb $t4, 0($t4) # t4 = value at rcon[i]
andi $t4, $t4, 255 
xor $t4, $t4, $t3 # t4 = e
sll $v0, $t4, 24 # v0 contains e: after this v0 will be temp
# v0: e << 24

# getting c
srl $s1, $t1, 8 # c = s1
andi $s1, $s1, 255

# calculation of f
la $t3, T2 # t3 = address of word containing 
lw $t3, 0($t3)
sll $s1, $s1, 2 # byte offset from word offset
add $t3, $t3, $s1 # t3: address of T2[c]
lw $t3, 0($t3) # t3: value at T2[c]
andi $t3, $t3, 255 # t3 = f
sll $t3, $t3, 16
xor $v0, $v0, $t3 # v0 = (e << 24) ^ (f << 16) 

# getting d
andi $t1, $t1, 255 # t1 = d
move $s1, $t1 # s1 = d

# calculation of g
la $t3, T2 # t3 = address of byte containing address of T2
lw $t3, 0($t3) # t3 = address of T2
sll $s1, $s1, 2 # byte offset from word offset d
add $t3, $t3, $s1 # t3 = address of T2[c]
lw $t3, 0($t3)  # t3 = value at T2[c]
andi $t3, $t3, 255 # t3 = g
sll $t3, $t3, 8
xor $v0, $v0, $t3 # v0 = (e << 24) ^ (f << 16) ^ (g << 8)

# getting a
la $t0, rkey 
addi $t0, $t0, 8 # rkey[2]
lw $t1, 0($t0)
srl $s1, $t1, 24 # a
andi $s1, $s1, 255 # 0xff

# calculation of h
la $t3, T2# t3 address of byte containing address of first word of T2
lw $t3, 0($t3) # t3: address of first word of T2
sll $s1, $s1, 2 # byte offset from word offset a
add $t3, $t3, $s1 #t3 contains address of T2[a]
lw $t3, 0($t3) # t3 contains value @ T2[a]
andi $t3, $t3, 255 # t3 = h

xor $v0, $v0, $t3 # # v0 = (e << 24) ^ (f << 16) ^ (g << 8) ^ h = tmp

# update rkey values
la $t4, rkey
lw $t3, 0($t4) # value at rkey[0] = t3

xor $v0, $v0, $t3 # $v0 = new val of rkey[0]
sw $v0, 0($t4) # value in $v0 -> rkey[0]

lw $t3, 4($t4) # value at rkey[1] = t3
xor $v0, $v0, $t3
sw $v0, 4($t4) # store to rkey[1]

lw $t3, 8($t4) # value at rkey[2] = t3
xor $v0, $v0, $t3
sw $v0, 8($t4) # store to rkey[2]

lw $t3, 12($t4) # value at rkey[3] = t3
xor $v0, $v0, $t3
sw $v0, 12($t4) # store to rkey[3]
# end of updating rkey values

lw $t0, 0($sp) # restore t regs
lw $t1, 4($sp)
lw $t2, 8($sp)
lw $t3, 12($sp)
lw $t4, 16($sp)
addi $sp, $sp, 20

jr $ra
# end of rkey generation function



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






# function transfer from t to s: state transfer

transfer:
# a0: from - t
# a1: to - s --> addresses of arrays

addi $sp, $sp, -12 # pushing t regs
sw $t0, 0($sp)
sw $t1, 4($sp)
sw $t2, 8($sp)

move $t2, $a0
move $t0, $a1

lw $t1, 0($t2)
sw $t1, 0($t0) # transferred item 0
addi $t2, $t2, 4
addi $t0, $t0, 4 # point at item 1

lw $t1, 0($t2)
sw $t1, 0($t0) # transferred item 1
addi $t2, $t2, 4
addi $t0, $t0, 4 # point at item 2

lw $t1, 0($t2)
sw $t1, 0($t0) # transferred item 2
addi $t2, $t2, 4
addi $t0, $t0, 4 # point at item 3

lw $t1, 0($t2)
sw $t1, 0($t0) # transferred item 3

lw $t0, 0($sp) # restoring t regs
lw $t1, 4($sp)
lw $t2, 8($sp)
addi $sp, $sp, 12

jr $ra 

# end of function


generate_rkey:




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
