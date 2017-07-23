;;--------------------------------------------------- SISTEMAS EMBARCADOS I - 2017/1---------------------------;;
;;---------------------------------------------------------PROJETO:O ELEVADOR----------------------------------;;
;;-------------------------------------------------------------------------------------------------------------;;
;;-------------------------------------------------------EMILIA FRIGERIO CREMASCO------------------------------;;
;;--------------------------------------------------------MARCELA FREITAS VIEIRA-------------------------------;;
;;-------------------------------------------------------MARCELO BRINGUENTI PEDRO------------------------------;;
;;-------------------------------------------------------------------------------------------------------------;;
;;OBS: MAQUETE UTILIZADA: ELEVADOR DE ACRILICO ANTIGO----------------------------------------------------------;;

segment code
..start:
		mov 		ax,data
		mov 		ds,ax
		mov 		ax,stack
		mov 		ss,ax
		mov 		sp,stacktop

; Salvar modo corrente de video(vendo como esta o modo de video da maquina)
        mov  		ah,0Fh
		int  		10h
		mov  		[modo_anterior],al

; Alterar modo de video para grafico 640x480 16 cores
    	mov     	al,12h
   		mov     	ah,0
    	int     	10h
; Interrrupcao do teclado
  		xor     ax, ax
        mov     es, ax
; Salvando o segmento antigo
        mov     ax, [es:int9*4] 
        mov     [offset_dos], ax
        mov     ax, [es:int9*4+2] 
        mov     [cs_dos], ax
        cli
; Substituindo a tabela da BIOS pela nossa tabela
        mov     [es:int9*4+2], cs ; 
        mov     WORD [es:int9*4],keyint 
        sti    

;--------------------------------------------------	MACROS------------------------------------------------------
%macro linha 5
		pusha
		pushf
		mov		ax,%1 ;x
		push	ax
		mov		ax,%2 ;y
		push	ax
		mov		ax,%3 ;x
		push	ax
		mov		ax,%4 ;y
		push	ax
		mov		byte[cor],%5
		call	line
		popf
		popa
%endmacro

%macro escreve_palavra 6	;caracteres, dh,dl,nome,loop, cor
		pusha
		pushf
		mov     cx, %1
      	mov     bx, 0
      	mov     dh, %2 ;0-29 vertical
      	mov 	dl, %3 ;0-079 horizontal
      	mov		byte[cor], %6
%5:
      	call 	cursor
      	mov 	al, [bx+ %4]
      	call 	caracter
      	inc 	bx
      	inc 	dl
      	loop    %5
      	popf
      	popa
%endmacro

;--------------------------------------------------------FIM MACROS------------------------------------------;;

;;---------------------------------------------------PROGRAMA PRINCIPAL--------------------------------------;;
	call moldura ;;Desenha a moldura da interface
	call nomes   ;;Escreve os nomes dos componentes do grupo, o nome da disciplina e etc na parte inferior da tela

	call calibraele ;;Calibra o elevador no quarto andar
	call desenha_interface ;;Desenha a interface da tela apos a calibracao
	enquanto: ;;loop principal

	cmp byte[emodo], 1 ;;Verifica se esta em modo de emergencia
	je enquanto; ;;Fica preso no loop se estiver
	call verifica_botoes_externos ;;Verifica quais botoes externos foram ativados e liga os leds respectivos 
	call decide ;;Decide qual sera o proximo andar

	acao: ;;Verifica se o elevador vai subir ou descer
		cmp byte[proximo], 0 
		je acao_1 ;;Se o elevador tiver acabado de sair da calibracao, pula para a label acao_1
		mov bl, byte[andar_atual] ;
		cmp byte[proximo], bl ;;Compara o andar atual com o proximo andar, para saber se chegou ao destino
		je cheguei ;;Se tiver chegado ao destino, pula para a label cheguei
acao_1:
		cmp byte[status], 0 ;;Se o elevador estiver parado, fica no loop ate receber algum comando
		je enquanto
		cmp byte[status], 1 ;;Se o elevador estiver setado para descer, pula para o label to_desce
		je to_desce
		cmp byte[status], 2 ;;Se o elevador estiver setado para subir, pula para o label to_sobe
		je to_sobe

	to_desce: ;Se o elevador tiver que descer
		call desce ;;Manda o comando de descer para o motor 
		mov ax, word[contador]
		sub ax, 89 ;;Subtrai a variavel para chegar ao valor do contador do andar inferior
	cont2:
		cmp byte[emodo], 1 ;;Se estiver em modo de emergencia, fica preso no loop cont2 sem contar volta
		je cont2
		call conta_volta   ;;Chama a funcao que conta uma volta 
		call verifica_botoes_externos ;;Verifica os botoes externos ativados
		cmp word[contador], ax  ;;Verifica se chegou ao andar inferior 
		jne cont2 ;;Se nao chegou, continua descendo e contando voltas 
		dec byte[andar_atual] ;Se chegou, decrementa o andar
		mov bl, byte[andar_atual]
		cmp byte[proximo], bl ;Verifica se o andar atual eh o andar de destino, se for, pula para o label cheguei
		je cheguei
		jmp enquanto ;Se nao for, continua no loop enquanto 


	cheguei:
	 		call att_andar_imprime ;Imprime o andar atual e seta os botoes externos e internos respectivos aquele andar em 0
	 		call para ;Manda o comando para o elevador parar
	 		call delay ;Delei para "abrir a porta"

	 		jmp enquanto ;Continua no loop principal

	to_sobe: ;Se o elevador tiver que subir
		call e_sobe ;Manda o comando para subir 
		mov ax, word[contador]
		add ax, 89 ;Adiciona a variavel para chegar ao andar superior
	cont3:
		cmp byte[emodo], 1 ;Se estiver em modo de emergencia, fica preso no loop cont3 sem contar volta
		je cont3
		call conta_volta ;Conta uma volta
		call verifica_botoes_externos ;Verifica os botoes externos que foram ativados
		cmp word[contador], ax ;Verifica se chegou ao andar de cima
		jne cont3 ;Se nao chegou, continua subindo e contando voltas
		inc byte[andar_atual] ;Se chegou, incrementa o andar 
		mov bl, byte[andar_atual]
		cmp byte[proximo], bl ;Verifica se eh o andar de destino
		je cheguei ;Se for, pula para o label cheguei
		jmp enquanto ;Se nao for, fica no loop enquanto


;;--------------------------------------------------FIM PROGRAMA PRINCIPAL-----------------------------------;;

;;---------------------------------------------------FUNCOES ADICIONAIS--------------------------------------;;
;;------------------------------------------------------------------------------------------------------------;;

;;Funcao que decide qual sera o proximo andar 
decide:
 	pusha
 	pushf

    ;;Verifica em qual andar o elevadoe esta
 	cmp byte[andar_atual], 4
 	je forthfloor
 	cmp byte[andar_atual], 3
 	je thirdfloor
 	cmp byte[andar_atual], 2
 	je scdfloor
 	cmp byte[andar_atual], 1
 	je firstfloor
;;Trata cada andar de forma diferente
forthfloor:  
	call andar_4
	jmp sai_decide

thirdfloor:
	call andar_3
	jmp sai_decide

scdfloor:
	call andar_2
	jmp sai_decide

firstfloor:
	call andar_1
	jmp sai_decide

 sai_decide:
 	popf
 	popa
 	ret
;;----------------------------------------------------------------------------------------------------
;Se estiver no andar 4
andar_4:
	pusha
	pushf
    ;Verifica se o elevador esta parado ou se esta descendo
	cmp byte[status], 0
	je c_p_4
	jmp c_d_4
;Verifica quais pedidos deve tratar, se o elevador estiver parado
c_p_4:
	
	cmp byte[bint_4], 1
	je a_4_4
	cmp byte[bint_3], 1
	je a_4_3
	cmp byte[bint_2], 1
	je a_4_2
	cmp byte[bint_1], 1
	je a_4_1
	cmp byte[bext_5], 1
	je a_4_3
	cmp byte[bext_4], 1
	je a_4_3
	cmp byte[bext_3], 1
	je a_4_2
	cmp byte[bext_2], 1
	je a_4_2
	cmp byte[bext_1], 1
	je a_4_1
	jmp sai_andar4
;Verifica quais pedidos deve tratar, se o elevador estiver descendo
c_d_4:
	cmp byte[bint_3], 1
	je a_4_3
	cmp byte[bint_2], 1
	je a_4_2
	cmp byte[bint_1], 1
	je a_4_1
	cmp byte[bext_4], 1
	je a_4_3
	cmp byte[bext_2], 1
	je a_4_2
	cmp byte[bext_1], 1
	je a_4_1
	cmp byte[bext_3], 1
	je a_4_2
	jmp sai_andar4

;;--Os labels a_4_i tratam os casos do elevador no quarto andar, setandando a variavel status(descendo) e variavel do proximo andar
a_4_4:
	mov byte[bint_4], 0 ;Nesse caso, desativa o botao interno 4, se alguem ativar 
	call apaga_4 ;Desativa os botoes e os leds, as setas da interface e imprime o andar 4
	jmp sai_andar4

a_4_3:
	mov byte[status], 1 ;;desce
	mov byte[proximo], 3
	;;apaga seta
	jmp sai_andar4

a_4_2:
	mov byte[status], 1 ;;desce
	mov byte[proximo], 2
	jmp sai_andar4

a_4_1:
	mov byte[status], 1 ;;desce
	mov byte[proximo], 1
	jmp sai_andar4

sai_andar4:
	popf
	popa
	ret

;;Se estiver no terceiro andar--------------------------------------------------------
andar_3:
	pusha
	pushf
;Verifica se o elevador esta parado, subindo ou descendo
	cmp byte[status], 0
	je c_p_3
	cmp byte[status], 2
	je c_s_3
	jmp c_d_3
;Verifica quais pedidos tratar se o elevador estiver parado
c_p_3:
	cmp byte[bint_3],1
	jne t91
	jmp a_3_3
t91:	cmp byte[bint_4], 1
	jne t10
	jmp a_3_4
t10:
	cmp byte[bint_2], 1
	jne t11
	jmp a_3_2
t11:
	cmp byte[bint_1], 1
	jne t12
	jmp a_3_1
t12:
	cmp byte[bext_6], 1
	je a_3_4
	cmp byte[bext_3], 1
	jne t90
	jmp a_3_2
t90: cmp byte[bext_2], 1
	je a_3_2
	cmp byte[bext_1], 1
	je p_a_3_1
	jmp sai_andar3
c_s_3: ;Verifica quais pedidos tratar se estiver subindo
	cmp byte[bext_5], 1
	je	a_3_3
	cmp byte[bint_4], 1
	je a_3_4
	cmp byte[bint_3], 1
	je a_3_3
	jmp sai_andar3
c_d_3: ;Verfica quais pedidos tratar se estiver descendo
	cmp byte[bext_4], 1
	je	a_3_3
	cmp byte[bint_3], 1
	je a_3_3
	cmp byte[bint_2], 1
	je a_3_2
	cmp byte[bint_1], 1
	je a_3_1
	cmp byte[bext_2], 1 ;desce primeiro andar
	je a_3_2
	jmp sai_andar3
p_a_3_1: jmp a_3_1 ;Para resolver out of range
;--Os labels a_3_i tratam os casos do elevador no quarto andar, setandando a variavel status(descendo, subindo, parado) e variavel do proximo andar
a_3_3:
	cmp byte[status], 0
	je a3
	mov byte[proximo], 3
	jmp sai_andar3
a3:
	xor byte[estado_atual], 00010100b ;Se o elevador estiver parado e os leds do andar 3 estiverem ligados, apaga. Pode ser a causa de os leds estarem piscando
	call atualiza_led ;Atualiza os leds
	mov byte[bint_3], 0
	jmp sai_andar3
a_3_4:
	mov byte[status], 2 ;sobe
	call apaga_3
	mov byte[proximo], 4
	jmp sai_andar3
a_3_2:
	mov byte[status], 1 ;;desce
	call apaga_3
	mov byte[proximo], 2
	jmp sai_andar3
a_3_1:
	mov byte[status], 1 ;;desce
	call apaga_3
	mov byte[proximo], 1
	jmp sai_andar3

sai_andar3:
	popf
	popa
	ret
;;Se o elevador estiver no segundo andar-----------------------------------------------------------------------------------------------
andar_2:
	pusha
	pushf
;Verifica se o elevador esta subindo, descendo ou parado
	cmp byte[status], 0
	je c_p_2
	cmp byte[status], 2
	je c_s_2
	jmp c_d_2
;Verifica quais pedidos tratar se estiver parado
c_p_2:
	;call apaga_led3
	;call apaga_led2
	cmp byte[bint_2], 1
	je a_2_2
	cmp byte[bint_1], 1
	jne t
	jmp a_2_1
t:
	cmp byte[bint_3], 1 ;t:small fix: pra nao dar out of range
	jne t15
	jmp a_2_3
t15:
	cmp byte[bint_4], 1
	je a_2_4
	cmp byte[bext_1], 1 ;1 andar
	jne t16
	jmp a_2_1
t16:
	cmp byte[bext_4], 1 ;3 andar
	je a_2_3
	cmp byte[bext_5], 1 ;3 andar
	je a_2_3
	cmp byte[bext_6], 1
	je a_2_4
	jmp sai_andar2
;Verifica quais pedidos tratar se estiver subindo
c_s_2:
	cmp byte[bext_3], 1
	je a_2_2
	cmp byte[bint_2], 1
	je a_2_2
	cmp byte[bint_3],1
	je a_2_3
	cmp byte[bint_4], 1
	je a_2_4
	cmp byte[bext_5],1	;sobe andar 3
	je a_2_3
	jmp sai_andar2
;Verifica quais pedidos tratar se estiver descendo
c_d_2:
	cmp byte[bext_2], 1
	je a_2_2
	cmp byte[bint_2], 1
	je a_2_2
	cmp byte[bint_1], 1
	je a_2_1
	jmp sai_andar2
;;Os labels a_3_i tratam os casos do elevador no quarto andar, setandando a variavel status(descendo, subindo, parado) e variavel do proximo andar---------
a_2_2:
	cmp byte[status], 0
	je a2
	mov byte[proximo], 2
	jmp sai_andar2
a2:
	xor byte[estado_atual], 00001010b ;Apaga os leds do segundo andar se o elevador estiver parado la. Pode levar os leds a piscarem
	call atualiza_led
	mov byte[bint_2], 0
	jmp sai_andar2
a_2_4:
	mov byte[status], 2 ;sobe
	call apaga_2
	mov byte[proximo], 4
	jmp sai_andar2
a_2_3:
	mov byte[status], 2 ;sobe
	call apaga_2
	mov byte[proximo], 3
	jmp sai_andar2
a_2_1:
	mov byte[status], 1 ;desce
	call apaga_2
	mov byte[proximo], 1
	jmp sai_andar2
sai_andar2:
	popf
	popa
	ret

;;-------------------------------------------------------------------------------------------------
;Se o elevador estiver no primeiro andar
andar_1:
	pusha
	pushf
';Verifica se o elevador esta parado ou subindo
	cmp byte[status], 0
	je c_p_1
	jmp c_s_1
;Verifica quais casos tratar se o elevador estiver parado
c_p_1:
	;call apaga_led1
	cmp byte[bint_1], 1
	je a_1_1
	cmp byte[bint_2], 1
	jne t19
	jmp a_1_2
t19:
	cmp byte[bint_3], 1
	jne t18
	jmp a_1_3
t18:
	cmp byte[bint_4], 1
	je a_1_4
	cmp byte[bext_2], 1 ;andar 2
	je a_1_2
	cmp byte[bext_3], 1 ;andar 2
	je a_1_2
	cmp byte[bext_4], 1 ;andar 3
	je a_1_3
	cmp byte[bext_5], 1 ;andar 3
	je a_1_3
	cmp byte[bext_6], 1 ;andar 4
	je	a_1_4
	jmp sai_andar1
;Verifica quais casos tratar se o elevado estiver subindo
c_s_1:
	cmp byte[bint_2], 1
	je a_1_2
	cmp byte[bint_3], 1
	je a_1_3
	cmp byte[bint_4], 1
	je a_1_4
	cmp byte[bext_3], 1
	je a_1_2
	cmp byte[bext_5], 1
	je a_1_3
	cmp byte[bext_6], 1
	je a_1_4
	jmp sai_andar1
;Os labels a_1_i tratam os casos do elevador no quarto andar, setandando a variavel status(subindo, parado) e variavel do proximo andar
a_1_1:
	mov byte[bint_1], 0
	call apaga_1
	jmp sai_andar1

a_1_4:
	mov byte[status], 2 ;sobe
	mov byte[proximo], 4
	jmp sai_andar1

a_1_3:
	mov byte[status], 2 ;;sobe
	mov byte[proximo], 3
	jmp sai_andar1

a_1_2:
	mov byte[status], 2 ;sobe
	mov byte[proximo], 2
	jmp sai_andar1

sai_andar1:
	popf
	popa
	ret
;;--------------------------------------------------------------------------------------------------
;;-------------------------------------------------------------------------------------------------
;Funcao que gera um delay, simulando o tempo de abrir e fechar a porta do elevador
delay:
	pusha
	pushf

	mov ah, 0
	int 1ah
	mov di, 30
	mov ah, 0
	int 1ah
	mov bx, dx

espera:
	cmp byte[emodo], 1
	je espera
	call verifica_botoes_externos
	mov ah, 0
	int 1ah
	sub dx, bx
	cmp di, dx
	ja espera
	popf
	popa
	ret

;;As funcoes apaga_i escrevem o andar respectivo na interface, apagam as setas, desativam os botoes do andar e apagam os leds----------------------------------------------------------
apaga_1:
	pusha
	pushf

	escreve_palavra 1, 2, 16, um, l80, branco_intenso
	linha 442, 125, 472, 125, branco_intenso ;h
	linha 442, 125, 442, 145, branco_intenso ;v
	linha 472, 125, 472, 145, branco_intenso ;v

	linha 442, 145, 432, 145, branco_intenso ;h
	linha 472, 145, 482, 145, branco_intenso ;h

	linha 432, 145, 457, 174, branco_intenso ;t
	linha 482, 145, 457, 174, branco_intenso ;t

	mov byte[bext_1], 0
	mov byte[bint_1], 0
	linha 557, 125, 587, 125, branco_intenso ;h
	linha 557, 125, 557, 145, branco_intenso ;h
	linha 587, 125, 587, 145, branco_intenso ;h

	linha 557, 145, 547, 145, branco_intenso ;h
	linha 587, 145, 597, 145, branco_intenso ;h

	linha 547, 145, 572, 174, branco_intenso ;t
	linha 597, 145, 572, 174, branco_intenso ;t

	or byte[estado_atual], 00000001b ; atualiza led
	call atualiza_led

	popf
	popa
	ret
;;-----------------------------------------------------------
apaga_2:
	pusha
	pushf

	escreve_palavra 1, 2, 16, dois, l81, branco_intenso
	linha 442, 229, 442, 249, branco_intenso ;v
	linha 472, 229, 472, 249, branco_intenso ;v

	linha 442, 229, 432, 229, branco_intenso ;h
	linha 472, 229, 482, 229, branco_intenso ;h
	linha 442, 249, 432, 249, branco_intenso ;h
	linha 472, 249, 482, 249, branco_intenso ;h

	linha 432, 229, 457, 210, branco_intenso ;t
	linha 482, 229, 457, 210, branco_intenso ;t
	linha 432, 249, 457, 268, branco_intenso ;t
	linha 482, 249, 457, 268, branco_intenso
	mov byte[bint_2], 0
	cmp byte[status], 2 ;subindo
	jne sub3
	jmp sub1
sub3:
	mov byte[bext_2], 0
	or byte[estado_atual], 00001000b ; atualiza led
	call atualiza_led

	linha 557, 235, 557, 225, branco_intenso ;v
	linha 587, 235, 587, 225, branco_intenso ;v

	linha 557, 235, 587, 235, branco_intenso ;h

	linha 557, 225, 547, 225, branco_intenso ;h
	linha 587, 225, 597, 225, branco_intenso ;h

	linha 547, 225, 572, 210, branco_intenso ;t
	linha 597, 225, 572, 210, branco_intenso ;t
	jmp sai_apaga_2
sub1:
	mov byte[bext_3], 0
	or byte[estado_atual], 00000010b ; atualiza led
	call atualiza_led

  linha 557, 243, 557, 253, branco_intenso ;v
	linha 587, 243, 587, 253, branco_intenso ;v

	linha 557, 243, 587, 243, branco_intenso ;h

	linha 557, 253, 547, 253, branco_intenso ;h
	linha 587, 253, 597, 253, branco_intenso ;h

	linha 547, 253, 572, 268, branco_intenso ;t
	linha 597, 253, 572, 268, branco_intenso ;t;
	;apaga led 3 ;subindo
sai_apaga_2:
	popf
	popa
	ret
;-----------------------------------------------------------------------------------------------
apaga_3:
	pusha
	pushf
	linha 442, 319, 442, 339, branco_intenso ;v
	linha 472, 319, 472, 339, branco_intenso ;v

	linha 442, 319, 432, 319, branco_intenso ;h
	linha 472, 319, 482, 319, branco_intenso ;h
	linha 442, 339, 432, 339, branco_intenso ;h
	linha 472, 339, 482, 339, branco_intenso ;h

	linha 432, 319, 457, 300, branco_intenso ;t -
	linha 482, 319, 457, 300, branco_intenso ;t
	linha 432, 339, 457, 358, branco_intenso ;t
	linha 482, 339, 457, 358, branco_intenso ;t
	;;
	escreve_palavra 1, 2, 16, tres, l82, branco_intenso
	mov byte[bint_3], 0
	cmp byte[status], 2 ;subindo
	jne sub4
	jmp sub2
sub4:
	mov byte[bext_4], 0
	or byte[estado_atual], 00010000b ; atualiza led
	call atualiza_led
	linha 557, 325, 557, 315, branco_intenso ;v
	linha 587, 325, 587, 315, branco_intenso ;v

	linha 557, 325, 587, 325, branco_intenso ;h

	linha 557, 315, 547, 315, branco_intenso ;h
	linha 587, 315, 597, 315, branco_intenso ;h

	linha 547, 315, 572, 300, branco_intenso ;t
	linha 597, 315, 572, 300, branco_intenso ;t
	;apaga led 4
	jmp sai_apaga_3
sub2:;
	mov byte[bext_5], 0
	or byte[estado_atual], 00000100b ; atualiza led
	call atualiza_led

	linha 557, 333, 557, 343, branco_intenso ;v
	linha 587, 333, 587, 343, branco_intenso ;v

	linha 557, 333, 587, 333, branco_intenso ;h

	linha 557, 343, 547, 343, branco_intenso ;h
	linha 587, 343, 597, 343, branco_intenso ;h

	linha 547, 343, 572, 358, branco_intenso ;t
	linha 597, 343, 572, 358, branco_intenso ;t
;apaga led 5 ;subindo
sai_apaga_3:
	popf
	popa
	ret
;;----------------------------------------------------------------------------------------------------
apaga_4:
	pusha
	pushf
  escreve_palavra 1, 2, 16, quatro, l83, branco_intenso
	linha 442, 447, 472, 447, branco_intenso ;h
	linha 442, 447, 442, 427, branco_intenso ;v
	linha 472, 447, 472, 427, branco_intenso ;v

	linha 442, 427, 432, 427, branco_intenso ;h
	linha 472, 427, 482, 427, branco_intenso ;h

	linha 432, 427, 457, 398, branco_intenso ;t
	linha 482, 427, 457, 398, branco_intenso ;t
;---------
	linha 557, 447, 587, 447, branco_intenso ;h
	linha 557, 447, 557, 427, branco_intenso ;v
	linha 587, 447, 587, 427, branco_intenso ;v

	linha 557, 427, 547, 427, branco_intenso ;h
	linha 587, 427, 597, 427, branco_intenso ;h

	linha 547, 427, 572, 398, branco_intenso ;t
	linha 597, 427, 572, 398, branco_intenso ;t
	mov byte[bint_4], 0
	mov byte[bext_6], 0
	or byte[estado_atual], 00100000b
	call atualiza_led


	popf
	popa
	ret
;;---------------------------------------------------------------------------------------------------
;;Funcao que acende os leds cujos botoes externos foram ativados
;Logica: a cada botao comparado, incrementa o bit mais extremo em 1 se estiver ativado e da um shift left para esquerda, independentemente
;Ao final da funcao, os bits vao ter deslocado 5 posicoes, ficando na configuracao correta para enviar para a saida
acende_led:
			pusha
			pushf
			mov 	ax,0
			cmp 	byte[bext_6],1
			jne 	led4
			inc 	al
led4:
			shl 	al,1
			cmp 	byte[bext_4],1
			jne 	led2
			inc 	al
led2:
			shl 	al,1
			cmp 	byte[bext_2],1
			jne 	led5
			inc 	al
led5:
			shl 	al,1
			cmp 	byte[bext_5],1
			jne 	led3
			inc 	al
led3:
			shl 	al,1
			cmp 	byte[bext_3],1
			jne 	led1
			inc 	al
led1:
			shl 	al,1
			cmp 	byte[bext_1],1
			jne 	nnn
			inc 	al
nnn:
			mov 	dx,318h
			mov 	byte[pendentes], al
			cmp byte[status], 2 ;Verifica qual eh o status do elevador, para definir o bits enviados ao motor
			je ac_subindo
			cmp byte[status], 1
			je ac_descendo
			or al, 11000000b ;Mantem os bits dos leds como estao, e os bits do motor se estiver parado
			jmp ac_sai
ac_descendo:
			or al, 10000000b ;Manetm os bits dos leds como estao, e os bits do motor se estiver descendo
			jmp ac_sai
ac_subindo:
			or al, 01000000b ;Mantem os bits dos leds como estao, e seta os bits do motor em 01 se estiver subindo
ac_sai:
			out 	dx,al	 ; acende os leds pendentes e mantem o status do motor (parado,descendo ou subindo)
			popf
			popa
			ret

;----------------------------------------------------------------------------------------------------
;Funcao que atualiza o andar atual, e chama a funcao apaga_i do andar correspondente, para desativar os botoes, leds e setas
att_andar_imprime:
	pusha
	pushf

	cmp byte[andar_atual],1
	jne compara2
	call apaga_1
	jmp fim_att
compara2:
	cmp byte[andar_atual], 2
	jne compara3
	call apaga_2
	jmp fim_att
compara3:
	cmp byte[andar_atual], 3
	jne compara4
	call apaga_3
	jmp fim_att
compara4:
	cmp byte[andar_atual], 4
	jne fim_att
	call apaga_4

fim_att:
	popf
	popa
	ret

;;------------------------------------------------------------------------------------------------------------;;

;;Funcao que desenha a moldura da interface
moldura:
		pusha
		pushf
		linha 10, 470, 10, 10, branco_intenso
		linha 630, 470, 630, 10, branco_intenso
		linha 10, 470, 630, 470, branco_intenso
		linha 10, 10, 630, 10, branco_intenso
		popf
		popa
		ret
;;-----------------------------------------------------------------------------------------------------------;;

;;Funcao que escreve a mensagem para sair, o nome da disciplina e dos integrantes do grupo
nomes:
		pusha
		pushf
		escreve_palavra 34, 23, 3, toexit, l3, branco_intenso          ;;escreve 'Para sair do programa pressionar Q'
		escreve_palavra 43, 24, 3, projetof, l4, branco_intenso        ;;escreve 'Projeto Final de Sistemas Embarcados 2017-1'
		escreve_palavra 24, 25, 3, emilia, l5, branco_intenso          ;;escreve emilia
		escreve_palavra 22, 26, 3, marcela, l6, branco_intenso		   ;;escreve marcela
		escreve_palavra 24, 27, 3, marcelo, l7, branco_intenso         ;;escreve marcelo
		popf
		popa
		ret
;;-------------------------------------------------------------------------------------------------------------;;

;Funcao que calibra o elevador, colocando-o na posicao inicial, 4 andar
calibraele:
		pusha
		pushf

		mov     byte[init], 00h             ;Variavel para identificar se e pra apagar a mensagem ou nao
		call    escreve_mens_temp           ;Escreve mensagem de calibracao do elevador
		mov     dx, 318h                    ;Move endereco da porta de saida para dx
        xor		al,al						;Zera al
		out		dx,al	                    ;Poe 0 na porta 318h ;desliga o motor e os leds
		mov		dx,318h						;Move a saida para dx
		mov		al,40h                      ;Comando que manda o elevador SUBIR
		out		dx,al                       ;Comando que manda o elevador SUBIR
		mov     byte[status], 2             ;Variavel de estado do elevador: subindo

l18:
		mov     ax,[p_i]  ;Trecho do tecbuf
        cmp     ax,[p_t]  
        je      l18 ; 
        inc     word[p_t] 
        and     word[p_t],7 
        mov     bx,[p_t]
        xor     ax, ax 
        mov     al, [bx+tecla]  
        mov     [tecla_u],al 

        cmp     byte[tecla_u], 0B9h ;Espera tecla de espaco
        je      imprime_preto       ;Quando pressiona a tecla espaco, imprime e mensagem da calibracao de preto
		jmp l18

imprime_preto:

		mov     word[contador], 267         ;Salvar no contador de voltas que chegou no quarto andar 3*89
		call para                           ;Manda o elevador parar
		mov 	byte[status], 0             ;Variavel de estado do elevador recebe 0 = parado
		mov 	byte[status_anterior], 0    
		mov     byte[init], 11h
		call    escreve_mens_temp
		mov 	byte[andar_atual], 4       ;Atualiza o andar atual
		escreve_palavra 6, 3, 23, parado, l77, branco_intenso ;Ecreve o status do elevador na tela
		escreve_palavra 11, 4, 21, funciona, l78, branco_intenso ;Escreve o modo na tela
		escreve_palavra 1, 2, 16, quatro, l11, branco_intenso ;Escreve o andar na tela
		popf
		popa
		ret
;;-----------------------------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------------------------------------------------------------------------------
;;Funcao que desenha a interface principal
desenha_interface:
		pusha
		pushf
		;;escreve na interface
		escreve_palavra 12, 2, 3, andar, l8, branco_intenso            ;;escreve andar
		escreve_palavra 19, 3, 3, estado, l9, branco_intenso		   ;;escreve estado
		escreve_palavra 17, 4, 3, modo, l10, branco_intenso            ;;escreve modo
		escreve_palavra 8, 25, 54, chama, l14, branco_intenso          ;;escreve 'chamadas' na tabela que contem as setas
		escreve_palavra 8, 25, 68, chama, l15, branco_intenso          ;;idem
		escreve_palavra 8, 26, 54, interna, l16, branco_intenso        ;;escreve 'internas' na coluna das setas que sinalizam as chamadas internas
		escreve_palavra 8, 26, 68, externa, l17, branco_intenso        ;;escreve 'externas' na coluna das setas que sinalizam as chamadas externas
		;desenha a tabela das setas
		linha 400, 470, 400, 10, branco_intenso
		linha 515, 470, 515, 10, branco_intenso
		linha 400, 102, 630, 102, branco_intenso
		linha 400, 194, 630, 194, branco_intenso
		linha 400, 284, 630, 284, branco_intenso
		linha 400, 374, 630, 374, branco_intenso
		;;desenha setas
		;;SETA 1 INFERIOR ESQUERDA
		linha 442, 125, 472, 125, branco_intenso ;h
		linha 442, 125, 442, 145, branco_intenso ;v
		linha 472, 125, 472, 145, branco_intenso ;v

		linha 442, 145, 432, 145, branco_intenso ;h
		linha 472, 145, 482, 145, branco_intenso ;h

		linha 432, 145, 457, 174, branco_intenso ;t
		linha 482, 145, 457, 174, branco_intenso ;t
		;;SETA 2 INFERIOR DIREITA
		linha 557, 125, 587, 125, branco_intenso ;h
		linha 557, 125, 557, 145, branco_intenso ;h
		linha 587, 125, 587, 145, branco_intenso ;h

		linha 557, 145, 547, 145, branco_intenso ;h
		linha 587, 145, 597, 145, branco_intenso ;h

		linha 547, 145, 572, 174, branco_intenso ;t
		linha 597, 145, 572, 174, branco_intenso ;t

		;;SETA 3 SUPERIOR ESQUERDA
		linha 442, 447, 472, 447, branco_intenso ;h
		linha 442, 447, 442, 427, branco_intenso ;v
		linha 472, 447, 472, 427, branco_intenso ;v

		linha 442, 427, 432, 427, branco_intenso ;h
		linha 472, 427, 482, 427, branco_intenso ;h

		linha 432, 427, 457, 398, branco_intenso ;t
		linha 482, 427, 457, 398, branco_intenso ;t

		;;SETA 4 SUPERIOR DIREITA
		linha 557, 447, 587, 447, branco_intenso ;h
		linha 557, 447, 557, 427, branco_intenso ;v
		linha 587, 447, 587, 427, branco_intenso ;v

		linha 557, 427, 547, 427, branco_intenso ;h
		linha 587, 427, 597, 427, branco_intenso ;h

		linha 547, 427, 572, 398, branco_intenso ;t
		linha 597, 427, 572, 398, branco_intenso ;t

		;;SETA 5 MAIS INFERIOR DIREITA
		linha 442, 229, 442, 249, branco_intenso ;v
		linha 472, 229, 472, 249, branco_intenso ;v

		linha 442, 229, 432, 229, branco_intenso ;h
		linha 472, 229, 482, 229, branco_intenso ;h
		linha 442, 249, 432, 249, branco_intenso ;h
		linha 472, 249, 482, 249, branco_intenso ;h

		linha 432, 229, 457, 210, branco_intenso ;t
		linha 482, 229, 457, 210, branco_intenso ;t
		linha 432, 249, 457, 268, branco_intenso ;t
		linha 482, 249, 457, 268, branco_intenso ;t

		;;SETA 6 MAIS SUPERIOR DIREITA
		linha 442, 319, 442, 339, branco_intenso ;v
		linha 472, 319, 472, 339, branco_intenso ;v

		linha 442, 319, 432, 319, branco_intenso ;h
		linha 472, 319, 482, 319, branco_intenso ;h
		linha 442, 339, 432, 339, branco_intenso ;h
		linha 472, 339, 482, 339, branco_intenso ;h

		linha 432, 319, 457, 300, branco_intenso ;t -
		linha 482, 319, 457, 300, branco_intenso ;t
		linha 432, 339, 457, 358, branco_intenso ;t
		linha 482, 339, 457, 358, branco_intenso ;t

		;;SETA 7 MAIS SUPERIOR ESQUERDA

		;seta de cima
		linha 557, 333, 557, 343, branco_intenso ;v
		linha 587, 333, 587, 343, branco_intenso ;v

		linha 557, 333, 587, 333, branco_intenso ;h

		linha 557, 343, 547, 343, branco_intenso ;h
		linha 587, 343, 597, 343, branco_intenso ;h

		linha 547, 343, 572, 358, branco_intenso ;t
		linha 597, 343, 572, 358, branco_intenso ;t

		;seta de baixo
		linha 557, 325, 557, 315, branco_intenso ;v
		linha 587, 325, 587, 315, branco_intenso ;v

		linha 557, 325, 587, 325, branco_intenso ;h

		linha 557, 315, 547, 315, branco_intenso ;h
		linha 587, 315, 597, 315, branco_intenso ;h

		linha 547, 315, 572, 300, branco_intenso ;t
		linha 597, 315, 572, 300, branco_intenso ;t
		;;

		;;SETA 8 MAIS INFERIOR ESQUERDA

		;seta de cima
		linha 557, 243, 557, 253, branco_intenso ;v
		linha 587, 243, 587, 253, branco_intenso ;v

		linha 557, 243, 587, 243, branco_intenso ;h

		linha 557, 253, 547, 253, branco_intenso ;h
		linha 587, 253, 597, 253, branco_intenso ;h

		linha 547, 253, 572, 268, branco_intenso ;t
		linha 597, 253, 572, 268, branco_intenso ;t

		;seta de baixo
		linha 557, 235, 557, 225, branco_intenso ;v
		linha 587, 235, 587, 225, branco_intenso ;v

		linha 557, 235, 587, 235, branco_intenso ;h

		linha 557, 225, 547, 225, branco_intenso ;h
		linha 587, 225, 597, 225, branco_intenso ;h

		linha 547, 225, 572, 210, branco_intenso ;t
		linha 597, 225, 572, 210, branco_intenso ;t
		popf
		popa
		ret
;;----------------------------------------------------------------------------------------------------------------------------------


;;Funcao que escreve Calibrando elevador... e Aperte ESPACO no quarto andar'
escreve_mens_temp:
		pusha
		pushf
		;;imprime Calibrando elevador
		mov     cx, 22
      	mov     bx, 0
      	mov     dh, 11 ;0-29 vertical
      	mov 	dl, 31 ;0-079 horizontal
      	cmp     byte[init], 00h
      	jne     cor_preto ;;se estiver saido da tela de inicio
      	mov     byte[cor], branco_intenso
      	jmp     l1

cor_preto:
      	mov		byte[cor], preto
l1:
      	call 	cursor
      	mov 	al, [bx+ calibra]
      	call 	caracter
      	inc 	bx
      	inc 	dl
      	loop    l1

		;imprime Aperte ESPACO no quarto andar
		mov     cx, 29
      	mov     bx, 0
      	mov     dh, 12 ;0-29 vertical
      	mov 	dl, 27 ;0-079 horizontal
      	cmp     byte[init], 00h
      	jne     cor_preto2
      	mov		byte[cor], branco_intenso
      	jmp     l2

cor_preto2:
		mov     byte[cor], preto

l2:
      	call 	cursor
      	mov 	al, [bx+ espaco]
      	call 	caracter
      	inc 	bx
      	inc 	dl
      	loop    l2
      	popf
      	popa
      	ret
;;---------------------------------------------------------------------------------------------------------------------------

;;Funcao que faz o elevador descer
desce:
	pusha
	pushf

	escreve_palavra 7, 3, 23, sobe, l12, preto
	escreve_palavra 6, 3, 23, parado, l55, preto
	escreve_palavra 8, 3, 23, descendo, l53, branco_intenso
	mov     dx, 318h ;sinal para o elevador descer
	mov al, byte[estado_atual]
	xor al, 11000000b ;Zera os bits do motor; 11 xor 11 = 00
	or al, 10000000b  ;Seta os bits do motor em 10, descendo
	out     dx, al
	popf
	popa
	ret
;;----------------------------------------------------------------------------------------------------------------------------

;;Funcao que faz o elevador parar
para:
	pusha
	pushf

	mov al, byte[estado_atual]
	cmp byte[status], 1 ;Verifica o status do elevador, para setar os bits do motor corretamente
	jne seta_parado
	xor al, 10000000b ;Se estiver descendo 10 xor 10 = 00
seta_parado: xor al, 01000000b ;Se estiver subindo 01 xor 01 = 00

	or al, 11000000b ;Seta os bits do motor em 11: 00 or 11 = 11
	mov byte[estado_atual], al
	mov     dx, 318h
	out     dx, al
	escreve_palavra 7, 3, 23, sobe, l101, preto ;Apaga a palavra subindo
	escreve_palavra 8, 3, 23, descendo, l100, preto ;Apaga a palavra descendo
	escreve_palavra 6, 3, 23, parado, l58, branco_intenso ;Escrevev a palavra parado
	mov 	byte[status], 0             ;variavel de estado do elevador recebe 0 = parado
	popf
	popa
	ret
;;--------------------------------------------------------------------------------------------------------------------------

;;Funcao que faz o elevador subir
e_sobe:
	pusha
	pushf

	escreve_palavra 6, 3, 23, parado, l87, preto
	escreve_palavra 8, 3, 23, descendo, l84, preto
	escreve_palavra 7, 3, 23, sobe, l59, branco_intenso

	;mov byte[status], 2
	mov byte[status], 2
	mov     dx, 318h
	mov al, byte[estado_atual]
	xor al, 11000000b ;Zera os bits do motor e mantem os leds
	or al, 01000000b ;Manda 01 para os bits do motor
	out     dx, al

	popf
	popa
	ret
;;-------------------------------------------------------------------------------------------------------------------------
;;Funcao que recebe as entradas da porta 319h e trata o debounce
recebe_entrada:
			pushf
			pusha

			mov		dx,319h						;coloca a entrada em dx
l_2:
			in		al,dx						;recebe uma entrada e passa dx para al
			and		al,01111111b				;seta o bit mais significativo em 0
			mov		ah,al						;coloca a primeira entrada em ah
			in		al,dx                       ;recebe outra entrada e passa para al
			and		al,01111111b				;seta o bit mais significativo em 0
			cmp		al,ah                       ;ver se as entradas sao iguais
			jne		l_2                         ;Fica no loop até o valor de duas entradas seguidas serem iguais
			mov		cx,30						;loop l_30 = roda 30 vezes
l_30:
			in		al,dx                       ;recebe outra entrada
			and		al,01111111b				;Seta o bit mais significativo em 0
			cmp		al,ah                       ;compara com a anterior
			jne		l_2                         ;se nao for igual, volta pro loop anterior
			loop	l_30                        ;Verifica 30 vezes se as entradas são iguais (dentro do loop)
			mov		byte[entrada_atual],al		;coloca na entrada_atual o valor de al

			popa
			popf
			ret
;;----------------------------------------------------------------------------------------------------------------------------------------------------------

;;Funcao que conta uma volta do disco
conta_volta:
			pushf
			pusha
			cmp     byte[status],0        		;Não conta volta se o elevador estiver parado
			je      sair_conta_volta			;se estiver parado, sai da rotina
			call    recebe_entrada              ;Pega as entradas já com debounce
			mov		bl,byte[entrada_atual]		;coloca em bl o valor da entrada atual
			and		bl,01000000b				;Para verificar o bit do sensor
			cmp		bl,00000000b				;Sensor = 0, 'buraco'
			jne		sair_conta_volta			;sendo igual, entra na função "buraco"
buraco:
			call	recebe_entrada				;chama as entradas com o debounce
			mov		bl,byte[entrada_atual]		;coloca em bl a entrada atual
			and		bl,01000000b				;verifica o bit do sensor
			cmp		bl,00000000b				;compara se esta no "buraco"
			je		buraco						;verifica se saiu do 'buraco'
			cmp 	byte[status], 2
			jne 	el_desce
			inc 	word[contador]     			;contagem deve ser feita incrementando o contador caso esteja subindo
			jmp 	sair_conta_volta			;sai da rotina
el_desce:
			dec 	word[contador]

sair_conta_volta:
			popa
			popf
			ret

;----------------------------------------------------------------------------------------------------------------------------------
;Funcao que manda o valor de estado_atual para a saida, depois de atualizar os leds
atualiza_led:
	pushf
	pusha

	mov dx, 318h
	mov al, byte[estado_atual]
	out dx, al

	popf
	popa
	ret

;;Funcoes seta_bxi que pintam as setas da interface de vermelho e setam os botoes ativados em 1
seta_bx1:
	pusha
	pushf
	linha 557, 125, 587, 125, vermelho ;h
	linha 557, 125, 557, 145, vermelho ;h
	linha 587, 125, 587, 145, vermelho ;h

	linha 557, 145, 547, 145, vermelho ;h
	linha 587, 145, 597, 145, vermelho ;h

	linha 547, 145, 572, 174, vermelho ;t
	linha 597, 145, 572, 174, vermelho ;t
	mov     byte[bext_1], 1 ;salva na variavel de botoes externos
	popf
	popa
	ret
;;---------------------------------------------------------------------------------------
seta_bx2:
	pusha
	pushf
	; ;seta de baixo
	linha 557, 235, 557, 225, azul ;v
	linha 587, 235, 587, 225, azul ;v

	linha 557, 235, 587, 235, azul ;h

	linha 557, 225, 547, 225, azul ;h
	linha 587, 225, 597, 225, azul ;h

	linha 547, 225, 572, 210, azul ;t
	linha 597, 225, 572, 210, azul ;t
	mov byte[bext_2], 1 ;salva na variavel de botoes externos
	popf
	popa
	ret
;;------------------------------------------------------------------------------------------
seta_bx3:
	pusha
	pushf
	linha 557, 243, 557, 253, vermelho ;v
	linha 587, 243, 587, 253, vermelho ;v

	linha 557, 243, 587, 243, vermelho ;h

	linha 557, 253, 547, 253, vermelho ;h
	linha 587, 253, 597, 253, vermelho ;h

	linha 547, 253, 572, 268, vermelho ;t
	linha 597, 253, 572, 268, vermelho ;t
	mov     byte[bext_3], 1 ;salva na variavel de botoes externos
	popf
	popa
	ret


seta_bx4:
	pusha
	pushf
	linha 557, 325, 557, 315, azul ;v
	linha 587, 325, 587, 315, azul ;v

	linha 557, 325, 587, 325, azul ;h

	linha 557, 315, 547, 315, azul ;h
	linha 587, 315, 597, 315, azul ;h

	linha 547, 315, 572, 300, azul ;t
	linha 597, 315, 572, 300, azul ;t
	mov     byte[bext_4], 1 ;salva na variavel de botoes externos
	popf
	popa
	ret


seta_bx5:
	pusha
	pushf
	;seta de cima
	linha 557, 333, 557, 343, vermelho ;v
	linha 587, 333, 587, 343, vermelho ;v

	linha 557, 333, 587, 333, vermelho ;h

	linha 557, 343, 547, 343, vermelho ;h
	linha 587, 343, 597, 343, vermelho ;h

	linha 547, 343, 572, 358, vermelho ;t
	linha 597, 343, 572, 358, vermelho ;t

	mov     byte[bext_5], 1 ;salva na variavel de botoes externos
	popf
	popa
	ret

seta_bx6:
	pusha
	pushf
	linha 557, 447, 587, 447, azul ;h
	linha 557, 447, 557, 427, azul ;v
	linha 587, 447, 587, 427, azul ;v

	linha 557, 427, 547, 427, azul ;h
	linha 587, 427, 597, 427, azul ;h

	linha 547, 427, 572, 398, azul ;t
	linha 597, 427, 572, 398, azul ;t
	mov     byte[bext_6], 1 ;salva na variavel de botoes externos

	popf
	popa
	ret
;;---------------------------------------------------


;;Funcao que verifica os botaoes externos que foram ativados
verifica_botoes_externos:
			pusha
			pushf

			xor     bl, bl
			call 	recebe_entrada
			mov     al, byte[entrada_atual]
			and     al, 00000001b				;quarda so o bit do b1
			cmp     al, 00000001b               ;ve se esta ativado
			jne     be2	                        ;se nao, pula para o proximo
			call seta_bx1

be2:
			mov     al, byte[entrada_atual]
			and     al, 00001000b				;quarda so o bit do b2
			cmp     al, 00001000b               ;ve se esta ativado
			jne     be3                         ;se nao, pula para o proximo
			call seta_bx2

be3:
			mov     al, byte[entrada_atual]
			and     al, 00000010b				;quarda so o bit do b1
			cmp     al, 00000010b               ;ve se esta ativado
			jne     be4                         ;se nao, pula para o proximo
			call seta_bx3
be4:
			mov     al, byte[entrada_atual]
			and     al, 00010000b				;quarda so o bit do b1
			cmp     al, 00010000b               ;ve se esta ativado
			jne     be5                         ;se nao, pula para o proximo
			call seta_bx4

be5:
			mov     al, byte[entrada_atual]
			and     al, 00000100b				;quarda so o bit do b1
			cmp     al, 00000100b               ;ve se esta ativado
			jne     be6                         ;se nao, pula para o proximo
			call seta_bx5

be6:
			mov     al, byte[entrada_atual]
			and     al, 00100000b				;quarda so o bit do b1
			cmp     al, 00100000b               ;ve se esta ativado
			jne     saibotaoe                   ;se nao, sai
			call    seta_bx6

saibotaoe:
			call acende_led
			mov     al, bl

			popf
			popa
			ret


;--------------------------------------------FUNCOES DO ARQUIVO LINEC.ASM-------------------------------------------------------------
;
;Funcao cursos
;dh = linha (0-29) e  dl=coluna  (0-79)
cursor:
		pushf
		push 	ax
		push 	bx
		push	cx
		push	dx
		push	si
		push	di
		push	bp
		mov    	ah,2
		mov    	bh,0
		int    	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;;-----------------------------------------------------
;
;Funcao caracter escrito na posicao do cursor
;al= caracter a ser escrito
;cor definida na variavel cor
caracter:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
    	mov     	ah,9
    	mov     	bh,0
   		mov     	cx,1
   		mov     	bl,[cor]
    	int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;;-----------------------------------------------------------------

;Funcao plot_xy
;push x; push y; call plot_xy;  (x<639, y<479)
;cor definida na variavel cor
plot_xy:
		push		bp
		mov		bp,sp
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
	    mov     	ah,0ch
	    mov     	al,[cor]
	    mov     	bh,0
	    mov     	dx,479
		sub		dx,[bp+4]
	    mov     	cx,[bp+6]
	    int     	10h
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		4
;;------------------------------------------------------------------------------------------------------
;
;Funcaoo line
; push x1; push y1; push x2; push y2; call line;  (x<639, y<479)
line:
		push	bp
		mov		bp,sp
		pushf                 ;coloca os flags na pilha
		push 	ax
		push 	bx
		push	cx
		push	dx
		push	si
		push	di
		mov		ax,[bp+10]   ; resgata os valores das coordenadas
		mov		bx,[bp+8]    ; resgata os valores das coordenadas
		mov		cx,[bp+6]    ; resgata os valores das coordenadas
		mov		dx,[bp+4]    ; resgata os valores das coordenadas
		cmp		ax,cx
		je		line2
		jb		line1
		xchg		ax,cx
		xchg		bx,dx
		jmp		line1
line2:						; deltax=0
 		cmp		bx,dx  		;subtrai dx de bx
		jb		line3
		xchg	bx,dx       ;troca os valores de bx e dx entre eles
line3:	; dx > bx
		push	ax
		push	bx
		call 	plot_xy
		cmp		bx,dx
		jne		line31
		jmp		fim_line
line31:
		inc		bx
		jmp		line3
							;deltax <>0
line1:
; comparar modulos de deltax e deltay sabendo que cx>ax
; cx > ax
		push	cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push	dx
		sub		dx,bx
		ja		line32
		neg		dx
line32:
		mov		[deltay],dx
		pop		dx
		push	ax
		mov		ax,[deltax]
		cmp		ax,[deltay]
		pop		ax
		jb		line5             ;cx > ax e deltax>deltay
		push	cx
		sub		cx,ax
		mov		[deltax],cx
		pop		cx
		push	dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx
		mov		si,ax
line4:
		push	ax
		push	dx
		push	si
		sub		si,ax	         ;(x-x1)
		mov		ax,[deltay]
		imul	si
		mov		si,[deltax]		 ;arredondar
		shr		si,1             ;se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar1
		add		ax,si
		adc		dx,0
		jmp		arc1
ar1:
		sub		ax,si
		sbb		dx,0
arc1:
		idiv	word [deltax]
		add		ax,bx
		pop		si
		push	si
		push	ax
		call	plot_xy
		pop		dx
		pop		ax
		cmp		si,cx
		je		fim_line
		inc		si
		jmp		line4

line5:
		cmp		bx,dx
		jb 		line7
		xchg	ax,cx
		xchg	bx,dx
line7:
		push	cx
		sub		cx, ax
		mov		[deltax],cx
		pop		cx
		push	dx
		sub		dx,bx
		mov		[deltay],dx
		pop		dx
		mov		si,bx
line6:
		push	dx
		push	si
		push	ax
		sub		si,bx	         ;(y-y1)
		mov		ax,[deltax]
		imul	si
		mov		si,[deltay]		;arredondar
		shr		si,1			;se numerador (DX)>0 soma se <0 subtrai
		cmp		dx,0
		jl		ar2
		add		ax,si
		adc		dx,0
		jmp		arc2
ar2:
		sub		ax,si
		sbb		dx,0
arc2:
		idiv	word [deltay]
		mov		di,ax
		pop		ax
		add		di,ax
		pop		si
		push	di
		push	si
		call	plot_xy
		pop		dx
		cmp		si,dx
		je		fim_line
		inc		si
		jmp		line6

fim_line:
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		pop		bp
		ret		8

;;----------------------------------------------------FIM FUNCOES DO ARQUIVO LINEC.ASM-----------------------------------------;;

; ;;---------------------------------------------------FUNCAO KEYINT DO ARQUIVO TECBUF.ASM---------------------------------------;;
keyint:
; Guarda os valores antigos
        push    ax
        push    bx
        push    ds
        mov     ax,data ; segment data
        mov     ds,ax

        in      al, kb_data ; Lê do teclado
        mov     byte[tecla_u], al
        inc     word [p_i]  ; incrementa quando pressiona a tecla
        and     word [p_i],7
        mov     bx,[p_i] ; Coloca os três primeiros bits de [p_i] em BX
        mov     [bx+tecla],al ; Guarda o código da tecla pressionada
        in      al, kb_ctl
        or      al, 80h ; Pega os 4 últimos bits de AL
        out     kb_ctl, al
        and     al, 7Fh ; Pega os 7 primeiros bits de AL
        out     kb_ctl, al
        mov     al, eoi
        out     pictrl, al

		cmp     byte [tecla_u], 90h;  Codigo da letra Q
		jne tecla_g
		call sair
tecla_g:
		cmp     byte [tecla_u], 0A2H ; Codigo da letra G
		jne tecla_esc
		call emergencia_off ; Desliga a emergencia
		jmp fim_keyint
tecla_esc:
		cmp byte [tecla_u], 81h ; 81h é o código gerado ao soltar a tecla ESC
		jne botao1
		call emergencia_on
		jmp fim_keyint
botao1:
		cmp byte[tecla_u], 82h
		jne botao2
		call bt1
		mov byte[bint_1], 01h
		mov byte[chamada], 1
botao2:
		cmp byte[tecla_u], 83h
		jne botao3
		call bt2
		mov byte[bint_2], 01h
		mov byte[chamada], 1
botao3:
		cmp byte[tecla_u], 84h
		jne botao4
		call bt3
		mov byte[bint_3], 01h
		mov byte[chamada], 1
botao4:
		cmp byte[tecla_u], 85h
		jne fim_keyint
		call bt4
	 	mov byte[bint_4], 01h
	 	mov byte[chamada], 1

fim_keyint:
        pop     ds
        pop     bx
        pop     ax
        iret
;;-------------------------------------------------------------------------------------------------
bt1:
    pusha
	pushf
	mov byte[bint_1], 01h
	linha 442, 125, 472, 125, vermelho ;h
	linha 442, 125, 442, 145, vermelho ;v
	linha 472, 125, 472, 145, vermelho ;v

	linha 442, 145, 432, 145, vermelho ;h
	linha 472, 145, 482, 145, vermelho ;h

	linha 432, 145, 457, 174, vermelho ;t
	linha 482, 145, 457, 174, vermelho ;t
	popf
	popa
	ret
bt2:
	pusha
	pushf
	mov byte[bint_2], 01h
	linha 442, 229, 442, 249, vermelho ;v
	linha 472, 229, 472, 249, vermelho ;v

	linha 442, 229, 432, 229, vermelho ;h
	linha 472, 229, 482, 229, vermelho ;h
	linha 442, 249, 432, 249, vermelho ;h
	linha 472, 249, 482, 249, vermelho ;h

	linha 432, 229, 457, 210, vermelho ;t
	linha 482, 229, 457, 210, vermelho ;t
	linha 432, 249, 457, 268, vermelho ;t
	linha 482, 249, 457, 268, vermelho ;t
	popf
	popa
	ret
bt3:
	pusha
	pushf
	mov byte[bint_3], 01h
	linha 442, 319, 442, 339, vermelho ;v
	linha 472, 319, 472, 339, vermelho ;v

	linha 442, 319, 432, 319, vermelho ;h
	linha 472, 319, 482, 319, vermelho ;h
	linha 442, 339, 432, 339, vermelho ;h
	linha 472, 339, 482, 339, vermelho ;h

	linha 432, 319, 457, 300, vermelho ;t -
	linha 482, 319, 457, 300, vermelho ;t
	linha 432, 339, 457, 358, vermelho ;t
	linha 482, 339, 457, 358, vermelho ;t

	popf
	popa
	ret
bt4:
	pusha
	pushf
	mov byte[bint_4], 01h
	linha 442, 447, 472, 447, vermelho ;h
	linha 442, 447, 442, 427, vermelho ;v
	linha 472, 447, 472, 427, vermelho ;v

	linha 442, 427, 432, 427, vermelho ;h
	linha 472, 427, 482, 427, vermelho ;h

	linha 432, 427, 457, 398, vermelho ;t
	linha 482, 427, 457, 398, vermelho ;t

	popf
	popa
	ret



emergencia_on:
        pusha
        pushf
        mov  al, byte[status]
        mov  byte[status_anterior], al ;Salva status anterior para retornar normalmente depois
		escreve_palavra 11, 4, 21, funciona, l72, preto ;Apaga modo Funcionando
		escreve_palavra 10, 4, 21, emerg, l52, vermelho ;Escreve modo EMERGENCIA
		mov al, byte[status]
		mov byte[status_anterior], al
		call para ;Para o elevador
		mov byte[emodo], 1 ;Seta a o modo de emergencia em 1
		popf
		popa
        ret

emergencia_off:
		pusha
		pushf
		escreve_palavra 10, 4, 21, emerg, l50, preto
		escreve_palavra 11, 4, 21, funciona, l51, branco_intenso
		mov byte[emodo], 0
		mov al, byte[status_anterior] ;Recupera o status anterior
		mov byte[status], al
		cmp byte[status], 1 ;Verifica se estava subindo ou descendo
		jne volta_sobe
		call desce
		jmp sai_eg_off
volta_sobe:
		cmp byte[status], 0
		je sai_eg_off
		call e_sobe

sai_eg_off:
		popf
		popa
    ret

sair:
      	mov al, 11000000b ;Desliga o motor e apaga os leds
		mov dx, 318H
		out dx, al

		; Restaura a tabela de interrupção da BIOS
        mov  	ah,0   						; set video mode
		mov  	al,byte[modo_anterior]   	; modo anterior
		int  	10h

        cli
        xor     ax, ax
        mov     es, ax
        mov     ax, [cs_dos]
        mov     [es:int9*4+2], ax
        mov     ax, [offset_dos]
        mov     [es:int9*4], ax
        mov     ah, 4Ch ; Retorna o controle para o sistema (finaliza o programa)
        int     21h

;;----------------------------------------------------SEGUIMENTO DE DADOS--------------------------------------------------------;;
segment data

;;DECLARACAO DAS CORES;;

cor		    	db		branco_intenso
preto			equ		0
azul			equ		1
verde			equ		2
cyan			equ		3
vermelho		equ		4
magenta			equ		5
marrom			equ		6
branco			equ		7
cinza			equ		8
azul_claro		equ		9
verde_claro		equ		10
cyan_claro		equ		11
rosa			equ		12
magenta_claro	equ		13
amarelo		    equ		14
branco_intenso	equ		15

;;VARIAVEIS USADAS NA INTERRUPCAO DO TECLADO

kb_data          equ    60h  ;PORTA DE LEITURA DE TECLADO - pega o código da tecla
kb_ctl           equ    61h  ;PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
pictrl           equ    20h  ; finaliza operação do sistema
eoi              equ    20h   ; finaliza operação do sistema
int9             equ    9h  ; 09h é interrupção de teclado
cs_dos           dw     1
offset_dos       dw     1
tecla_u          db     0
tecla            resb   8
p_i              dw     0   ;ponteiro p/ interrupcao (qnd pressiona tecla)
p_t              dw     0   ;ponterio p/ interrupcao ( qnd solta tecla)
teclasc          db     0,0,13,10,'$'



status           db     0 ; 0: parado; 1: descendo; 2: subindo; > para a impressao na tela
status_anterior  db     0 ; 0: parado; 1: descendo; 2: subindo; > para a logica do elevador
emodo            db     0 ;0=funcionando 1=emergencia
bext_1  db     0
bext_2  db     0
bext_3  db     0
bext_4  db     0
bext_5  db     0
bext_6  db     0

bint_1  db     0
bint_2  db     0
bint_3  db     0
bint_4  db     0

contador         dw     0
init             db     0 ;;byte para determinar se ja saiu da tela de inicio 0 = nao, 1 = sim
proximo_andar    dw     0

andar_atual	     db	    00h
proximo			 db	    00h
entrada_atual    db     00h
chamada          db     00h
estado_atual	db	00h
pendentes	db	00h

modo_anterior	db		0
linha   		dw  	0
coluna  		dw  	0
deltax			dw	    0
deltay			dw	    0

;;DECLARACAO DAS MENSAGENS A IMPRIMIR

calibra     db          'Calibrando elevador...'
espaco      db          'Aperte ESPACO no quarto andar'
toexit    	db  		'Para sair do programa pressionar Q'
projetof    db          'Projeto Final de Sistemas Embarcados 2017-1'
emilia      db          'Emilia Frigerio Cremasco'
marcela     db          'Marcela Freitas Vieira'
marcelo     db          'Marcelo Bringuenti Pedro'

andar       db          'Andar atual:'
um          db          '1'
dois        db          '2'
tres        db          '3'
quatro      db          '4'
estado      db          'Estado do elevador:'
modo        db          'Modo de operacao:'
parado      db          'Parado'
sobe        db          'Subindo'
descendo       db          'Descendo'
funciona    db          'Funcionando'
emerg       db          'EMERGENCIA'
chama       db          'Chamadas'
interna     db          'INTERNAS'
externa     db          'EXTERNAS'


;*************************************************************************
segment stack stack
    		resb 		512
stacktop:
