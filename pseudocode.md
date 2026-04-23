# General Game Design



### Stage 1: Menu Display

* Loads from program memory a light pattern that repeats
* Use Z pointer to load in data and display at around 5Hz
* Probably use its own clock module
* Can be interrupted by SLB S1 in order to start the game (no debouncing necessary)



### Stage 2: Gameplay loop

* The main gameplay of the program will involve a cursor of a varied size bounce back and forth across the PORTC LEDs. The goal is to land the cursor on the target. The target is an LED that is exactly a width of 1. The cursor may be between 1-3 or 4 LEDs wide. The cursor will decrease in size and increase in speed as the user continues through the game. Additionally, the PORTD LED will progressively become more and more red as the game progresses (It will start at blue), giving the user additional information about where they are in the game without having to go to stage 4. Eventually, the user will max out the counter and there will have to be some Tetris-style kill screen. If the user misses the target with the cursor, the game will restart from level 0 (and the memory pointer will be reset). However, the user's score will be saved as a 1 byte address in data memory. This will be elaborated on later.
* Loads from program memory the stage that it is on (eventually gonna have a Tetris-style, not humanly possible stage)
* To do this, there needs to be a mapping of difficulty for each byte of program memory (figure out later probably)
* The following qualities will be determined by the byte of information described in this section of program memory:
*  	- Speed of cursor
*  	- width of cursor
*  	- color of LED
*  	- The actual level # will not be kept in the program memory, as this will be determined by an external counter
* 
* When the user fails, the program will go back to stage 1
* Also, when SLB S2 is pressed, the program will switch to stage 4.
* At any point, the program should be able to expect an interrupt from SLB S1, which will cause the next stage of the game.





### Stage 3: Win/Lose condition and the determination of the target position

* If the user does not land on the target, the program stops moving the cursor for a few moments, all LEDs get toggle on a off a few times, and then the program branches to Stage 1. The outro sequence might need to be stored in program memory...
* If the user correctly lands the cursor on the target, the game will either pause or continue moving with the updates on the next frame (whatever is easier to program for the time being). In addition to this, it will increment the score counter and, if it is a high score, update the data memory. Furthermore, the next "level" will be loaded from program memory (Z pointer incremented and loaded) and the implications of that updated (increase in speed, decrease in cursor width, etc).



##### Determination of the Target Position:

* In order for the game to be at all fun, the target must move from level to level. This could be programmed with program memory (which I might do initially), but ideally it should be completely random. I have no idea how to implement randomness in assembly, so this will be fun. Really, the determination of the Target Position is just a random number 0-7, which I am sure I could do by checking some external timer and divide by something (idk, I'll think about this later). For now, we can just program the position into program memory with the rest of the level instructions.



### Stage 4: Check High Score

* During either Stage 1 or Stage 2, the user should be able to click SLB 2 (without debouncing necessary) to switch to high score checking mode. In this mode, the LEDs will display the static current score (coming from Stage 1) or the static high score (if coming from Stage 2).
* This would be an interrupt that could happen at any time during Stage 1 or 2, so the variables should be able to be stored when resuming those stages.
* When S1 is pressed, the stage will be updated to either Stage 1 or Stage 2 depending on where the user is coming from. This input needs to be debounced.



I think that is it for the description for now...



Lets move on to the actual pseudocode!



### Stage 1: Pseudocode

* Basically just lab 2 but easier



Initialize all interrupts (S1, S2, timer C and D overflow for gameplay loop and animation respectively);

Initialize program memory with appropriate animation frames;

Initialize stack;

Initialize I/O ports;

Initialize Z pointer to correct place in memory for animation;

Initialize Timer D (and period;

Start timer D;

define Animation\_start\_address as a constant;

define level\_start\_address as a constant;





while (true){

 	load data from Z;

 	if (Z == 0x00 (end of animation)){

 		Z = start address;

 	}

 	Update PORTC from Z;

 	Increment Z;

 	Wait until clock overflow before moving onto next frame;

}

function S1\_Interrupt{

 	// This all has to be debounced...

 	Set Z to level\_start\_address;

 	Stop D timer;

 	branch to Stage 2;

}

function S2\_Interrupt{

 	Set Z to level\_start\_address;

 	Stop D timer;

 	Store info in a register of where you came from (Stage 1 or 2);

 	branch to Stage 4;

}



### Stage 2/3: Pseudocode



Initialize timer C;



Load level information from Z;

// no need to check for end of z (user should be dead by then)

initialize timer period from level information;

initialize cursor width from level information;

initialize CCA and CCB for LED color from level information;

initialize target position from level information (to start off with);

while (true){

 	if (moving right \&\& cursor position is not all the way to the right){

 		shift cursor right;

 	}

 	else if (not moving right \&\& cursor position is not all way to the left){

 		shift cursor left

 	}

 	else if (cursor position is all the way left){

 		moving right = true;

 	}

 	else if (cursor position is all the way right){

 		moving right = false;

 	}

 	update PORTC based on cursor;

 	update PORTC based on target;

 	wait for timer to overflow;

}



function S1\_Interrupt{

 	// This all has to be debounced...

 	if (target is within range of cursor){

 		increment Z;

 		increment counter variable;

 		if (counter > high score){

 			store counter in high score in data memory;

 		}

 		branch back to Stage 2;

 	}

 	if (target is not within range of cursor){

 		Set Z to Animation\_start\_address;

 		play outro animation;

 		branch back to stage 1;

 	} 

}

function S2\_Interrupt{

 	Stop C timer;

 	Store info in a register of where you came from (Stage 1 or 2);

 	branch to Stage 4;

}



### Stage 4: Pseudocode



while (true){

 	if (return register is 1){

 		Load in high score from data memory;

 	}

 	else{

 		load in current score;

 	}

 	PORTC LEDs = whatever score;

}

function S1\_Interrupt{

 	// This all has to be debounced...

 	if (return register is 1){

 		Set Z to Animation\_start\_address;

 		branch back to Stage 1;

 	}

 	if (return register is 2{

 		turn on clock C;

 		branch back to stage 2;

 	} 

}



TIMER\_LOOP5:

; Load OVFIF flag

 	lds r16, TCC0\_INTFLAGS



 	;Check SL2

 	lds r17, PORTF\_IN

 	sbrs r16, 0

 	rjmp TIMER\_LOOP5



 	; If pressed and value in r24 is true

 	sbrc r17, 2

 	cpi r24, 1

 	breq FINISH\_DEBOUNCING ; increment r16 (counter)



CONTINUE2:

 

 	; if value is pressed, set r20 to tue

 	sbrs r17, 3

 	ldi r24, 1



 	; Turn off timer

 	ldi r16, TC\_CLKSEL\_OFF\_gc

 	sts TCC0\_CTRLA, r16

 	; reset flag

 	ldi r16, 0b00000001

 	sts TCC0\_INTFLAGS, r16

 	rjmp END\_DEBOUNCE



FINISH\_DEBOUNCING:

 	ldi r24, 0 ; reset pressed flag (false)

 	rjmp CONTINUE2

END\_DEBOUNCE:

