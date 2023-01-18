nop
nop
nop
nop
nop
# Air Hockey Scorekeeping and LED/Sound Control
# Registers:
# $r1: player 1's score to be displayed
# $r2: player 2's score to be displayed
# $r3: player 1's goal sensor
# $r4: player 2's goal sensor 
# $r5: turn on player 1 side LEDs
# $r6: turn on player 2 side LEDs
# $r8: minutes value of timer
# $r9: tens value of timer
# $r10: ones value of timer
# $r11: intermediate score for player 1
# $r12: intermediate score for player 2



# initialize $r14 to 9 for checking score limit later
addi $r14, $r0, 9

# game loop - only leave when someone scores or to adjust output values
# upper module generates timer
# game restarted by reset sanwa
gameloop: nop
# if either break beam goes off, branch to handle the player who scored accordingly
# break beam inputs to the processor should be inverted - pulled low when someone scores, should be high here
bne $r4, $r0, p1scored 
bne $r3, $r0, p2scored
# if the LEDs are on from a score, branch to turn off
bne $r5, $r0, LED1off
bne $r6, $r0, LED2off
# restart the game loop as long as the timer digits haven't all hit 0
bne $r8, $r0, gameloop
bne $r9, $r0, gameloop
bne $r10, $r0, gameloop

# game over: turn on all LEDs (and sound)
# only reach here if the timer has expired (none of the 3 above bne's were taken) or a player scores >9
gameover: nop
# turn on both LEDs
addi $r5, $r5, 1
addi $r6, $r6, 1
# do nothing forever (player needs to reset the game manually)
wait: nop
j wait


# player 1 scored - increment their score, turn on player 2's LEDs, (turn on sound)
p1scored: nop
# trial addition to player 1 score
addi $r11, $r11, 1
# if player 1 scored more than 9, end the game
blt $r14, $r11, gameover
# their score is still <=9, display it
add $r1, $r0, $r11
# turn on player 2 side LEDs
addi $r6, $r6, 1
j buffer


# player 2 scored - increment their score, turn on player 1's LEDs (turn on sound)
p2scored: nop
# trial addition to player 2 score
addi $r12, $r12, 1
# if player 2 just scored more than 9, end the game
blt $r14, $r12, gameover
# total still <=9, display score
add $r2, $r0, $r12
# turn on player 1 side LEDs
addi $r5, $r5, 1
j buffer


# do nothing while either beam is being broken
buffer: nop
bne $r3, $r0, buffer
bne $r4, $r0, buffer
j gameloop


# turn off LEDs
LED1off: nop
sub $r5, $r5, $r5
j gameloop

LED2off: nop
sub $r6, $r6, $r6
j gameloop