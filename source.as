;CONSTANTES:
INT_CHANGE		EQU		fffah					;porto para mudar os interruptores.
INT_GAME		EQU		1000000000001111b		;mascara de interrupçoes durante o jogo.
INT_MENU		EQU		0000000000000010b		;mascara de interrupçoes
INT_FIM			EQU		0111111111111111b		;marcara de interrupçoes no final.
SP_INI			EQU		fdffh					;ponto incial no SP.
POS_ON			EQU		ffffh					;sinal para ligar o porto de controlo.
IO_POS			EQU		fffch					;controlo do display.
IO_IN			EQU		fffeh					;entrada do display.
IO_SEG_U		EQU		fff0h					;portos do display de segmentos.
IO_SEG_D		EQU		fff1h
IO_SEG_C		EQU		fff2h
IO_SEG_M		EQU		fff3h
IO_LCD_POS		EQU		fff4h					;portos do LCD.
IO_LCD_IN		EQU		fff5h
IO_LED			EQU		fff8h					;porto dos LEDs.
TIMER_SET		EQU		fff6h					;portos do temporizador.
TIMER_GO		EQU		fff7h
WALL			EQU		'-'
PIPE			EQU		'X'
SCENE_HEIGHT	EQU		23
SCENE_WIDTH		EQU		78
BIRD_OFFSET		EQU		20
CICLE			EQU		1
CLR				EQU		' '
V_FORCE			EQU		4						;velocidade de queda inicial.
J_FORCE			EQU		-16						;velocidade no periodo de salto.
J_TIME			EQU		1						;tempo do salto.
G_FORCE			EQU		1						;gravidade.
DIST_OBST		EQU		6						;distancia entre obstaculos (contando com a posição de um dos obstaculos)
MAX_OBST		EQU		13						;numero maximo de obstaculos em campo.
OBST_WIDTH		EQU		5						;largura dos espaços nos obstaculos.
DIF_INC			EQU		4						;incremento na velocidade de jogo por nivel de dificuldade.
MAX_DIF			EQU		16						;velocidade de jogo maxima.
T_A_X			EQU		35						;posiçoes dos textos.
T_A_Y			EQU		12
T_B_X			EQU		29
T_B_Y			EQU		14
F_X				EQU		34
F_Y				EQU		12
S_X				EQU		42
S_Y				EQU		14
RAND_MASK		EQU		1000000000010110b		;mascara para a geracao de numeros aleatoreos.
LAST_BIT		EQU		0001h
ASCII_NUM		EQU		0030h

;VARIAVEIS:
				ORIG	8000h
birdSpr			STR		'O>'
birdLen			WORD	2
birdPos			WORD	00c0h
birdV			WORD	4
gKick			WORD	0000h					;regula o movimento do passaro.
isFin			WORD	0000h
isJogo			WORD	0000h
msgA			STR		'Prepare-se'
lenA			WORD	10
msgB			STR		'Prima o interruptor I1'
lenB			WORD	22
txt_dist		STR		'Distancia:'
txt_distLen		WORD	10
txt_col			STR		'colunas'
txt_colLen		WORD	7
msgF			STR		'Fim do Jogo!'
lenF			WORD	12
obstX			TAB		20						;estrutura de dados que guarda informacao sobre os obstaculos.
obstH			TAB		20
numObst			WORD	0
obstTimer		WORD	10
novoObst		WORD	0
lastRand		WORD	0
cicloObst		WORD	17
dif				WORD	0
percorridos		WORD	0
score			WORD	0
scoreTimer		WORD	58
isPause			WORD	1						;na verdade o jogo esta em pausa quando isPause e 0 (logo deveria chamar-se isNotPause, mas pronto...)

;TABELA DE INTERRUPCOES:
				ORIG	fe00h
INT0			WORD	interruptZero
INT1			WORD	interruptOne
INT2			WORD	interruptTwo
INT3			WORD	interruptThr
INT4			WORD	interruptN
INT5			WORD	interruptN
INT6			WORD	interruptN
INT7			WORD	interruptN
INT8			WORD	interruptN
INT9			WORD	interruptN
INT10			WORD	interruptN
INT11			WORD	interruptN
INT12			WORD	interruptN
INT13			WORD	interruptN
INT14			WORD	interruptN
INT15			WORD	continua
				
;CODIGO:
				ORIG	0000h
				JMP		start

;resetVars: rotina que reinicia as variaveis de jogo.
resetVars:		MOV		R1, 00c0h
				MOV		M[birdPos], R1
				MOV		M[isFin], R0
				MOV		R1, 4
				MOV		M[birdV], R1
				MOV		M[gKick], R0
				MOV		M[isJogo], R0
				MOV		M[score], R0
				MOV		M[percorridos], R0
				MOV		R1, 58
				MOV		M[scoreTimer], R1
				MOV		M[dif], R0
				MOV		M[numObst], R0
				MOV		R1, 17
				MOV		M[cicloObst], R1
				MOV		M[novoObst], R0
				MOV		R1, 10
				MOV		M[obstTimer], R1
				MOV		R1, 1
				MOV		M[isPause], R1
				CALL	limpaObst
				RET
				
;limpaObst: rotina que da reset aos obstaculos.
limpaObst:		MOV		R1, obstX
				MOV		R2, obstH
				MOV		R3, 20
limpaObstP:		MOV		M[R1], R0
				MOV		M[R2], R0
				INC		R1
				INC		R2
				DEC		R3
				BR.NZ	limpaObstP
				RET
				
;setupJogo: rotina que inicializa o jogo.
setupJogo:		CALL	initDis
				CALL	initIO
				RET
				
;iniDisJogo: inicializa as interrupcoes do jogo.
iniDisJogo:		MOV		R1, INT_GAME
				MOV		M[INT_CHANGE], R1
				RET

;loopJogo: rotina que contem o loop de jogo.
loopJogo:		CALL	drawBird
				CALL	drawObst
				CALL	drawDisps
				CALL	delay
				CALL	eraseBird
				CALL	update
				CMP		M[isFin], R0
				BR.Z	loopJogo
				RET
				
;difDown: rotina que reduz a dificuldade.
difDown:		PUSH 	R1
				DEC		M[dif]
				MOV		R1, 0003h
				AND		M[dif], R1
				CALL	updCicloObst
				POP		R1
				RET

;difUp: rotina que aumenta a dificuldade.				
difUp:			PUSH 	R1
				INC		M[dif]
				MOV		R1, 0003h
				AND		M[dif], R1
				CALL	updCicloObst
				POP		R1
				RET
				
;updCicloObst: rotina que faz update ao comprimento do ciclo de update dos obstaculos.
updCicloObst:	PUSH	R2
				MOV		R1, M[dif]
				MOV		R2, DIF_INC
				MUL		R1, R2
				ENI
				NEG		R2
				ADD		R2, MAX_DIF
				MOV		M[cicloObst], R2
				CALL	drawDif
				POP		R2
				RET
				
;pausa: rotina que pausa o jogo.
pausa:			PUSH	R1
				PUSH	R2
				MOV		R1, M[isPause]
				XOR		R1, 1
				MOV		M[isPause], R1
				MOV		R1, CICLE
				MOV		R2, 1
				MOV		M[TIMER_SET], R1
				MOV		M[TIMER_GO], R2
				POP		R2
				POP		R1
				RET
				
;interruptZero: rotina que lida com o interruptor 0.
interruptZero:	CMP		M[isJogo], R0
				CALL.Z	saiMenu
				CMP		M[isJogo], R0
				CALL.NZ	jump
				RTI


;interruptOne: rotina que lida com o interruptor 1.				
interruptOne:	CMP		M[isJogo], R0
				CALL.Z	saiMenu
				CMP		M[isJogo], R0
				CALL.NZ	difDown
				RTI
				
;interruptTwo: rotina que lida com o interruptor 2.
interruptTwo:	CMP		M[isJogo], R0
				CALL.Z	saiMenu
				CMP		M[isJogo], R0
				CALL.NZ	difUp
				RTI
				
;interruptThr: rotina que lida com o interruptor 3.
interruptThr:	CMP		M[isJogo], R0
				CALL.Z	saiMenu
				CMP		M[isJogo], R0
				CALL.NZ	pausa
				RTI
				
;interruptN: rotina que lida com os outros interruptores.
interruptN:		CALL	saiMenu
				RTI
				
;initDis: inicializa os disables.
initDis:		ENI
				RET
				
;initIO: inicializa a janela de texto.
initIO:			MOV		R1, POS_ON
				MOV		M[IO_POS], R1
				RET
				
;drawScene: desenha o ecran.
drawScene:		PUSH	R0
				CALL	drawWall
				PUSH	R0
				PUSH	SCENE_HEIGHT
				CALL	getXY
				POP		R1
				PUSH	R1
				CALL	drawWall
				RET
				
;drawWall: desenha um dos limites do campo. (SP+2 primeira posicao)
drawWall:		MOV		R1, SCENE_WIDTH
				MOV		R3, M[SP+2]
				MOV		R2, WALL
drawWallP:		MOV		M[IO_POS], R3
				MOV		M[IO_IN], R2
				INC		R3
				DEC		R1
				BR.NZ	drawWallP
				RETN	1
				
;getXY: devolve um valor (X,Y). (SP+3 Y; SP+4 X | SP+4 XY)
getXY:			PUSH	R1
				MOV		R1, M[SP+3]
				SHL		R1, 8
				ADD		R1, M[SP+4]
				MOV		M[SP+4], R1
				POP		R1
				RETN	1
				
;drawBird: desenha o passaroco.
drawBird:		DSI
				MOV		R1, M[birdPos]
				SHR		R1, 4
				PUSH	BIRD_OFFSET
				PUSH	R1
				CALL	getXY
				POP		R1
				MOV		R2, birdSpr
				MOV		R3, M[birdLen]
drawBirdP:		MOV		R4, M[R2]
				MOV		M[IO_POS], R1
				MOV		M[IO_IN], R4
				INC		R2
				INC		R1
				DEC		R3
				BR.NZ	drawBirdP
				ENI
				RET
				
				
;drawObst: desenha os obstaculos.
drawObst:		DSI
				MOV		R1, obstX
				MOV		R4, obstH
				MOV		R2, M[numObst]
				CMP		R2, R0
				BR.Z	drawObstEnd
drawObstPA:		MOV		R5, M[R4]
drawObstPB:		PUSH	R5
				PUSH	M[R1]
				CALL	drawPipe
				DEC		R5
				BR.NZ	drawObstPB
				MOV		R5, M[R4]
				ADD		R5, OBST_WIDTH
drawObstPC:		PUSH	R5
				PUSH	M[R1]
				CALL	drawPipe
				INC		R5
				CMP		R5, SCENE_HEIGHT
				BR.N	drawObstPC
				INC		R1
				INC		R4
				DEC		R2
				BR.NZ	drawObstPA
drawObstEnd:	ENI
				RET
				
				
;drawPipe: rotina que desenha um tubo (apagando o tubo que esta atras do novo). (SP+4 X, SP+5 Y)
drawPipe:		PUSH	R5
				PUSH 	R4
				MOV		R3, M[SP+4]
				MOV		R7, M[SP+5]
				MOV		R5, PIPE
				MOV		R6, CLR
				PUSH	R3
				PUSH	R7
				CALL	getXY
				POP		R4
				MOV		M[IO_POS], R4
				MOV		M[IO_IN], R5
				INC		R4
				MOV		M[IO_POS], R4
				MOV		M[IO_IN], R6
				CMP		R3, SCENE_WIDTH
				BR.NZ	drawPipeExit
				CALL	graphPatch
				PUSH	1
				PUSH	R7
				CALL	getXY
				POP		R4
				MOV		M[IO_POS], R4
				MOV		M[IO_IN], R6
drawPipeExit:	POP 	R4
				POP		R5
				RETN	2
				

				
;drawDisps: rotina que escreve a pontuação e etc nos displays.
drawDisps:		CALL	drawDist
				CALL	drawScore
				CALL	drawDif
				RET
				
;drawScore: rotina que escreve o score.
drawScore:		MOV		R1, M[score]
				MOV		R3, R1
				MOV		R2, 10
				DIV		R1, R2
				MOV		M[IO_SEG_U], R2
				MOV		R2, 10
				DIV		R1, R2
				MOV		M[IO_SEG_D], R2
				MOV		R2, 10
				DIV		R1, R2
				MOV		M[IO_SEG_C], R2
				MOV		R2, 10
				DIV		R1, R2
				MOV		M[IO_SEG_M], R2
				RET
				
;drawDist: rotina que desenha a distancia.
drawDist:		MOV		R1, 8000h
				PUSH	txt_dist
				PUSH	M[txt_distLen]
				CALL	drawTextLCD
				ADD		R1, 5
				MOV		R2, 5
				MOV		R3, M[percorridos]
drawDistP:		MOV		R4, 10
				DIV		R3, R4
				ADD		R4, ASCII_NUM
				MOV		M[IO_LCD_POS], R1
				MOV		M[IO_LCD_IN], R4
				DEC		R1
				DEC		R2
				BR.NZ	drawDistP
				MOV		R1, 8010h
				PUSH	txt_col
				PUSH	M[txt_colLen]
				CALL	drawTextLCD
				RET
				
;drawTextLCD: rotina que desenha uma string no LCD.				
drawTextLCD:	PUSH	R2
				PUSH	R3
				PUSH	R4
				MOV		R2, M[SP+6]
				MOV		R3, M[SP+5]
drawTextLCDP:	MOV		R4, M[R2]
				MOV		M[IO_LCD_POS], R1
				MOV		M[IO_LCD_IN], R4
				INC		R1
				INC		R2
				DEC		R3
				BR.NZ	drawTextLCDP
				POP		R4
				POP		R3
				POP		R2
				RETN	2
				
;drawDif: rotina que faz update aos LEDs.
drawDif:		PUSH	R1
				PUSH	R2
				MOV		R1, M[dif]
				INC		R1
				MOV		R2, R0
drawDifP:		SHR		R2, 1
				ADD		R2, 8000h
				DEC		R1
				BR.NZ	drawDifP
				MOV		M[IO_LED], R2
				POP		R2
				POP		R1
				RET
				
				
				
;delay: rotina que aguarda 1 ciclo.
delay:			PUSH	R1
				PUSH	R2
				PUSH	R3
				MOV		R1, 1
				MOV		R2, CICLE
				MOV		R3, R0
				MOV		M[TIMER_SET], R2
				MOV		M[TIMER_GO], R1
delayP:			CMP		R3, R0
				BR.Z	delayP
				POP		R3
				POP		R2
				POP		R1
				RET
				
;continua: rotina que muda o valor de R3 para 1. Funciona em conjunto com delay.
continua:		MOV		R3, 1
				AND		R3, M[isPause]
				RTI
				
;update: rotina que faz update as vars de jogo.
update:			MOV		R1, M[birdV]
				MOV		R2, M[birdPos]
				ADD		R2, R1
				ADD		R2, -16
				BR.N	updateC
				ADD		M[birdPos], R1
updateC:		CMP		M[gKick], R0
				BR.NZ	updateA
				MOV		R1, V_FORCE
				MOV		M[birdV], R1
updateA:		DEC		M[gKick]
				CMP		M[gKick], R0
				BR.NN	updateB
				MOV		R1, G_FORCE
				ADD		M[birdV], R1
updateB:		CALL	deadChk
				CMP		M[obstTimer], R0
				BR.NZ	updateD
				CALL	updateObst
updateD:		DEC		M[obstTimer]
				RET
				
;updateObst: rotina que faz update aos tubos.
updateObst:		MOV		R1, MAX_OBST
				CMP		M[numObst], R1
				BR.Z	updateObstA
				CALL	criaObst
updateObstA:	MOV		R1, obstX
				MOV		R5, obstH
				MOV		R2, M[numObst]
				MOV		R3, SCENE_WIDTH
updateObstP:	DEC		M[R1]
				BR.NZ	updateObsB
				MOV		M[R1], R3
				PUSH	R0
				CALL 	randH
				POP		R4
				MOV		M[R5], R4
updateObsB:		INC		R1
				INC		R5
				DEC		R2
				BR.NZ	updateObstP
				MOV		R1, M[cicloObst]
				MOV		M[obstTimer], R1
				INC		M[percorridos]
				DEC		M[scoreTimer]
				BR.NZ	updateObstEnd
				INC		M[score]
				MOV		R1, DIST_OBST
				MOV		M[scoreTimer], R1
updateObstEnd:	RET
				
;criaObst: rotina que cria obstaculos a uma distancia constante.
criaObst:		PUSH	R1
				CMP		M[novoObst], R0
				BR.NZ	criaObstEnd
				MOV		R2, SCENE_WIDTH
				MOV		R1, obstX
				MOV		R3, obstH
				ADD		R1, M[numObst]
				ADD		R3, M[numObst]
				PUSH	R0
				CALL	randH
				POP		R4
				MOV		M[R1], R2
				MOV		M[R3], R4
				INC		M[numObst]
				MOV		R2, DIST_OBST
				MOV		M[novoObst], R2
criaObstEnd:	DEC		M[novoObst]
				POP		R1
				RET
				
				
;graphPatch: rotina que apaga as posições que a rotina que trata os graficos dos obstaculos não consegue apagar.
graphPatch:		PUSH	R1
				PUSH	R2
				PUSH	R3
				PUSH	R4
				MOV		R1, 1
				MOV		R2, SCENE_HEIGHT
				SUB		R2, 2
				MOV		R4, CLR
graphPatchL:	PUSH	1
				PUSH	R1
				CALL	getXY
				POP		R3
				MOV		M[IO_POS], R3
				MOV		M[IO_IN], R4
				INC		R1
				DEC		R2
				BR.NZ	graphPatchL
				POP		R4
				POP		R3
				POP		R2
				POP		R1
				RET
				
;randH: rotina que gera uma altura aleatoria. (SP+4 output)
randH:			PUSH	R1
				PUSH	R2
				PUSH	R3
				MOV		R1, M[lastRand]
				TEST	R1, LAST_BIT
				BR.NZ	randHB
				ROR		R1, 1
				MOV		R2, 12
				MOV		R3, R1
				DIV		R3, R2
				ADD		R2, 3
				TEST	R1, LAST_BIT
randHB:			BR.Z	randHC
				XOR		R1, RAND_MASK
				ROR		R1, 1
				MOV		R3, R1
				MOV		R2, 12
				DIV		R3, R2
				ADD		R2, 3
randHC:			MOV		M[SP+5], R2
				MOV		M[lastRand], R1
				POP		R3
				POP		R2
				POP		R1
				RET
				
				
;deadChk: rotina que faz update a var de fim de jogo.
deadChk:		MOV		R1, M[birdPos]
				SHR		R1, 4
				INC		R1
				MOV		R2, SCENE_HEIGHT
				PUSH	R0
				CALL	colision
				POP		R3
				CMP		R2, R1
				BR.NN	deadChkA
				MOV		R1, 1
				MOV		M[isFin], R1
deadChkA:		CMP		R3, R0
				BR.Z	deadChkExit
				MOV		R1, 1
				MOV		M[isFin], R1
deadChkExit:	RET

;colision: rotina que verifica se o passaro colidiu com uma parede (SP+4 0/1)
colision:		PUSH	R1
				PUSH	R2
				PUSH	R0
				CALL	obstOff
				POP		R1
				CMP		R1, ffffh
				BR.Z	colisionExit
				ADD		R1, obstH
				MOV		R2, M[birdPos]
				SHR		R2, 4
				CMP		R2, M[R1]
				BR.P	colisionA
				INC		M[SP+4]
colisionA:		ADD		R2, -5
				CMP		R2, M[R1]
				BR.N	colisionExit
				INC		M[SP+4]
colisionExit:	POP		R2
				POP		R1
				RET
				
				
;obstOff: rotina que devolve o indice do obstaculo que está a passar pelo passaro. (SP+6 indice/ffff)
obstOff:		PUSH	R1
				PUSH	R2
				PUSH	R3
				PUSH	R4
				MOV		R1, R0
				MOV		R2, obstX
				MOV		R3, BIRD_OFFSET
				MOV		R4, M[numObst]
				CMP		R4, R0
				BR.Z	obstOffFalse
obstOffL:		CMP		M[R2], R3
				BR.Z	obstOffTrue
				INC		R1
				INC		R2
				DEC		R4
				BR.NZ	obstOffL
obstOffFalse:	MOV		R1, ffffh
				MOV		M[SP+6], R1
				POP		R4
				POP		R3
				POP		R2
				POP		R1
				RET
obstOffTrue:	MOV		M[SP+6], R1
				POP		R4
				POP		R3
				POP		R2
				POP		R1
				RET
				
				
;eraseBird: apaga o passaro.
eraseBird:		DSI
				MOV		R1, M[birdPos]
				SHR		R1, 4
				PUSH	BIRD_OFFSET
				PUSH	R1
				CALL	getXY
				POP		R1
				MOV		R2, CLR
				MOV		R3, M[birdLen]
eraseBirdP:		MOV		M[IO_POS], R1
				MOV		M[IO_IN], R2
				INC		R1
				DEC		R3
				BR.NZ	eraseBirdP
				ENI
				RET
				
;jump: rotina de servico que faz o passaro saltar.
jump:			PUSH	R1
				PUSH	R2
				MOV		R1, J_FORCE
				MOV		R2, J_TIME
				MOV		M[gKick], R2
				MOV		M[birdV], R1
				POP		R2
				POP		R1
				RET
				
				
;stratMenu: rotina que chama o start menu e espera por input do utilizador.
stratMenu:		DSI
				MOV		R1, INT_MENU
				MOV		M[INT_CHANGE], R1
				CALL	drawStart
				MOV		R1, R0
				ENI
stratMenuP:		INC		M[lastRand]
				CMP		R1, R0
				BR.Z	stratMenuP
				CALL	limpaEcran
				RET
				
;drawStart: rotina que desenha o menu.
drawStart:		PUSH	T_A_X
				PUSH	T_A_Y
				CALL	getXY
				POP		R1
				PUSH	msgA
				PUSH	M[lenA]
				PUSH	R1
				CALL	drawTxt
				PUSH	T_B_X
				PUSH	T_B_Y
				CALL	getXY
				POP		R1
				PUSH	msgB
				PUSH	M[lenB]
				PUSH	R1
				CALL	drawTxt
				RET
				
;drawTxt: rotina que desenha uma linha de texto. (SP+2 posicao; SP+3 length; SP+4 mensagem em memoria)
drawTxt:		MOV		R1, M[SP+4]
				MOV		R2, M[SP+3]
				MOV		R3, M[SP+2]
drawTxtP:		MOV		M[IO_POS], R3
				MOV		R4, M[R1]
				MOV		M[IO_IN], R4
				INC		R1
				INC		R3
				DEC		R2
				BR.NZ	drawTxtP
				RETN	3
				
;saiMenu: rotina que quebra a espera do menu.
saiMenu:		MOV		R1, 1
				RET
				

				
;limpaEcran: Rotina que apaga o ecrã
limpaEcran:		DSI
				MOV		R1, SCENE_WIDTH
				MOV		R2, SCENE_HEIGHT
				MOV		R3, CLR
limpaEcranP:	PUSH	R1
				PUSH	R2
				CALL	getXY
				POP		R4
				MOV		M[IO_POS], R4
				MOV		M[IO_IN], R3
				DEC		R1
				BR.NN	limpaEcranP
				MOV		R1, SCENE_WIDTH
				DEC		R2
				BR.NN	limpaEcranP
				ENI
				RET
				
;menuFinal: rotina que desenha o menu final.
menuFinal:		DSI
				MOV		R1, INT_FIM
				MOV		M[INT_CHANGE], R1
				MOV		M[isJogo], R0
				PUSH	F_X
				PUSH	F_Y
				CALL	getXY
				POP		R1
				PUSH	msgF
				PUSH	M[lenF]
				PUSH	R1
				CALL	drawTxt
				CALL	drawFnScore
				ENI
				MOV		R1, R0
menuFinalW:		CMP		R1, R0
				BR.Z	menuFinalW
				RET
				
;drawFnScore: rotina que desenha a pontuação final.
drawFnScore:	PUSH	S_X
				PUSH	S_Y
				CALL	getXY
				POP		R1
				MOV		R2, 4
				MOV		R3, M[score]
drawFnScoreP:	MOV		R4, 10
				DIV		R3, R4
				ADD		R4, ASCII_NUM
				MOV		M[IO_POS], R1
				MOV		M[IO_IN], R4
				DEC		R1
				DEC		R2
				BR.NZ	drawFnScoreP
				RET
				
				
				
;start: rotina de inicio do jogo.				
start:			MOV		R1, SP_INI
				MOV		SP, R1
				CALL	resetVars
				CALL	drawDisps
				CALL	setupJogo
				CALL	stratMenu
				MOV		R1, 1
				MOV		M[isJogo], R1
				CALL	drawScene
				CALL	iniDisJogo
				CALL	loopJogo
				CALL	limpaEcran
				CALL	menuFinal
fin:			BR		start

;===========================================;