# Arduino-Morse-Code-Decoder
Morse code decoder for an Arduino board written in AVR assembly

This implementation can, as required, decode any
letter in the alphabet (A-Z). If the button is pressed for
15ms or longer - note that any shorter duration is
debounced - then the program will attempt to interpret
the signal.

 If the signal is 200ms or less, then a dot is
recorded; if it is longer than 200ms, then a dash is
recorded.

 If a character matching the
inputted dots and dashes is found, said character will
be output onto the display.

get_morse.S - Contains an index of each letter in the alphabet and its corresponding required
segments of the display. It converts the morse code into the character that will be output onto the display.

group_3941.S - measures button presses and hence records dots and dashes in
the correct order. Whether it records a dot or a dash is dependent on the duration of the button
press. 

Google Drive - https://drive.google.com/drive/u/0/folders/1rGUSNTzUj6L5vTpkUYxS2VYJ3LJ5qHib
