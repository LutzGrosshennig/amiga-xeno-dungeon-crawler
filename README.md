# amiga-xeno-dungeon-crawler (30th anniversary)

Do you know the game 'Xenomorph' (c) 1990 by Pandora or 'Dungeon Master', 'Eye of the Beholder'? Back in 1990 some of my friends and me where enjoying playing these games on our Amigas whenever we could.

We thought: How cool would it be to be able to link two Amigas using the serial port and have a kind of very early CoOp (I dont think that this term even existed at the time).

So we startet this project. I did the coding and the others supplied some graphics. These are early placeholder type graphics so we could get started. Unfortunatly we started studying in different cities and our paths slowly separated.

So this is basically a tech-demo because its missing all the game mechanics and artwork/sounds that would make a game. As far as I can tell (please correct me if I am wrong) it is the first ever "multiplayer" approach in this genre.

# Screenshots

## In game (placeholder graphics)

![Screenshot](https://github.com/LutzGrosshennig/amiga-xeno-dungeon-crawler/blob/main/images/ScreenShot.png)

## Alternate tile settings

![Screenshot](https://github.com/LutzGrosshennig/amiga-xeno-dungeon-crawler/blob/main/images/AlternateTileset.PNG)

## Inventory concept art

![Screenshot](https://github.com/LutzGrosshennig/amiga-xeno-dungeon-crawler/blob/main/images/Inventory.gif)

## Multiplayer (serial link)

![Screenshot](https://github.com/LutzGrosshennig/amiga-xeno-dungeon-crawler/blob/main/images/Multiplayer.gif)

# Notes about the code

Bear in mind that this code is 30 years old, there was no Internet in those days to search for information (BBS where the closest thing to a internet) so you had to either a.) buy rather expensive books (most of them where not worth the money) or b.) reverse engineer existing code.
All I needed to know about the serial.device I learned by reverse engineering a terminal programm (I cant recall which one). Its basically my first attempt to do remote process communication. Its flimsy and lacks all what you need to do a reliable communication protocol but it does work if you follow the usage guidelines.

## But why are your old assembly sources all in CAPS?

30 years ago the only affortable and durable "backup" solution my younger self had access to, where paper hardcopies. 9 pin dotmatrix printers of that time where terrible printing lowercase letters! Having everything in uppercase was far more readable on printed listings.

## How to build

My favorite assembler was the "Profimat" which already came close to a full IDE. It should not be hard to port the code to a different assembler. Just make sure the data section goes into chip ram.

# How to run it

Unfortunatly I dont own a real amiga anymore but I managed to run two instances of WinUAE on my system and was able to link them using the WinUAE build in "WinUAE inter-process serial port" emulation.

## WinUAE settings for the solo/server instance

Under IO-Port select the "WinUAE inter-process serial port". WinUAE will show "(master)" for the first instance automatically.
Untick all the box below the selection box!

![WinUAE_Server](https://github.com/LutzGrosshennig/amiga-xeno-dungeon-crawler/blob/main/images/WinUAE-SerialCrossOver_1.png)

## WinUAE settings for the client instance

For the second instance (it can be the same config file) again select the "WinUAE inter-process serial port". This time WinUAE will automatically add "(slave)" to the selection.
Untick all the box below the selection box!

![WinUAE_Client](https://github.com/LutzGrosshennig/amiga-xeno-dungeon-crawler/blob/main/images/WinUAE-SerialCrossOver_2.png)

## Start the solo/server instance

You can now start the solo/server instance by running the executable from a CLI. Just type "xeno" and hit enter. Without additional parameters the game will launch and you can start playing. It does listen to incoming traffic via the serial port automatically become a server.
If your solo/server instance is running switch over to the 2nd WinUAE instance and start the excecutable with an additional argument (any will do) like for example "xeno c". 

Both instances should be linked now and you can start chaseing yourself.

## Requirements

It was developed on a Amiga 2000 (A) with 1MB Ram (512 kb Chip & 512kb Slow) running KS 1.2 and also tested an differend Amiga 500 KS 1.2/1.3. Because the serial.device is used, you must make sure its available under DEVS:

# Does it work on real hardware?

Yes, we used to link two Amiga 500 using a cross over cable back then. I am only unsure if I had to lower the baud rate from 19200 to 9600.


# Whats next?

Bear in mind that this code is 30 years old, I did not know better back then, I do now :-) and si I startet a new project called 'Xenomorph 2409'

You can watch a work in progress version of "Xenomorph 2409" on YouTube:

[![](http://img.youtube.com/vi/phD2-d7OQRk/0.jpg)](http://www.youtube.com/watch?v=phD2-d7OQRk "")

Complete devlog is here:
https://www.youtube.com/playlist?list=PLS4ewnjLUh_FoZtXrj5tolTsnKdIVJtbR


Stay tuned, 
Lutz