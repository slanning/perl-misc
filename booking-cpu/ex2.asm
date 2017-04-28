START: LDA 1 # print the powers of 2 up to 2^15
       LDB 2
       LDD 15 # the loop index
LOOP:  MUL   # multiply A by 2
       OUTC  # print the result
       DECD  # decrement the index
       WTC 0 # store the result into memory 0
       RDA 0 # read it into A
       JDZ END
       JMP LOOP
END:   HALT
