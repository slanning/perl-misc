START: LDA 10 # count down from 10 to 0
LOOP:  OUTA
       DECA
       JAZ END
       JUMP LOOP
END:   HALT
