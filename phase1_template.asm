.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\Emre Eser\\Desktop\\cs401_term_project\\tables.dat" # put the fullpath name of the file AES.dat here
buffer: .space 5000                    # temporary buffer to read from file

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
li   $a2, 4096     # hardcoded buffer length
syscall            # read from file

move $s0, $v0	   # the number of characters read from the file
# la   $s1, buffer   # address of buffer that keeps the characters
addi $sp, $sp, -16
sw $s0, 0($sp) # push s regs
sw $s1, 4($sp)
sw $s2, 8($sp)
sw $s3, 12($sp)

jal get_num_val # function call

lw $s0, 0($sp) # restore s regs
lw $s1, 4($sp)
lw $s2, 8($sp)
lw $s3, 12($sp)
addi $sp, $sp, 16
j Exit

# 1024 LUT values -- each 4 bytes: total 4096 bytes
# each LUT will contain 256 entries

# S1: ADDRESS OF BUFFER (set inside get_num_val, passed to func in a1)


#### FUNCTION ####
#### gets the numeric value of table entry pointed by $a1
# a1 must point to the 0 character in 0x...
get_num_val:
addi $sp, $sp, -12 # push t regs
sw $t0, 0($sp)
sw $t1, 4($sp)
sw $t2, 8($sp)

li $t1, 0
li $s3, 0
move $s1, $a1
addi $s1, $s1, 2 # initial 0x # every 8 iterations: += 4
func_main:
lbu $a2, 0($s1) # load from buffer location
li $a1, 87 # so that a corresponds to 10
bge $a2, $a1, alpha_hex
li $a1, 48 # so that ascii 0 corresponds to numeric 0
bge $a2, $a1, alpha_hex

main_p2:
sll $s3, $s3, 4 # one hex digit left shift
or $s3, $s3, $v0
addi $s1, $s1, 1 # buffer address increment
addi $t1, $t1, 1 # counter increment
li $t2, 7
ble $t1, $t2, func_main
move $v0, $s3 # returns in v0

lw $t0, 0($sp) # restore t regs
lw $t1, 4($sp)
lw $t2, 8($sp)
addi $sp, $sp, 12

jr $ra # return here

alpha_hex: # args in: $a2, $a1, returns in $v0
sub $a2, $a2, $a1
move $v0, $a2
j main_p2

# NOTE: RESET @ EVERY 8 CHARS
# NEED TO ELIMINATE SPACES AND COMMAS

#### END OF FUNCTION!!!!

Exit:
li $v0,10
syscall             #exits the program

