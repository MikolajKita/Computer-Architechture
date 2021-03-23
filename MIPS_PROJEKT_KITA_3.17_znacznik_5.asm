#-------------------------------------------------------------------------------
#author: Miko³aj Kita
# Program znajduje znacznik numer 5 z zadania 3.17
# W zadaniu zosta³o przyjête, ¿e znacznik posiada punkty (id¹c od kolejnoœci wskazówek zegara, zaczynaj¹c od P): P, X, B, C, Y 
# Opis algorytmu znajdowania znacznika w punktach, jeœli odpowiedŸ jest prawdziwa, 
# to przechodzimy do nastêpnego punktu, jeœli nie to idziemy do kolejnego pixela (powrót do punktu 1 z nowymi danymi):
# 1. WeŸ pixel
# 2. Czy pixel jest czarny?
# 3. Czy punkt s¹siaduj¹cy z lewej strony, na lewej wy¿szej przek¹tnej i górny NIE jest czarny?
# 4. Czy d³ugoœæ szerokosci do wysokosci znacznika jest równa 2?
# 5. Czy d³ugoœæ ramion znacznika jest taka sama? (jako ramie rozumiem te bardzo krótkie boki znacznika, które s¹ równej d³ugoœci na rysunku, u mnie boki YA i XB)
# 6. Czy znacznik jest ci¹g³y na swoim obwodzie? (tj. czy nie ma w obwodzie ¿adnych "dziur")
# 7. Czy w otoczeniu znacznika nie znajduje siê ani jeden punkt czarny? 
# 8. (tj. czy obwód znacznika nie styka siê w jakikolwiek sposób, nawet punktem po przêkatnej, z innym czarnym punktem/znacznikiem)
# 9. Wróc do punktu 1 z kolejnymi danymi pixela

# Program wyrzuca b³¹d, jeœli nie uda mu siê otworzyæ nazwy pliku

#-------------------------------------------------------------------------------

#only 24-bits 320x240 pixels BMP files are supported
.eqv BMP_FILE_SIZE 230454 #320*240*3 + 54
.eqv BYTES_PER_ROW 960

	.data
openerror: 			.asciiz "\n ERROR: File was not opened"
blackpoint:			.asciiz "\n BLACK POINT "
newline: 			.asciiz "\n"
space: 				.asciiz " "
word: 				.asciiz " EQUAL "
#space for the 600x50px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

fname:	.asciiz "input.bmp"
	.text
main:
	jal	read_bmp
	
	#Start in top left
	# s0 = x
	# s1 = y
	# s2 = kolor
	# s3 = x wspolrzedna punktu na lewo od potencjalnego punktu P
	# s4 = y wspolrzedna punktu, ktory jest wyzej od potencjalnego punktu P
	li	$a0, 0
	li	$a1, 239	# zaczynam od lewego gornego rogu, zeby ulatwic sobie zadanie
	la 	$s0, ($a0)
	la	$s1, ($a1)
	
loop: 	
	bgt	$s0, 319, nextrow	# jesli liczba jest wieksza od 319, to ide do nastepnego wiersza
	blt	$s1, 0, not_loop	# jesli przeszedlem wszystkie wiersze, to wychodze z funkcji
	jal	get_pixel
	la 	$s2, ($v0)
	beq	$s2, 0x00000000, around	#jesli punkt jest czarny, sprawdzamy jego otoczenie
	add	$s0, $s0, 1
	la 	$a0, ($s0)
	blt 	$s0, 319, loop	# dopoki nie przejdziemy calego wiersza to powtarzamy
	
beforeloop:			# funkcja pomocnicza do ustawiania adresu a0, poniewaz czesto uzywalem syscalla, wiec musialem zmieniac wartosci a0
	move $a0, $s0
	add $s0, $s0, 1
	j loop
	
nextrow:
	
	li $s0, 0
	la $a0, ($s0)
	sub $s1, $s1, 1
	la $a1, ($s1)
	j loop

not_loop:
	
	jal	save_bmp

exit:	
	li 	$v0,10		#Terminate the program
	syscall

around:	
	
	la $s3, ($s0)
	la $s4, ($s1) 
	sub $s3, $s3, 1 # zmienna pomocnicza, wspó³rzedna x punktu na lewo od badanego
	add $s4, $s4, 1 # zmienna pomocnicza, wspó³rzêdna y puntku w górê od badanego

	bgt $s4, 239, outofheight	# jesli y jest powyzej krawedzi, to jest to specjalny przypadek ktory sprawdzam osobno
	blt $s3, 0, outofwidth		# jesli x jest z lewej strony krawedzi, to jest to specjalny przypadek ktory sprawdzam osobno
	
	move $a0, $s3   # przygotowanie do sprawdzenia punktu na lewo od badanego
	jal get_pixel 	# sprawdzam
	move $a0, $s0   # wspó³rzêdna X wraca jako wspó³rzêdna punktu badanego
	beq $v0, 0, nextpoint	#	je¿eli czarny, to znaczy ¿e jestem w œrodku znacznika/stykam siê z czymœ wiêc out
	
	move $a1, $s4	# przygotowanie do sprawdzenia punktu na lewo od badanego
	jal get_pixel
	move $a1, $s1
	beq $v0, 0, nextpoint # je¿eli czarny, to znaczy ¿e jestem w œrodku znacznika/stykam siê z czymœ wiêc out
	
	move $a0, $s3   # sprawdzam punkt po przekatnej
	move $a1, $s4	# sprawdzam punkt po przekatnej
	jal get_pixel
	move $a1, $s1
	move $a0, $s0
	beq $v0, 0, nextpoint # je¿eli czarny, to znaczy ¿e jestem w œrodku znacznika/stykam siê z czymœ wiêc out
	la $a0, ($s0)
	
	move $s3, $s0
	move $s4, $s1
	
	j measurewidth
	
outofheight:				# specjalny przypadek, sprawdzam tylko punkt na lewo od potencjalnego punktu P
	move $s4, $s1
	move $a0, $s3
	move $a1, $s4
	jal get_pixel
	beq $v0, 0, nextpoint
	move $s3, $s0
	move $a0, $s0
	move $a1, $s1
	j measurewidth
	
outofwidth:				# specjalny przypadek, sprawdzam tylko punkt wyzej od potencjalnego punktu P
	move $s3, $s0
	move $a0, $s3
	move $a1, $s4
	jal get_pixel
	beq $v0, 0, nextpoint
	move $s4, $s1
	move $a0, $s0
	move $a1, $s1
	j measurewidth
	
nextpoint:
	add $s0, $s0, 1
	move $a0, $s0
	j loop
	
measurewidth:
	# s5 = dlugosc
	# s6 = wysokosc
	# s3 = punkt w prawo od P
	# s4 = punkt w dó³ od P

	bgt $s3, 319, savewidth #koniec wiersza
	
	move $a0, $s3
	
	jal get_pixel
	bne $v0, 0, savewidth #koniec czarnego, wiêc przechodzimy do mierzenia, pamietac o odjeciu 1 bo ostatnie czarne pole to $s3 -1 
	add $s3, $s3, 1
	j measurewidth		# jeœli nie koniec, to powtarzamy czynnoœæ
	
savewidth:
	
	sub $s5, $s3, $s0	# obliczam d³ugoœæ 
	
	move $a0, $s0		# wracam do wyjœciowych wspó³rzêdnych
	j measureheight
	
measureheight:

	blt $s4, 0, compare	# sprawdzam, czy to nie koniec kolumny
	move $a1, $s4		
	move $a0, $s0
	jal get_pixel
	bne $v0, 0, compare 	# koniec czarnego, ide sprawdzic obie funkcje
	sub $s4, $s4, 1
	j measureheight
	 
compare:
	# s5 = dlugosc
	# s6 = wysokosc
	
	sub $s6, $s1, $s4
	move $a0, $s0
	move $a1, $s1
	mul $s6, $s6, 2
	beq $s6, $s5, equal	# sprawdzam, czy stosunek dlugosci do szerokosci jest taki jak w zadaniu
	add $s0, $s0, 1
	j loop
	
equal:

	li $s7, 239
	sub $s7, $s7, $s1
	div	$s6, $s6, 2
	sub $s5, $s5, 1		# punkt krancowy w bok, punkt X
	add $s3, $s0, $s5	# punkt krancowy w bok, punkt X
	add $s5, $s5, 1		# punkt krancowy w bok, punkt X
	
	sub $s4, $s1, $s6	# punkt krañcowy w dó³, punkt Y
	add $s4, $s4, 1		# punkt krañcowy w dó³, punkt Y

	move $t4, $s0	# zmienne do przesuwania
	move $t5, $s1	# zmienne do przesuwania	
	
	j ramiona
	
ramiona:

	bgt $t4, 319, wysokoscramion #koniec wiersza dla bezpieczenstwa
	move $a0, $t4
	move $a1, $s4
	jal get_pixel
	bne $v0, 0, wysokoscramion #koniec czarnego, wiêc przechodzimy do mierzenia drugiego ramienia
	add $t4, $t4, 1
	j ramiona
	
wysokoscramion:
	sub $t8, $t4, $s0
	
	blt $t4, 0, czyrowne
	move $a0, $s3
	move $a1, $t5
	
	jal get_pixel
	bne $v0, 0, czyrowne #koniec czarnego, wiêc przechodzimy do porownania czy ramiona sa rowne
	sub $t5, $t5, 1
	
	j wysokoscramion

czyrowne:

	sub $t9, $s1, $t5
	move 	$t2, $t4 	# t2 = wspó³rzêdna X-owa punktu C, czyli punktu wklês³ego w znaczniku
	move 	$t3, $s4	# t3 = wspó³rzêdna Y-owa punktu C, czyli punktu wklês³ego w znaczniku
	sub $t4, $t4, 1
	beq $t9, $t8, bokAC
	
	j beforeloop
	
bokAC:

	beq $s4, 239, beforeloop
	add $s4, $s4, 1		# idziemy w górê
	move $a0, $t4
	move $a1, $s4
	jal get_pixel
	bne $v0, 0, beforeloop # dziura w znaczniku, znacznik jest zly
	sub $t1, $s1, $t9
	beq $s4, $t1, przygotujbokBC
	j bokAC
	
przygotujbokBC:
	
	add $s4, $s4, 1
	
bokBC:
	beq $t4, 339, beforeloop
	add $t4, $t4, 1		# idziemy w prawo
	move $a0, $t4

	move $a1, $s4
	
	move $a0, $t4
	jal get_pixel
	move $a0, $s0
	bne $v0, 0, beforeloop # dziura w znaczniku, znacznik jest zly
	add $t8, $s0, $s5
	sub $t8, $t8, 1
	
	
	beq $t4, $t8, otoczenie
	j bokBC
	
otoczenie:
	
	sub $s4, $s1, $s6
	
	move $a0, $s0	# wracam do punktu P, aby obejœæ ca³¹ figurê dooko³a
	move $a1, $s1
	move $t8, $s0
	sub $t8, $t8, 1
	move $a0, $t8
	sub $s6, $s6, 1	
			
		
otoczeniePY:

	blt $a1, 0, under	 # specjalny case dla znacznika przy krawedzi
	move $a0, $t8
	jal get_pixel
	beq $v0, 0, beforeloop	#jeœli napotkam jakiœ granicz¹cy czarny punkt, to nie jest to mój znacznik, wiêc out
	sub $s4, $s1, $s6
	blt $a1, $s4, otoczenieYA	# otoczenie przylegaj¹ce do boku PY nie jest czarne (razem z punktem po przekatnej!)
	
	sub $a1, $a1, 1
	j otoczeniePY

under:

	li $a1, 0
	add $t8, $t8, $t9
	add $t8, $t8, 1
	j otoczenieAC
	
otoczenieYA:	
	blt $a1, 0, otoczenieAC
	add $t8, $t8, 1
	move $a0, $t8
	add $s4, $s0, $t9
	beq $a0, $s4, otoczenieAC # otoczenie przylegaj¹ce do boku YA nie jest czarne, mozna isc dalej
	jal get_pixel
	beq $v0, 0, beforeloop
	j otoczenieYA
	
otoczenieAC:
	move $a0, $t8
	
	jal get_pixel
	beq $v0, 0, beforeloop 	 
	
	sub $s4, $s1, $t9
	add $a1, $a1, 1
	beq $a1, $s4, otoczenieCB # otoczenie przylegaj¹ce do boku PY nie jest czarne, mozna isc dalej
	j otoczenieAC
	
otoczenieCB:
	add $t8, $t8, 1
	move $a0, $t8
	add $s4, $s0, $s5
	beq $a0, $s4, otoczenieBX	# otoczenie przylegaj¹ce do boku CB nie jest czarne, mozna isc dalej
	jal get_pixel
	beq $v0, 0, beforeloop
	j otoczenieCB
	
otoczenieBX:
	move $a0, $t8
	bgt $a0, 339, otoczenieXP  # specjalny case dla znacznika przy krawedzi
	jal get_pixel
	add $a1, $a1, 1
	beq $v0, 0, beforeloop
	bgt $a1, $s1, otoczenieXP # otoczenie przylegaj¹ce do boku BX nie jest czarne, mozna isc dalej
	j otoczenieBX
	
otoczenieXP:
	bgt $a1, 239, znacznikwypisz 
	move $a0, $t8
	jal get_pixel
	beq $v0, 0, beforeloop
	sub $t8, $t8, 1
	move $a0, $t8
	add $s4, $s0, 0
	beq $a0, $s4, znacznikwypisz
	j otoczenieXP

znacznikwypisz:

	la $a0, ($s0)
	li $v0, 1
	syscall
	
	la $a0, ','
	li $v0, 11
	syscall
	
	la $a0, space
	li $v0, 4
	syscall
	
	li $s7, 239
	sub $s7, $s7, $s1
	
	la $a0, ($s7)
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	move $a1, $s1
	
	j beforeloop	#wroc do petli


# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
#open file
	li $v0, 13
        la $a0, fname		#file name 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...

	bltz $s1, error
	
#read file
	li $v0, 14
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
#open file
	li $v0, 13
        la $a0, fname		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...
	#bltz $s1, error
	
#save file
	li $v0, 15
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra


# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	$v0 - 0RGB - pixel color

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#get color
	lbu $v0,($t2)		#load B
	lbu $t1,1($t2)		#load G
	sll $t1,$t1,8
	or $v0, $v0, $t1
	lbu $t1,2($t2)		#load R
        sll $t1,$t1,16
	or $v0, $v0, $t1
					
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================

error:
	li $v0, 4
	la $a0, openerror # not opened = print error
	syscall
	
	li $v0, 10
	syscall
