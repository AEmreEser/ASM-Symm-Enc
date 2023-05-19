.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\Emre Eser\\Desktop\\cs401_term_project\\tables.dat" # put the fullpath name of the file AES.dat here
buffer: .space 5000                    # temporary buffer to read from file

stage: .byte 4 # staging area of the lut words

.text
#open a file for writing
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
li   $a2, 4096     # hardcoded buffer length
syscall            # read from file

move $s0, $v0	   # the number of characters read from the file
la   $s1, buffer   # address of buffer that keeps the characters
la $s2, stage

# 1024 LUT values -- each 4 bytes: total 4096 bytes
# ascii (hex): 2c = ',', 20 = ' ' --> need to filter these values out!!!

# S2: ADDRESS @ STAGE

li $s3, 0
addi $s1, $s1, 2 # initial 0x # every 8 iterations: += 4
main:
lbu $a2, 0($s1)
li $a1, 87 # so that a corresponds to 10
bge $a2, $a1, alpha_hex
li $a1, 48 
bge $a2, $a1, alpha_hex
main_p2:
or $s3, $s3, $v0
sll $s3, $s3, 4 # one hex digit left shift
move $a1, $s3
addi $s1, $s1, 1
j main

alpha_hex: # argument reg'e cevir
sub $a2, $a2, $a1
move $v0, $a2
j main_p2

save:

jr $ra


addi $s1, $s1, 4 # " ,0x"


# NOTE: RESET @ EVERY 8 CHARS


# NEED TO ELIMINATE SPACES AND COMMAS


Exit:
li $v0,10
syscall             #exits the program

