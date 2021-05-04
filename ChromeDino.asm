.data 0x10010000 			# Start of data memory
a_sqr:	.space 4
a:	.word 3

.text 0x00400000                # Start of instruction memory
.globl main

#############################################################
#	Sprite Mapping                                      #
#	0 -> Dino                                           #
#	1 -> Dino Run 1                                     #
#	2 -> Dino Run 2                                     #
#	3 -> Cactus                                         #
#	4 -> Road                                           #
#	5 -> White					      #
#	6 -> Bird                                   	      #		
#	7 -> Road 1                                         #	
#	8 -> Roda 2                                         #	
############################################################

#####################################
#	Register Mapping	
#	s0	->	Scan Line
#	s1	-> 	Seed
#	s2	->	Cactus Spawn Counter
#	s3	-> 	Bird Spawn Counter
#	s4	-> 	Dino Jump State
#	s5	-> 	Dino Jump Counter
#	s6	-> 	Dino Animation Counter
#	s7	-> 	Score
####################################
main:
	lui     $sp, 0x1001         # Initialize stack pointer to the e1024th location above start of data
	ori     $sp, $sp, 0x1000    # top of the stack will be one word below
                                    #   because $sp is decremented first.
       	addi    $fp, $sp, -4        # Set $fp to the start of main's stack frame
       		
       	jal	set_up

       	
animation_loop: 

	li	$t2, 39
	slt 	$t1, $t2 , $s0      # checks if $s0 > $s1
	beq	$t1, 1, reset_scan_line #Reset $s0 to 1

	# If Scan Line in Dino (X=5) then skip by 2 
	beq 	$s0, 	5,	jump_scan_line_by_2
	
	# Get Char at current scan line X
	move	$a1, 	$s0
	li	$a2,	19
	jal	getChar_atXY
	
	# Move current sprite to left
	move	$a0,	$v0
	jal	move_sprite_left
	
	move	$a1, 	$s0
	li	$a2,	18
	jal	getChar_atXY
	
	move	$a0,	$v0
	jal	move_sprite_left
	
	move	$a1, 	$s0
	li	$a2,	20
	jal	getChar_atXY
	
	move	$a0,	$v0
	jal	move_sprite_left
	
	#jal	increment_score
	
	# Advance Scan line
	addi 	$s0, $s0, 1
	
	j 	key_loop

key_loop:	
	jal 	get_key			# get a key (if available)
	beq	$v0, $0, animation_loop	# 0 means no valid key	

jump_animation:
	bne	$v0, 5, animation_loop 	# If key not pressed then go back to animation loop	
	beq	$s4, 1, animation_loop 	# if jump state is 1 then go back to animation loop else continue
	
	# Check if Sprite above Dino is a bird, if so game end
	
	li	$a0, 191113
       	jal 	put_sound
	
	move	$a0,	$s1
	jal	random_num_generator
	move	$s1,	$v0
	
	#li	$a0, 6
	li	$a1, 5
	li	$a2, 18
	jal	getChar_atXY
	
	beq	$v0, 6, game_over
	
	# Get things one in front in layer 19
	#li	$a1, 6
	#li 	$a2, 19
	#jal	getChar_atXY
	
	# Put that sprite at current
	li	$a0, 5
	li	$a1, 5
	li 	$a2, 19
	jal 	putChar_atXY
	
	# Put Dino 0 above
	li	$a0, 0
	li	$a1, 5
	li	$a2, 18
	jal 	putChar_atXY
	
	li	$s4, 1		# Reset Jump State
	li	$s5, 5		# Reset Jump Counter
	
	j 	animation_loop


game_over: 


	# Hot Fix for Sprite Issue
	
	addi	$t5,	$s6,	6
	move 	$a0,	$t5
	li	$a1,	4
	li	$a2	20
	jal	putChar_atXY

	jal 	sound_off
	
	li	$a0, 340530
       	jal 	put_sound
       	
       	li	$a0,	25
       	jal 	pause
       	
       	jal 	sound_off
       	
       	li	$a0, 382219
       	jal 	put_sound
       	
       	li	$a0,	25
       	jal 	pause
       	
       	jal	sound_off
       	
       	j 	game_reset_loop
       	
game_reset_loop: 
	jal 	get_key			# get a key (if available)
	beq	$v0, $0, game_reset_loop	# 0 means no valid key	
	bne	$v0, 6, game_reset_loop
	jal 	set_up
	j	animation_loop

reset_scan_line: 	
	
	# Update Seed(Random Number) Every loop
	
	addi	$t5,	$s6,	6
	move 	$a0,	$t5
	li	$a1,	39
	li	$a2	20
	jal	putChar_atXY
	
	
	move	$a0,	$s1
	jal	random_num_generator
	move	$s1,	$v0
	
	#Handle Dino Jumping
	jal 	handle_dino_jump
	
	#Reset Scan Link
	li	$s0, 	1
	
	#increment score
	addi 	$s7, $s7, 1
	move	$a0,	$s7
	#jal 	put_segs
	
	#Spawn Cactus if $s2 is at 0
	jal 	spawn_cactus
	
	#Spawn Cactus if $s3 is at 0
	jal 	spawn_bird
	
	#update $s2
	addi 	$s2, 	$s2, 	-1
	
	#update $s3
	addi 	$s3, 	$s3, 	-1
	
	
	# update $s5
	addi	$s5, 	$s5, 	-1
	
	li	$a0, 	8 
	jal 	pause
	
	jal 	sound_off
		
	j	animation_loop

jump_scan_line_by_2: 

	jal	handle_dino_in_layer_18
	
	jal 	handle_dino_in_layer_19
	
	jal 	handle_layer_17
	
	addi	$s0, $s0, 2
	
	j 	animation_loop
	
end:
	j	end          	# infinite loop "trap" because we don't have syscalls to exit

############################## Methods ########################################################################


.text
####################### Random Number Generator

	#########################
	#	$a0 -> Seed
	#	$v0 -> New Seed
	#########################


random_num_generator: 
	
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
	
    	move	$v0, $a0	     # Save Current Rand
    	
	addi	$v0, $v0, 17	     # Adding Low Prime to Seed and Store in Seed
	li	$t1, 31		     # Load High Prime
	slt 	$a0, $t1, $v0	     # if Sum greater than high prime, sebtract
	beq	$a0, 1, subtract_rand_2	
	j	return_random_num
	
subtract_rand_2: 
	addi	$v0, $v0, -31 	     # Subtract 41 from current sum
	j	return_random_num
	
return_random_num:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra
################### Random Number Generation


################### Move Sprite Left

	######################
	#	a0 -> Sprite Num 
	#	a1 -> Sprite X 
	#	a2 -> Sprite Y
	#	Uses get and put char to move the sprite left
	######################
move_sprite_left: 
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    	
    	# Save Current sprite
    	move	$v0,	$a0
    	
    	# Load White Sprite
    	li	$a0,	5
    	
    	# Put White Sprite at this current place
    	jal	putChar_atXY
    	
    	
    	move	$a0,	$v0
    	
    	# Move to left
    	addi 	$a1, $a1, -1
    	
    	# Pur sprite at X-1
    	jal	putChar_atXY

	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra
################### Move Sprite Left End


################## Spawn Cactus ##################################
spawn_cactus: 
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    	
    	# if cactus counter not equal to 0 return 
    	bne	$s2, 	0,	spawn_cactus_done
    	
    	li	$a1,	39
    	li	$a2,	18
    	j	check_feasible_cactus_spawn_loop 
    	
check_feasible_cactus_spawn_loop:
	beq	$a1, 	35, 	spawn_cactus_actual	# if no bird till X=35 then spawn bird
	
	# Get	sprite at current X and Y = 19
	jal	getChar_atXY
	
	# if bird at current X then wait for cactus to spawn 
	beq	$v0,	6,	spawn_cactus_wait 	
	
	# Decrement X loop
	addi	$a1,	$a1,	-1
	
	# Loop
	j	check_feasible_cactus_spawn_loop 

spawn_cactus_wait: 
	addi 	$s2, $s2, 7
	j	spawn_cactus_done
    	
spawn_cactus_actual:  
    	#update cactus coutner with current seed
    	
    	
    	# Final Check
    	li	$a1,	39
    	li	$a2,	18
    	jal 	getChar_atXY
    	
    	beq	$v0, 	6,  spawn_cactus_done	
    	
    	
    	
    	add	$s2, 	$s2, 	$s1
    	
    	#Spawn Cactus
    	li	$a0,	3
    	li	$a1,	39
    	li	$a2, 	19
    	jal 	putChar_atXY
    	
    	# return
    	j	spawn_cactus_done
    	
spawn_cactus_done:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra
######################################################################

################################## Spawn Bird ########################
spawn_bird: 
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame

	# if cactus counter not equal to 0 return 
    	bne	$s3, 	0,	spawn_bird_done
    	
    	# Load X = 38
    	li	$a1,	38
    	li	$a2,	19
    	j	check_feasible_bird_spawn_loop

check_feasible_bird_spawn_loop:
	beq	$a1, 	35, 	spawn_bird_actual	# if no cactus till X=35 then spawn bird
	
	# Get	sprite at current X and Y = 19
	jal	getChar_atXY
	
	# if 	cactus at current X then wait for bird to spawn 
	beq	$v0,	3,	spawn_bird_wait 	
	
	# Decrement X loop
	addi	$a1,	$a1,	-1
	
	# Loop
	j	check_feasible_bird_spawn_loop

spawn_bird_wait: 
	# Wait 10 more scan line loops to spawn bird
	addi	$s3,	$s3,	7	
	j	spawn_bird_done

spawn_bird_actual:   	
    	#update cactus coutner with current seed
    	add	$s3, 	$s3, 	$s1
    	
    	li	$a1,	39
    	li	$a2,	19
    	jal 	getChar_atXY
    	
    	beq	$v0, 	3,  spawn_cactus_done	
 
    	#Spawn Bird
    	li	$a0,	6
    	li	$a1,	39
    	li	$a2, 	18
    	jal 	putChar_atXY
    	
    	j	spawn_bird_done
    	
spawn_bird_done:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	 $ra	
######################################################################

########################### Functions to Handle jump scan line by 2 ###################################

handle_dino_in_layer_19: 
	
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    	
    	# if jumoing return since not in layer 19
    	beq	$s4, 	1,	handle_dino_in_layer_19_done
    	
    
	# If there is a cactus at the X=6 then game over!
	li	$a1, 6
	li	$a2, 19
	jal	getChar_atXY
	
	beq	$v0, 3, game_over	# TODO: Add sound
	
	#else move layer 18 properly
	
	# Get sprite above Dino
	li	$a1, 5
	li	$a2, 18
	jal	getChar_atXY
	
	# Put that sprite at X=4
	move 	$a0, $v0
	li	$a1, 4
	li	$a2, 18
	jal 	putChar_atXY
	
	# Get sprite at X=6
	li	$a1, 6
	li	$a2, 18
	jal	getChar_atXY
	
	# Put that sprite above Dino
	move 	$a0, $v0
	li	$a1, 5
	li	$a2, 18
	jal 	putChar_atXY
	
	# Update Dino Sprite
	move 	$a0, $s6
	li	$a1, 5
	li	$a2, 19
	jal 	putChar_atXY
	
	jal 	increment_animation
			
			
	j 	handle_dino_in_layer_19_done

handle_dino_in_layer_19_done:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra
###########################################################
handle_dino_in_layer_18: 
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    	
    	# if jumoing return since not in layer 19
    	beq	$s4, 	0,	handle_dino_in_layer_18_done
    	
    	li	$a1, 6
	li	$a2, 18
	jal	getChar_atXY
	
	beq	$v0, 6, game_over	# TODO: Add sound
    	
    	
    	li	$a1, 5
	li	$a2, 19
	jal	getChar_atXY
	
	move 	$a0, $v0
	li	$a1, 4
	li	$a2, 19
	jal 	putChar_atXY
    	
    	li	$a1, 6
	li	$a2, 19
	jal	getChar_atXY
	
	move 	$a0, $v0
	li	$a1, 5
	li	$a2, 19
	jal 	putChar_atXY
    	
    	j 	handle_dino_in_layer_18_done
	

handle_dino_in_layer_18_done:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra


handle_layer_17:
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    	
    	li	$a1, 5
	li	$a2, 20
	jal	getChar_atXY
	
	move 	$a0, $v0
	li	$a1, 4
	li	$a2, 20
	jal 	putChar_atXY
    	
    	li	$a1, 6
	li	$a2, 20
	jal	getChar_atXY
	
	move 	$a0, $v0
	li	$a1, 5
	li	$a2, 20
	jal 	putChar_atXY
    	
    	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra

    	
    	
	

#############################################################################################

################################ Handle Dino Jump ##########################################

handle_dino_jump: 
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    	
    	
    	beq	$s4, 	0, 	handle_dino_jump_done # if not jumping return
    	bne 	$s5, 	0,	handle_dino_jump_done # If jump counter not equal to 0 return
    	
    	
    	li	$s4, 	0	# Set jump state to 0 (Not Jumping)
    	li	$s5, 	5	# Reset Counter TODO
    	
    	# If Cactus below then game end TODO
    	li	$a1, 5		
	li	$a2, 19			
	jal	getChar_atXY
	beq	$v0, 3, game_over
	
	# Handle Dino Sprites not working properly:; TODO Maybe fixed with refactored code
	
	# Get sprite in layer 18 one in front
	li	$a1, 6		
	li	$a2, 18		#Dino Y val	
	jal	getChar_atXY
	
	
	# Replace with white
	li	$a0, 5
	li	$a1, 6		
	li	$a2, 18		#Dino Y val
	jal	putChar_atXY	#Put white sprite 
	
	# Move Sprite to current	
	move	$a0, $v0	#Load Sprite
	li	$a1, 5		
	li	$a2, 18		#Dino Y val
	jal	putChar_atXY	
	
	# Put Dino Down
	move	$a0, $s6		#Load Dino Sprite
	li	$a1, 5
	li	$a2, 19
	jal	putChar_atXY	#Put dino Sprite 
	
	j 	handle_dino_jump_done

	

handle_dino_jump_done:
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra

######################################################################################


########################## Animate Dino #############################################

increment_animation: 

	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
    
	addi 	$s6,	$s6,	1
	
	beq	$s6,	3,	reset_animation_counter
	
	j	increment_animation_done

reset_animation_counter: 
	li	$s6,	1
	j	increment_animation_done
	
increment_animation_done: 
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra
####################################################################################

set_up: 
	addi    $sp, $sp, -8        # Make room on stack for saving $ra and $fp
    	sw      $ra, 4($sp)         # Save $ra
    	sw      $fp, 0($sp)         # Save $fp
    	addi    $fp, $sp, 4         # Set $fp to the start of proc1's stack frame
  	li	$s0,	0
  	j 	clear_loop
  	
clear_loop: 
	beq	$s0, 39, value_set_up
	
	li	$a0,	5
	
	move	$a1, 	$s0
	li	$a2,	18
	jal	putChar_atXY
	
	li	$a2,	19
	jal	putChar_atXY
	
	addi	$s0, $s0, 1
	
	j 	clear_loop
	
value_set_up: 
	li	$s0, 	1	# Initialize Scan Line at 1
       	li	$s1, 	10	# Initialize Seed at 0
       	li	$s2,	20	# Initialize Cactus Spawn Counter at 20
       	li	$s3, 	40	# Initialize Bird Spawn Counter at 40
       	
       	#Initialize Dino Variables
       	li	$s4,	0	#Initialize Dino Jump State
       	li	$s5, 	5	#Inialize Dino Jump Counter
       	li	$s6,	1	#Initialize Dino Sprite Counter 
       	li	$s7, 	0
       	
       	#	Initialize Dino at X=5 Y=19
       	li	$a0, 0
	li	$a1, 5
       	li	$a2, 19
       	jal	putChar_atXY
       	
       	
       	#Initialize Cactus at X=39 Y=19
       	li	$a0, 3
	li	$a1, 39
       	li	$a2, 19
       	jal	putChar_atXY
       	
       	j	set_up_end
       	
set_up_end: 
	addi    $sp, $fp, 4     # Restore $sp
    	lw      $ra, 0($fp)     # Restore $ra
    	lw      $fp, -4($fp)    # Restore $fp
	jr	$ra
	
		

.include "procs_board.asm"
#.include "procs_mars.asm"                # Use this line for simulation in MARS
