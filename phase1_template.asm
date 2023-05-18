.data  
T0: .space 4                           # the pointers to your lookup tables
T1: .space 4                           
T2: .space 4                           
T3: .space 4                           
fin: .asciiz "C:\\Users\\Emre Eser\\Desktop\\cs401_term_project\\tables.dat" # put the fullpath name of the file AES.dat here
buffer: .space 5000                    # temporary buffer to read from file

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


# 1024 LUT values -- each 4 bytes: total 4096 bytes
# ascii (hex): 2c = ',', 20 = ' ' --> need to filter these values out!!!

lbu $s2, 0($s1)
lbu $s2, 1($s1) # read next byte

# FUNTIONS TO IMPLEMENT
# read byte
	# params: address, offset
# read word
	# address
#

# NEED TO ELIMINATE SPACES AND COMMAS


Exit:
li $v0,10
syscall             #exits the program

