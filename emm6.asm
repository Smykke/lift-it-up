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
  		xor     ax, ax  ; zera o AX
        mov     es, ax  ; Faz o ES [Extra Segment Register] apontar para 0h, que é o espaço reservado para vetores de interrupção
; Salvando o segmento antigo
        mov     ax, [es:int9*4] ; AX recebe o endereço antigo da próxima instrução [IP - Instruction Pointer] (que INT 9h estava apontando)
        mov     [offset_dos], ax  ; Esse endereço é guardado em offset_dos
        mov     ax, [es:int9*4+2] ; AX recebe o endereço antigo de CS (que estava sendo apontado por INT 9h)
        mov     [cs_dos], ax  ; Esse endereço é guardado em cs_dos
        cli     ; Clear Interruption Flag - faz o processador ignorar as interrupções mascaradas
; Substituindo a tabela da BIOS pela nossa tabela
        mov     [es:int9*4+2], cs ; Guarda o CS como nova próxima instrução depois da interrupção
        mov     WORD [es:int9*4],keyint ; Salva a nova sequência de tratamento de interrupção
        sti     ; Set Interruption Flag - ativa as interrupções

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
	call moldura
	call nomes

	call calibraele
	call desenha_interface ;;colocar isso dentro do loop infinito??

	enquanto:
			
	cmp byte[emodo], 1
	je enquanto; 		
	call verifica_botoes_externos
	call decide

	acao:
		
		mov bl, byte[andar_atual]
		cmp byte[proximo], bl
		je cheguei
		cmp byte[status], 0
		je enquanto
		cmp byte[status], 1
		je to_desce
		cmp byte[status], 2
		je to_sobe

	;;funcao
	to_desce:
		call desce
		;cmp byte[andar_atual], 2
		;je cont3
		mov ax, word[contador] 
		sub ax, 89
	cont2:
		call conta_volta
		call verifica_botoes_externos
		cmp word[contador], ax 
		jne cont2
		dec byte[andar_atual] 
		mov bl, byte[andar_atual]
		cmp byte[proximo], bl
		je cheguei
		jmp enquanto


	cheguei:
	 		call att_andar_imprime
	 		call para
	 		call delay
	 		
	 		jmp enquanto

	to_sobe:
		call e_sobe
		mov ax, word[contador]
		add ax, 89
	cont3:
		call conta_volta
		call verifica_botoes_externos
		cmp word[contador], ax
		jne cont3
		inc byte[andar_atual]
		mov bl, byte[andar_atual]
		cmp byte[proximo], bl
		je cheguei
		jmp enquanto


;;--------------------------------------------------FIM PROGRAMA PRINCIPAL-----------------------------------;;

;;---------------------------------------------------FUNCOES ADICIONAIS--------------------------------------;;
;;------------------------------------------------------------------------------------------------------------;;

decide:
 	pusha
 	pushf


 	cmp byte[andar_atual], 4
 	je forthfloor
 	cmp byte[andar_atual], 3
 	je thirdfloor
 	cmp byte[andar_atual], 2
 	je scdfloor
 	cmp byte[andar_atual], 1
 	je firstfloor

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

andar_4:
	pusha
	pushf

	cmp byte[status], 1
	je c_d_4
	jmp c_p_4

c_p_4:
	;call apaga_led6
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

c_d_4:
	cmp byte[bint_4], 1
	je a_4_4
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
	jmp sai_andar4

;;-------------------------------------
a_4_4:
	mov byte[bint_4], 0
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

;;---------------------------------------------------------
andar_3:
	pusha
	pushf

	cmp byte[status], 0
	je c_p_3
	cmp byte[status], 2
	je c_s_3
	jmp c_d_3

c_p_3:
	;call apaga_led5
	;call apaga_led4
	cmp byte[bint_3],1
	je a_3_3
	cmp byte[bint_4], 1
	je a_3_4
	cmp byte[bint_2], 1
	jne t2
	jmp a_3_2
t2:	cmp byte[bint_1], 1
	jne t1
	jmp a_3_1
t1:	cmp byte[bext_6], 1
	je a_3_4
	cmp byte[bext_3], 1
	je a_3_2
	cmp byte[bext_2], 1
	je a_3_2
	cmp byte[bext_1], 1
	je a_3_1
	jmp sai_andar3

c_s_3:
	cmp byte[bint_4], 1
	je a_3_4
	cmp byte[bint_3], 1
	je a_3_3
	cmp byte[bext_6], 1
	je a_3_4
	jmp sai_andar3

c_d_3:
	cmp byte[bint_3], 1
	je a_3_3
	cmp byte[bint_2], 1
	je a_3_2
	cmp byte[bint_1], 1
	je a_3_1
	cmp byte[bext_2], 1 ;desce primeiro andar
	jmp sai_andar3

;--

a_3_3:
	cmp byte[status], 0
	je a3
	mov byte[proximo], 3
	jmp sai_andar3
a3:
	mov byte[bint_3], 0
	jmp sai_andar3


a_3_4:
	mov byte[status], 2 ;sobe
	mov byte[proximo], 4
	jmp sai_andar3

a_3_2:
	mov byte[status], 1 ;;desce
	mov byte[proximo], 2
	jmp sai_andar3

a_3_1:
	mov byte[status], 1 ;;desce
	mov byte[proximo], 1
	jmp sai_andar3

sai_andar3:
	popf
	popa
	ret
;;------------------------------------------------------------------------------------------------
andar_2:
	pusha
	pushf

	cmp byte[status], 0
	je c_p_2
	cmp byte[status], 2
	je c_s_2
	jmp c_d_2

c_p_2:
	;call apaga_led3
	;call apaga_led2
	cmp byte[bint_2], 1
	je a_2_2
	cmp byte[bint_1], 1
	jne t
	jmp a_2_1
t:	cmp byte[bint_3], 1 ;t:small fix: pra nao dar out of range
	je a_2_3
	cmp byte[bint_4], 1
	je a_2_4
	cmp byte[bext_1], 1 ;1 andar
	je a_2_1
	cmp byte[bext_4], 1 ;3 andar
	je a_2_3
	cmp byte[bext_5], 1 ;3 andar
	je a_2_3
	cmp byte[bext_6], 1
	je a_2_4
	jmp sai_andar2	

c_s_2:
	cmp byte[bint_2], 1
	je a_2_2
	cmp byte[bint_3], 1
	je a_2_3
	cmp byte[bint_4], 1
	je a_2_4
	cmp byte[bext_5], 1	;sobe andar 3
	je a_2_3
	cmp byte[bext_6], 1
	jmp sai_andar2

c_d_2:
	cmp byte[bint_1], 1
	je a_2_1
	cmp byte[bint_2], 1
	je a_2_2
	jmp sai_andar2
;;---------	
a_2_2:
	cmp byte[status], 0
	je a2
	mov byte[proximo], 2
	jmp sai_andar2
a2:
	mov byte[bint_2], 0
	jmp sai_andar2
a_2_4:
	mov byte[status], 2 ;sobe
	mov byte[proximo], 4
	jmp sai_andar2
a_2_3:
	mov byte[status], 2 ;sobe
	mov byte[proximo], 3
	jmp sai_andar2
a_2_1:
	mov byte[status], 1 ;desce
	mov byte[proximo], 1
	jmp sai_andar2
sai_andar2:
	popf
	popa
	ret

;;-------------------------------------------------------------------------------------------------

andar_1:
	pusha
	pushf

	cmp byte[status], 2
	je c_s_1
	jmp c_p_1


c_p_1:
	;call apaga_led1
	cmp byte[bint_1], 1
	jne t3 
	jmp a_1_1
t3:	
	cmp byte[bint_2], 1
	jne t4
	jmp a_1_2
t4:	cmp byte[bint_3], 1
	je a_1_3
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
	jmp sai_andar1

c_s_1:
	cmp byte[bint_1], 1
	je a_1_1
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




a_1_1:
	mov byte[bint_1], 0
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
	call verifica_botoes_externos
	mov ah, 0
	int 1ah
	sub dx, bx
	cmp di, dx
	ja espera
	popf
	popa
	ret

;;----------------------------------------------------------
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
	mov byte[bext_2], 0
	mov byte[bext_3], 0
	cmp byte[status], 2 ;descendo
	jne sub3
	jmp sub1
sub3:
	linha 557, 235, 557, 225, branco_intenso ;v
	linha 587, 235, 587, 225, branco_intenso ;v

	linha 557, 235, 587, 235, branco_intenso ;h

	linha 557, 225, 547, 225, branco_intenso ;h
	linha 587, 225, 597, 225, branco_intenso ;h

	linha 547, 225, 572, 210, branco_intenso ;t
	linha 597, 225, 572, 210, branco_intenso ;t
	jmp sai_apaga_2
sub1: 
	; linha 557, 243, 557, 253, branco_intenso ;v
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
	mov byte[bext_4], 0
	mov byte[bext_5], 0
	cmp byte[status], 2 ;descendo
	jne sub4
	jmp sub2
sub4:
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
	;apaga led 6

	popf
	popa
	ret
;;---------------------------------------------------------------------------------------------------
	

;----------------------------------------------------------------------------------------------------
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

		mov     byte[init], 00h
		call    escreve_mens_temp
		mov     dx, 318h                    ;move endereco da porta de saida para dx
        xor		al,al						;zera al
		out		dx,al	                    ;poe 0 na porta 318h
		mov		dx,319h						;move endereco da porta de entrada 319h(botoesexternos) para dx
		inc		al							;PRECISA DISSO?????;Apaga o LED da porta 319H e define a porta 318H como porta de saída
		out		dx,al						;al passa par dx
		mov		dx,318h						;move a saida para dx
		mov		al,40h                      ;Comando que manda o elevador SUBIR
		out		dx,al
		mov     byte[status], 2             ;variavel de estado do elevador: subindo

l18:
		mov     ax,[p_i]  ; pont p/ int quando pressiona a tecla
        cmp     ax,[p_t]  ; verifica se soltou a tecla
        je      l18 ; se soltou, permanece no loop
        inc     word[p_t] ; se a tecla estiver pressionada, incrementa
        and     word[p_t],7 ; pega os três últimos bits de [p_t]
        mov     bx,[p_t]
        xor     ax, ax  ; zera AX
        mov     al, [bx+tecla]  ;
        mov     [tecla_u],al ; Recebe o código da tecla (depois de solta)

        cmp     byte[tecla_u], 0B9h ;;espera tecla de espaco
        je      imprime_preto
		jmp l18

imprime_preto:

		mov     word[contador], 267         ;salvar no contador de giros que chegou no quarto andar 3*89
		mov     dx, 318h
		mov     al, 00h                     ;sinal para o elevador parar
		out     dx, al
		mov 	byte[status], 0             ;variavel de estado do elevador recebe 0 = parado
		mov 	byte[status_anterior], 0             ;variavel de estado do elevador recebe 0 = parado
		mov     byte[init], 11h
		call    escreve_mens_temp
		mov 	byte[andar_atual], 4
		mov		byte[proximo], 4
		escreve_palavra 6, 3, 23, parado, l77, branco_intenso
		escreve_palavra 11, 4, 21, funciona, l78, branco_intenso
		escreve_palavra 1, 2, 16, quatro, l11, branco_intenso
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

	;cmp byte[status], 0
	;jne desce;;???????????
	escreve_palavra 7, 3, 23, sobe, l12, preto
	escreve_palavra 6, 3, 23, parado, l55, preto
	escreve_palavra 8, 3, 23, descendo, l53, branco_intenso
	;mov byte[status], 1
	mov     dx, 318h ;sinal para o elevador descer
	mov     al, 80h
	out     dx, al
	or byte[estado_atual], 10111111b
	 

	popf
	popa
	ret
;;----------------------------------------------------------------------------------------------------------------------------

;;Funcao que faz o elevador parar
para:
	pusha
	pushf

	mov     dx, 318h
	mov     al, 11000000b                   ;sinal para o elevador parar
	out     dx, al


	escreve_palavra 7, 3, 23, sobe, l101, preto

	escreve_palavra 8, 3, 23, descendo, l100, preto
	escreve_palavra 6, 3, 23, parado, l58, branco_intenso

	mov 	byte[status], 0             ;variavel de estado do elevador recebe 0 = parado
	or byte[estado_atual], 11111111b


	popf
	popa
	ret
;;--------------------------------------------------------------------------------------------------------------------------

;;Funcao que faz o elevador subir
e_sobe:
	pusha
	pushf

	
	;mov byte[status], 2
	mov     dx, 318h
	mov     al, 40h ;sinal para o elevador subir
	out     dx, al
	escreve_palavra 6, 3, 23, parado, l87, preto
	escreve_palavra 8, 3, 23, descendo, l84, preto
	escreve_palavra 7, 3, 23, sobe, l89, branco_intenso
	
	or byte[estado_atual], 01111111b

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
			jne		l_2                     ;Fica no loop até o valor de duas entradas seguidas serem iguais
			mov		cx,30						;loop l_30 = roda 30 vezes
l_30:
			in		al,dx                       ;recebe outra entrada
			and		al,01111111b				;Seta o bit mais significativo em 0
			cmp		al,ah                       ;compara com a anterior
			jne		l_2                         ;se nao for igual, volta pro loop anterior
			loop	l_30                        ;Verifica 30 vezes se as entradas são iguais (dentro do loop)
			mov		byte[entrada_atual],al		;coloca na entrada atual o valor de al

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
;pinta seta 1
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
	linha 557, 235, 557, 225, vermelho ;v
	linha 587, 235, 587, 225, vermelho ;v

	linha 557, 235, 587, 235, vermelho ;h

	linha 557, 225, 547, 225, vermelho ;h
	linha 587, 225, 597, 225, vermelho ;h

	linha 547, 225, 572, 210, vermelho ;t
	linha 597, 225, 572, 210, vermelho ;t
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
	linha 557, 325, 557, 315, vermelho ;v
	linha 587, 325, 587, 315, vermelho ;v

	linha 557, 325, 587, 325, vermelho ;h

	linha 557, 315, 547, 315, vermelho ;h
	linha 587, 315, 597, 315, vermelho ;h

	linha 547, 315, 572, 300, vermelho ;t
	linha 597, 315, 572, 300, vermelho ;t
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
	linha 557, 447, 587, 447, vermelho ;h
	linha 557, 447, 557, 427, vermelho ;v
	linha 587, 447, 587, 427, vermelho ;v

	linha 557, 427, 547, 427, vermelho ;h
	linha 587, 427, 597, 427, vermelho ;h

	linha 547, 427, 572, 398, vermelho ;t
	linha 597, 427, 572, 398, vermelho ;t
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
			call 	seta_bx1
			or 		byte[estado_atual], 0000001      ;ativa o led correspondente
			mov 	dx, 318h
            mov 	al, byte[entrada_atual]
            out 	dx, al
be2:
			mov     al, byte[entrada_atual]
			and     al, 00001000b				;quarda so o bit do b2
			cmp     al, 00001000b               ;ve se esta ativado
			jne     be3                         ;se nao, pula para o proximo
			call 	seta_bx2
            or 		byte[estado_atual], 00000010b				;ativa o led correspondente
            mov 	dx, 318h
            mov 	al, byte[entrada_atual]
            out 	dx, al
be3:
			mov     al, byte[entrada_atual]
			and     al, 00000010b				;quarda so o bit do b1
			cmp     al, 00000010b               ;ve se esta ativado
			jne     be4                         ;se nao, pula para o proximo
			call 	seta_bx3
            or      byte[estado_atual], 00000100b				;ativa o led correspondente
            mov 	dx, 318h
            mov 	al, byte[entrada_atual]
            out 	dx, al
be4:
			mov     al, byte[entrada_atual]
			and     al, 00010000b				;quarda so o bit do b1
			cmp     al, 00010000b               ;ve se esta ativado
			jne     be5                         ;se nao, pula para o proximo
			call seta_bx4
            or      byte[estado_atual], 00001000b				;ativa o led correspondente
            mov 	dx, 318h
            mov 	al, byte[entrada_atual]
            out 	dx, al
be5:
			mov     al, byte[entrada_atual]
			and     al, 00000100b								;quarda so o bit do b1
			cmp     al, 00000100b               				;ve se esta ativado
			jne     be6                         				;se nao, pula para o proximo
			call 	seta_bx5
            or      byte[estado_atual], 00010000b				;ativa o led correspondente
            mov 	dx, 318h
            mov 	al, byte[entrada_atual]
            out 	dx, al
be6:
			mov     al, byte[entrada_atual]
			and     al, 00100000b								;quarda so o bit do b1
			cmp     al, 00100000b               				;ve se esta ativado
			jne     saibotaoe                   				;se nao, sai
			call    seta_bx6
            or      byte[estado_atual], 00100000b				;ativa o led correspondente
            mov 	dx, 318h
            mov 	al, byte[entrada_atual]
            out 	dx, al

saibotaoe:				           

			popf
			popa
			ret
;;-----------------------------------------------------------------------------------------------------------------------------------------------



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
tecla_esc:
		; cmp     byte [emodo], 1 ;se esta em emergencia
		; call      enquanto ; Se estiver em estado de emergencia, fica no loop ate voltar ao normal (apertar a tecla G)
		cmp byte [tecla_u], 81h ; 81h é o código gerado ao soltar a tecla ESC
		jne botao1
		call emergencia_on
botao1:
		cmp byte[tecla_u], 82h
		jne botao2
		call bt1
		; add byte[bint_1], 1h
		mov byte[bint_1], 01h
botao2:
		cmp byte[tecla_u], 83h
		jne botao3
		call bt2
		mov byte[bint_2], 01h
botao3:
		cmp byte[tecla_u], 84h
		jne botao4
		call bt3
		mov byte[bint_3], 01h
botao4:
		cmp byte[tecla_u], 85h
		jne fim_keyint
		call bt4
	 	mov byte[bint_4], 01h

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

;;----------------------------------------------------------------

emergencia_on:
    pusha
    pushf
   ; mov byte [emodo], 1 ; verificar se tem necessidade
    mov  al, byte[status]
    mov  byte[status_anterior], al
	escreve_palavra 10, 4, 21, emerg, l52, vermelho
	call para
	mov byte[emodo], 1
	popf
	popa
    ret

emergencia_off:
	pusha
	pushf
    ;mov byte [emodo], 0 ;parado      ~verificar se tem necessidade
	escreve_palavra 10, 4, 21, emerg, l50, preto
	escreve_palavra 11, 4, 21, funciona, l51, branco_intenso
	mov al, byte[status_anterior]
	mov byte[status], al
	mov byte[emodo], 0
	popf
	popa
    ret

sair:
	; Restaura a tabela de interrupção da BIOS
  	call para
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
contagem		 dw	    0
init             db     0 ;;byte para determinar se ja saiu da tela de inicio 0 = nao, 1 = sim
proximo_andar    dw     0
delay_cont       dw     0


andar_atual	     db	    00h
proximo			 db	    00h
entrada_atual    db     00h	
estado_atual     db     00h





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







;;;;;;;;;;;;;;;;;;;;;;;;; MACROS DA INTERFACE, DEIXEI AQUI POR PRECAUCAO, NAO APAGUE;;;;;;;;;;;;;
;;------------------------------------------------CALIBRANDO-------------------------------------------------;;
; escreve_palavra 22, 11, 31, calibra, l1, branco_intenso
; ;escreve_palavra 29, 12, 27, espaco, l2, branco_intenso

; ;;-----------------------------------------------------ANDAR------------------------------------------------;;
;escreve_palavra 12, 2, 3, andar, l8, branco_intenso
;escreve_palavra 1, 2, 16, um, l11, branco_intenso
;escreve_palavra 1, 2, 16, dois, l11, branco_intenso
;escreve_palavra 1, 2, 16, tres, l11, branco_intenso
;escreve_palavra 1, 2, 16, quatro, l11, branco_intenso

;----------------------------------------------------ESTADO-------------------------------------------------;;
;escreve_palavra 19, 3, 3, estado, l9, branco_intenso
;escreve_palavra 6, 3, 23, parado, l12, branco_intenso
;escreve_palavra 7, 3, 23, sobe, l12, branco_intenso
;escreve_palavra 8, 3, 23, desce, l12, branco_intenso

;;-------------------------------------------------------MODO-----------------------------------------------;;
;escreve_palavra 17, 4, 3, modo, l10, branco_intenso
;escreve_palavra 11, 4, 21, funciona, l13, branco_intenso
;escreve_palavra 10, 4, 21, emerg, l13, vermelho


; escreve_palavra 34, 23, 3, toexit, l3, branco_intenso
; escreve_palavra 43, 24, 3, projetof, l4, branco_intenso
; escreve_palavra 24, 25, 3, emilia, l5, branco_intenso
; escreve_palavra 22, 26, 3, marcela, l6, branco_intenso
; escreve_palavra 24, 27, 3, marcelo, l7, branco_intenso

;;---------------------------------------------------------CHAMADAS-----------------------------------------;;

; escreve_palavra 8, 25, 54, chama, l14, branco_intenso
; escreve_palavra 8, 25, 68, chama, l15, branco_intenso
; escreve_palavra 8, 26, 54, interna, l16, branco_intenso
; escreve_palavra 8, 26, 68, externa, l17, branco_intenso

;;-------------------------------------------------------MOLDURA---------------------------------------------;;
; linha 10, 470, 10, 10, branco_intenso
; linha 630, 470, 630, 10, branco_intenso

; linha 10, 470, 630, 470, branco_intenso
; linha 10, 10, 630, 10, branco_intenso

; ;;SETA 1 INFERIOR ESQUERDA
; linha 442, 125, 472, 125, branco_intenso ;h
; linha 442, 125, 442, 145, branco_intenso ;v
; linha 472, 125, 472, 145, branco_intenso ;v

; linha 442, 145, 432, 145, branco_intenso ;h
; linha 472, 145, 482, 145, branco_intenso ;h

; linha 432, 145, 457, 174, branco_intenso ;t
; linha 482, 145, 457, 174, branco_intenso ;t
; ;;SETA 2 INFERIOR DIREITA
; linha 557, 125, 587, 125, branco_intenso ;h
; linha 557, 125, 557, 145, branco_intenso ;h
; linha 587, 125, 587, 145, branco_intenso ;h

; linha 557, 145, 547, 145, branco_intenso ;h
; linha 587, 145, 597, 145, branco_intenso ;h

; linha 547, 145, 572, 174, branco_intenso ;t
; linha 597, 145, 572, 174, branco_intenso ;t

; ;;SETA 3 SUPERIOR ESQUERDA
; linha 442, 447, 472, 447, branco_intenso ;h
; linha 442, 447, 442, 427, branco_intenso ;v
; linha 472, 447, 472, 427, branco_intenso ;v

; linha 442, 427, 432, 427, branco_intenso ;h
; linha 472, 427, 482, 427, branco_intenso ;h

; linha 432, 427, 457, 398, branco_intenso ;t
; linha 482, 427, 457, 398, branco_intenso ;t

; ;;SETA 4 SUPERIOR DIREITA
; linha 557, 447, 587, 447, branco_intenso ;h
; linha 557, 447, 557, 427, branco_intenso ;v
; linha 587, 447, 587, 427, branco_intenso ;v

; linha 557, 427, 547, 427, branco_intenso ;h
; linha 587, 427, 597, 427, branco_intenso ;h

; linha 547, 427, 572, 398, branco_intenso ;t
; linha 597, 427, 572, 398, branco_intenso ;t

; ;;SETA 5 MAIS INFERIOR DIREITA
; linha 442, 229, 442, 249, branco_intenso ;v
; linha 472, 229, 472, 249, branco_intenso ;v

; linha 442, 229, 432, 229, branco_intenso ;h
; linha 472, 229, 482, 229, branco_intenso ;h
; linha 442, 249, 432, 249, branco_intenso ;h
; linha 472, 249, 482, 249, branco_intenso ;h

; linha 432, 229, 457, 210, branco_intenso ;t
; linha 482, 229, 457, 210, branco_intenso ;t
; linha 432, 249, 457, 268, branco_intenso ;t
; linha 482, 249, 457, 268, branco_intenso ;t

; ;;SETA 6 MAIS SUPERIOR DIREITA
; linha 442, 319, 442, 339, branco_intenso ;v
; linha 472, 319, 472, 339, branco_intenso ;v

; linha 442, 319, 432, 319, branco_intenso ;h
; linha 472, 319, 482, 319, branco_intenso ;h
; linha 442, 339, 432, 339, branco_intenso ;h
; linha 472, 339, 482, 339, branco_intenso ;h

; linha 432, 319, 457, 300, branco_intenso ;t -
; linha 482, 319, 457, 300, branco_intenso ;t
; linha 432, 339, 457, 358, branco_intenso ;t
; linha 482, 339, 457, 358, branco_intenso ;t

; ;;SETA 7 MAIS SUPERIOR ESQUERDA

; ;seta de cima
; linha 557, 333, 557, 343, branco_intenso ;v
; linha 587, 333, 587, 343, branco_intenso ;v

; linha 557, 333, 587, 333, branco_intenso ;h

; linha 557, 343, 547, 343, branco_intenso ;h
; linha 587, 343, 597, 343, branco_intenso ;h

; linha 547, 343, 572, 358, branco_intenso ;t
; linha 597, 343, 572, 358, branco_intenso ;t

; ;seta de baixo
; linha 557, 325, 557, 315, branco_intenso ;v
; linha 587, 325, 587, 315, branco_intenso ;v

; linha 557, 325, 587, 325, branco_intenso ;h

; linha 557, 315, 547, 315, branco_intenso ;h
; linha 587, 315, 597, 315, branco_intenso ;h

; linha 547, 315, 572, 300, branco_intenso ;t
; linha 597, 315, 572, 300, branco_intenso ;t
; ;;

; ;;SETA 8 MAIS INFERIOR ESQUERDA

; ;seta de cima
; linha 557, 243, 557, 253, branco_intenso ;v
; linha 587, 243, 587, 253, branco_intenso ;v

; linha 557, 243, 587, 243, branco_intenso ;h

; linha 557, 253, 547, 253, branco_intenso ;h
; linha 587, 253, 597, 253, branco_intenso ;h

; linha 547, 253, 572, 268, branco_intenso ;t
; linha 597, 253, 572, 268, branco_intenso ;t

; ;seta de baixo
; linha 557, 235, 557, 225, branco_intenso ;v
; linha 587, 235, 587, 225, branco_intenso ;v

; linha 557, 235, 587, 235, branco_intenso ;h

; linha 557, 225, 547, 225, branco_intenso ;h
; linha 587, 225, 597, 225, branco_intenso ;h

; linha 547, 225, 572, 210, branco_intenso ;t
; linha 597, 225, 572, 210, branco_intenso ;t
