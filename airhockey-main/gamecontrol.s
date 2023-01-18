nop
nop
nop
nop
nop
# Air Hockey Scorekeeping and LED/Sound Control
# Registers:
# $r1: player 1's score
# $r2: player 2's score
# $r3: player 1's goal sensor
# $r4: player 2's goal sensor 
# $r5: turn on player 1 side LEDs
# $r6: turn on player 2 side LEDs
# $r7: turn on sound (PWM generator)



# game loop - only leave when someone scores or to adjust output values
# upper module handles timer and ends the game
# game restarted by reset button
gameloop: nop
# if either break beam goes off, branch to handle the player who scored accordingly
# break beam inputs to the processor should be inverted - pulled low when someone scores, should be high here
bne $r4, $r0, p1scored 
bne $r3, $r0, p2scored
# if the LEDs or sound are on from a score, branch to turn off
bne $r5, $r0, LED1off
bne $r6, $r0, LED2off
bne $r7, $r0, soundoff
j gameloop


# player 1 scored - increment their score, turn on player 2's LEDs, turn on sound
p1scored: nop
addi $r1, $r1, 1
addi $r6, $r6, 1
addi $r7, $r7, 1 
j gameloop


# player 2 scored - increment their score, turn on player 1's LEDs, turn on sound
p2scored: nop
addi $r2, $r2, 1
addi $r5, $r5, 1
addi $r7, $r7, 1
j gameloop


# turn off LEDs
LED1off: nop
sub $r5, $r5, $r5
j gameloop

LED2off: nop
sub $r6, $r6, $r6
j gameloop

# turn off sound
soundoff: nop 
sub $r7, $r7, $r7 
j gameloop