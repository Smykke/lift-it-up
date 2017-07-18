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
%endmacro  

%macro escreve_palavra 6	;caracteres, dh,dl,nome,loop, cor
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
%endmacro	

;--------------------------------------------------------FIM MACROS------------------------------------------;;	

;;---------------------------------------------------PROGRAMA PRINCIPAL--------------------------------------;;		

		call moldura
		call calibraele
		call desenha_interface ;;colocar isso dentro do loop infinito??
; enquanto:		
; 		mov     ax,[p_i]  ; pont p/ int quando pressiona a tecla
;         cmp     ax,[p_t]  ; verifica se soltou a tecla
;         je      enquanto ; se soltou, permanece no loop
;         inc     word[p_t] ; se a tecla estiver pressionada, incrementa
;         and     word[p_t],7 ; pega os três últimos bits de [p_t]
;         mov     bx,[p_t]
;         xor     ax, ax  ; zera AX
;         mov     al, [bx+tecla]  ;
;         mov     [tecla_u],al ; Recebe o código da tecla (depois de solta)

;         cmp     byte [tecla_u], 0A2H ; Codigo da letra G
;         je      emergencia_off ; Desliga a emergencia
;         cmp     byte [emodo], 1 ;se esta em emergencia
;         je      enquanto ; Se estiver em estado de emergencia, fica no loop ate voltar ao normal (apertar a tecla G)
;         cmp     byte [tecla_u], 81h ; 81h é o código gerado ao soltar a tecla ESC
;         je      emergencia_on  ; Liga a emergencia
;         ;call    verifica_botao_interno
;         ;call    verifica_botao_externo
;         ;call    atualiza_setas ;;funcao que liga as setas dos botoes externos correspondentes
;         ;call     andar_atual ;;funcao que decide em qual andar o elevador está
;         cmp     byte [tecla_u], 90h;  Codigo da letra Q
;         je      sair
;         jmp     enquanto

; emergencia_on:
;         mov byte [emodo], 1 
;         jmp enquanto

; emergencia_off:
;         mov byte [emodo], 0 ;parado
;         jmp enquanto

; sair: ; Restaura a tabela de interrupção da BIOS
;         ;;mov     dx, int_o
;         ;;call imprime
;         mov  	ah,0   						; set video mode
; 		mov  	al,byte[modo_anterior]   	; modo anterior
; 		int  	10h 

;         cli
;         xor     ax, ax
;         mov     es, ax
;         mov     ax, [cs_dos]
;         mov     [es:int9*4+2], ax
;         mov     ax, [offset_dos]
;         mov     [es:int9*4], ax
;         mov     ah, 4Ch ; Retorna o controle para o sistema (finaliza o programa)
;         int     21h
  		



;;--------------------------------------------------FIM PROGRAMA PRINCIPAL-----------------------------------;;


;;---------------------------------------------------FUNCOES ADICIONAIS--------------------------------------;;

;;Funcao que verifica quais botoes internos foram pressionados
verifica_botao_interno:
		pusha
		pushf

		cmp     byte [tecla_u], 82h; Codigo do 1
        jne     bi2
        add 	byte [botoes_internos], 01h

bi2:   
 		cmp     byte [tecla_u], 83h; Codigo do 2
        jne     bi3  ; Botao interno 2
        add 	byte [botoes_internos], 02h

bi3
        cmp     byte [tecla_u], 84h; Codigo do 3
        jne     bi4 ; Botao interno 3
        add 	byte [botoes_internos], 04h

bi4:        
        cmp     byte [tecla_u], 85h; Codigo do 4
        jne     saiibotao  ; Botao interno 4
        add 	byte [botoes_internos], 08h

saiibotao:
		popf
		popa
		ret
;-----------------------------------------------------------------------------------------------------------------;;




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
;------------------------------------------------------------------------------------------------------------------------------------

;Funcao que calibra o elevador, colocando-o na posicao inicial, 4 andar
calibraele:
		pusha
		pushf
		mov     byte[init], 00h
		call    escreve_mens_temp
		; mov     dx, 318h                    ;move endereco da porta de saida para dx  
  ;       xor		al,al						;zera al
		; out		dx,al	                    ;poe 0 na porta 318h
		; mov		dx,319h						;move endereco da porta de entrada 319h(botoesexternos) para dx
		; ;inc		al							;PRECISA DISSO?????;Apaga o LED da porta 319H e define a porta 318H como porta de saída
		; out		dx,al						;al passa par dx
		; mov		dx,318h						;move a saida para dx 	
		; mov		al,40h                      ;Comando que manda o elevador SUBIR
		; out		dx,al	
l18:    
		cmp     byte[tecla_u], 0B9h ; aguarda ate ser pressionada a tecla espaco para sinalizar que chegou no quarto andar
		jne     l18
		; mov     word[contador], 267         ;salvar no contador de giros que chegou no quarto andar 3*89
		; mov     dx, 318h
		; mov     al, 80h
		; out     dx, al                      ;sinal para o elevador descer 
; l19:
; 		;aguarda condicao x
; 		jne 	l19

		; mov     dx, 318h
		; mov     al, 00h                     ;sinal para o elevador parar
		; out     dx, al
		mov 	byte[status], 0             ;variavel de estado do elevador recebe 0 = parado
		mov     byte[init], 11h
		call    escreve_mens_temp
		popf
		popa
		ret
;--------------------------------------------------------------------------------------------------------------------------------------------

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
;-------------------------------------------------------------------------------------------------------------------------------------------------------



;-------------------------------------------------------------------------------------------------------------------------------------------------------
desenha_interface:
		pusha
		pushf
		;;escreve na interface
		escreve_palavra 12, 2, 3, andar, l8, branco_intenso            ;;escreve andar
		escreve_palavra 19, 3, 3, estado, l9, branco_intenso		   ;;escreve estado
		escreve_palavra 17, 4, 3, modo, l10, branco_intenso            ;;escreve modo
		escreve_palavra 34, 23, 3, toexit, l3, branco_intenso          ;;escreve 'Para sair do programa pressionar Q'
		escreve_palavra 43, 24, 3, projetof, l4, branco_intenso        ;;escreve 'Projeto Final de Sistemas Embarcados 2017-1'
		escreve_palavra 24, 25, 3, emilia, l5, branco_intenso          ;;escreve emilia
		escreve_palavra 22, 26, 3, marcela, l6, branco_intenso		   ;;escreve marcela
		escreve_palavra 24, 27, 3, marcelo, l7, branco_intenso         ;;escreve marcelo
		escreve_palavra 8, 25, 54, chama, l14, branco_intenso          ;;escreve 'chamadas' na tabela que contem as setas
		escreve_palavra 8, 25, 68, chama, l15, branco_intenso          ;;idem
		escreve_palavra 8, 26, 54, interna, l16, branco_intenso        ;;escreve 'internas' na coluna das setas que sinalizam as chamadas internas
		escreve_palavra 8, 26, 68, externa, l17, branco_intenso        ;;escreve 'externas' na coluna das setas que sinalizam as chamadas externas
		;;desenha a tabela das setas
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
;----------------------------------------------------------------------------------------------------------------------------------------------------------------




;------------------------------------------------------------------
  		

;--------------------------------------------FUNCOES DO ARQUIVO LINEC.ASM-------------------------------------------------------------
;   funcao cursor
;
; dh = linha (0-29) e  dl=coluna  (0-79)
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

;
;funcaoo caracter escrito na posicao do cursor
;
; al= caracter a ser escrito
; cor definida na variavel cor
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
;_____________________________________________________________________________
;
;   fun��o plot_xy
;
; push x; push y; call plot_xy;  (x<639, y<479)
; cor definida na variavel cor
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
;_____________________________________________________________________________
;    fun��o circle
;	 push xc; push yc; push r; call circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor
circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r

	mov 	dx,bx
	add		dx,cx       ;ponto extremo superior
	push    ax
	push	dx
	call plot_xy

	mov		dx,bx
	sub		dx,cx       ;ponto extremo inferior
	push    ax
	push	dx
	call plot_xy

	mov 	dx,ax
	add		dx,cx       ;ponto extremo direita
	push    dx
	push	bx
	call plot_xy

	mov		dx,ax
	sub		dx,cx       ;ponto extremo esquerda
	push    dx
	push	bx
	call plot_xy

	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y

;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante
;valores positivos para d

stay:				;loop
	mov		si,di
	cmp		si,0
	jg		inf       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov		si,dx		;o jl � importante porque trata-se de conta com sinal
	sal		si,1		;multiplica por doi (shift arithmetic left)
	add		si,3
	add		di,si     ;nesse ponto d=d+2*dx+3
	inc		dx		;incrementa dx
	jmp		plotar
inf:
	mov		si,dx
	sub		si,cx  		;faz x - y (dx-cx), e salva em di
	sal		si,1
	add		si,5
	add		di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc		dx		;incrementa x (dx)
	dec		cx		;decrementa y (cx)

plotar:
	mov		si,dx
	add		si,ax
	push    si			;coloca a abcisa x+xc na pilha
	mov		si,cx
	add		si,bx
	push    si			;coloca a ordenada y+yc na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,dx
	push    si			;coloca a abcisa xc+x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do s�timo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc+x na pilha
	call plot_xy		;toma conta do segundo octante
	mov		si,ax
	add		si,cx
	push    si			;coloca a abcisa xc+y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do oitavo octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	add		si,cx
	push    si			;coloca a ordenada yc+y na pilha
	call plot_xy		;toma conta do terceiro octante
	mov		si,ax
	sub		si,dx
	push    si			;coloca a abcisa xc-x na pilha
	mov		si,bx
	sub		si,cx
	push    si			;coloca a ordenada yc-y na pilha
	call plot_xy		;toma conta do sexto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	sub		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quinto octante
	mov		si,ax
	sub		si,cx
	push    si			;coloca a abcisa xc-y na pilha
	mov		si,bx
	add		si,dx
	push    si			;coloca a ordenada yc-x na pilha
	call plot_xy		;toma conta do quarto octante

	cmp		cx,dx
	jb		fim_circle  ;se cx (y) est� abaixo de dx (x), termina
	jmp		stay		;se cx (y) est� acima de dx (x), continua no loop


fim_circle:
	pop		di
	pop		si
	pop		dx
	pop		cx
	pop		bx
	pop		ax
	popf
	pop		bp
	ret		6
;-----------------------------------------------------------------------------
;    funcaoo full_circle
;	 push xc; push yc; push r; call full_circle;  (xc+r<639,yc+r<479)e(xc-r>0,yc-r>0)
; cor definida na variavel cor
full_circle:
	push 	bp
	mov	 	bp,sp
	pushf                        ;coloca os flags na pilha
	push 	ax
	push 	bx
	push	cx
	push	dx
	push	si
	push	di

	mov		ax,[bp+8]    ; resgata xc
	mov		bx,[bp+6]    ; resgata yc
	mov		cx,[bp+4]    ; resgata r

	mov		si,bx
	sub		si,cx
	push    ax			;coloca xc na pilha
	push	si			;coloca yc-r na pilha
	mov		si,bx
	add		si,cx
	push	ax		;coloca xc na pilha
	push	si		;coloca yc+r na pilha
	call line


	mov		di,cx
	sub		di,1	 ;di=r-1
	mov		dx,0  	;dx ser� a vari�vel x. cx � a variavel y

; ;aqui em cima a l�gica foi invertida, 1-r => r-1
;e as compara��es passaram a ser jl => jg, assim garante
;valores positivos para d

stay_full:				;loop
	mov			si,di
	cmp			si,0
	jg			inf_full       ;caso d for menor que 0, seleciona pixel superior (n�o  salta)
	mov			si,dx		;o jl � importante porque trata-se de conta com sinal
	sal			si,1		;multiplica por doi (shift arithmetic left)
	add			si,3
	add			di,si     ;nesse ponto d=d+2*dx+3
	inc			dx		;incrementa dx
	jmp			plotar_full
inf_full:
	mov			si,dx
	sub			si,cx  		;faz x - y (dx-cx), e salva em di
	sal			si,1
	add			si,5
	add			di,si		;nesse ponto d=d+2*(dx-cx)+5
	inc			dx		;incrementa x (dx)
	dec			cx		;decrementa y (cx)

plotar_full:
	mov			si,ax
	add			si,cx
	push		si		;coloca a abcisa y+xc na pilha
	mov			si,bx
	sub			si,dx
	push    	si		;coloca a ordenada yc-x na pilha
	mov			si,ax
	add			si,cx
	push		si		;coloca a abcisa y+xc na pilha
	mov			si,bx
	add			si,dx
	push    	si		;coloca a ordenada yc+x na pilha
	call 		line

	mov			si,ax
	add			si,dx
	push		si		;coloca a abcisa xc+x na pilha
	mov			si,bx
	sub			si,cx
	push    	si		;coloca a ordenada yc-y na pilha
	mov			si,ax
	add			si,dx
	push		si		;coloca a abcisa xc+x na pilha
	mov			si,bx
	add			si,cx
	push    	si		;coloca a ordenada yc+y na pilha
	call		line

	mov			si,ax
	sub			si,dx
	push		si		;coloca a abcisa xc-x na pilha
	mov			si,bx
	sub			si,cx
	push    	si		;coloca a ordenada yc-y na pilha
	mov			si,ax
	sub			si,dx
	push		si		;coloca a abcisa xc-x na pilha
	mov			si,bx
	add			si,cx
	push    	si		;coloca a ordenada yc+y na pilha
	call		line

	mov			si,ax
	sub			si,cx
	push		si		;coloca a abcisa xc-y na pilha
	mov			si,bx
	sub			si,dx
	push    	si		;coloca a ordenada yc-x na pilha
	mov			si,ax
	sub			si,cx
	push		si		;coloca a abcisa xc-y na pilha
	mov			si,bx
	add			si,dx
	push    	si		;coloca a ordenada yc+x na pilha
	call		line

	cmp			cx,dx
	jb			fim_full_circle  ;se cx (y) est� abaixo de dx (x), termina
	jmp			stay_full		;se cx (y) est� acima de dx (x), continua no loop


 fim_full_circle:
	pop			di
	pop			si
	pop			dx
	pop			cx
	pop			bx
	pop			ax
	popf
	pop			bp
	ret			6
;-----------------------------------------------------------------------------
;
;   funcaoo line
;
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
							; comparar m�dulos de deltax e deltay sabendo que cx>ax
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
		jb		line5
;;;
	; cx > ax e deltax>deltay
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
		sub		si,ax	;(x-x1)
		mov		ax,[deltay]
		imul	si
		mov		si,[deltax]		;arredondar
		shr		si,1
;se numerador (DX)>0 soma se <0 subtrai
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
		sub		si,bx	;(y-y1)
		mov		ax,[deltax]
		imul	si
		mov		si,[deltay]		;arredondar
		shr		si,1
;se numerador (DX)>0 soma se <0 subtrai
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
; Define os novos
        mov     ax,data ; segment data
        mov     ds,ax
        in      al, kb_data ; Lê do teclado
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
; Restaura os valores anteriores
        pop     ds
        pop     bx
        pop     ax
        iret

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



status           db     0 ; 0: parado; 1: descendo; 2: subindo; 
emodo            db     0 ;0=funcionando 1=emergencia
botoes_externos  db     00h ; 0001: B1 | 0010: B2 | 0100: B3 | 0100: B4 | 0001 0000: B5 | 0010 0000: B6
botoes_internos  db     00h ; 0001: I1 | 0010: I2 | 0100: I3 | 0100: I4
contador         dw     0
init             db     0 ;;byte para determinar se ja saiu da tela de inicio 0 = nao, 1 = sim

;;botoes internos 
ibotao1          db     0 ;;0:desativada, 1:ativada
ibotao2          db     0
ibotao3          db     0
ibotao4          db     0



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
desce       db          'Descendo'
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
