# Stacker-like MicroPAD Game



This project is an extracurricular project I made using the MicroPAD (uPAD) from EEL4744, Introduction to Microprocessors. The board utilizes a ATxmega128A1U microcontroller with the Out-of-the-Box Switch-LED backpack installed. The whole project was written in Microchip Atmel Studio using the assembly language associated with the ATxmega128A1U. See appendix for supporting documents.



This game was inspired by the arcade game Stacker (insert hyperlink), except it is 1 dimensional. The goal of the game is to line up the cursor LED(s) with the target LED (which is stationary). Each time the user presses the button when the cursor and target overlap, the player gets a point added to their current score. The player can check their current score at any time. If their current score is greater than the high score, the high score is updated to the current score and is saved between games. The game has a set number of levels. However, the last few levels are so difficult that a human would not be able to complete them, thus creating a similar "kill screen" to the original version of Tetris (insert hyperlink).



### Game Flow



The game have 4 states:

* Title Screen,
* Gameplay,
* Score display, 
* and High-score Display



(insert image of game flow here)

Image curtesy of ChatGPT.



#### Video Demonstration



Here is a demonstration video of me playing the game. I showcase the title screen, play until I reach 6 points, check the score, play until I reach 15 points, and then I lose and check the high score from the title screen.



(insert video link)



Here I demonstrate the "kill screen" of the game:



(insert video link)



#### Appendix



For additional information on the development process of the game, see the psudocode.md file.



ATxmega128A1U documentation:

* https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-8331-8-and-16-bit-AVR-Microcontroller-XMEGA-AU\_Manual.pdf
* https://ww1.microchip.com/downloads/en/DeviceDoc/ATxmega128A1U-64A1U-Data-Sheet-DS40002058A.pdf
* https://ww1.microchip.com/downloads/aemDocuments/documents/MCU08/ProductDocuments/ReferenceManuals/AVR-InstructionSet-Manual-DS40002198.pdf



Special thanks to Dr. Schwartz!





