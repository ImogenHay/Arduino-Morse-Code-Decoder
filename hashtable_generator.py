#This is a python script that creates the following hash table for morse code bytes which is used in the decoder

#.byte _, _, _, _, _, _, _, _, CHAR_T, _, _, _, CHAR_M, _, CHAR_O, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 
#_, _, _, _, _, _, _, _, _, CHAR_G, CHAR_Q, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_Z, _, _, _, _, _, _, _, _, _, _, _, 
#CHAR_N, _, CHAR_K, CHAR_Y, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_C, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_D, 
#CHAR_X, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_B, _, _, _, _, _, _, _, CHAR_E, _, _, _, CHAR_A, _, CHAR_W, CHAR_J, _, 
#_, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_P, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_R, _, _, _, _, _, _, _, _, _, _, _, 
#_, _, _, _, CHAR_L, _, _, _, _, _, _, _, _, _, _, _, CHAR_I, _, CHAR_U, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_F, _, 
#_, _, _, _, _, _, _, _, _, _, _, _, CHAR_S, CHAR_V, _, _, _, _, _, _, _, _, _, _, _, _, _, _, CHAR_H

print(".byte ", end="")

alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

MORSE = [
    "10000100",
    "01111000",
    "01011010",
    "01101000",
    "10000000",
    "11010010",
    "00101100",
    "11110000",
    "11000000",
    "10000111",
    "01001010",
    "10110100",
    "00001100",
    "01001000",
    "00001110",
    "10010110",
    "00101101",
    "10100100",
    "11100000",
    "00001000",
    "11000010",
    "11100001",
    "10000110",
    "01101001",
    "01001011",
    "00111100"]

MORSE_OUT = []

for i in MORSE:
    MORSE_OUT.append(int(i, 2))

li = {}

for i in range(0, 255):
    a = False
    for i2 in range(0, len(MORSE_OUT)):
        if MORSE_OUT[i2] == i:
            print("CHAR_"+alpha[i2]+", ", end="")
            li[alpha[i2]] = MORSE[i2]
            a = True
    if a == False:
        print("E, ", end="")

print()
print(li)
