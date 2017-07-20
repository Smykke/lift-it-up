segment code
..start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,stacktop

; Obs: [int9*4] = IP  ; [int9*4+2] = CS
; https://en.wikibooks.org/wiki/X86_Assembly/Advanced_Interrupts#The_Interrupt_Vector_Table

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

L1:
        mov     ax,[p_i]  ; pont p/ int quando pressiona a tecla
        cmp     ax,[p_t]  ; verifica se soltou a tecla
        je      L1  ; se soltou, permanece no loop
        inc     word[p_t] ; se a tecla estiver pressionada, incrementa
        and     word[p_t],7 ; pega os três últimos bits de [p_t]
        mov     bx,[p_t]
        xor     ax, ax  ; zera AX
        mov     al, [bx+tecla]  ;
        mov     [tecla_u],al ; Recebe o código da tecla (depois de solta)

        cmp     byte [tecla_u], 0A2H ; Codigo da letra G
        je      emergencia_off ; Desliga a emergencia
        cmp     byte [status], 2
        je      L1  ; Se estiver em estado de emergencia, fica no loop ate voltar ao normal (apertar a tecla G)
        cmp     byte [tecla_u], 81h ; 81h é o código gerado ao soltar a tecla ESC
        je      emergencia_on  ; Liga a emergencia
        cmp     byte [tecla_u], 0B9h ; Codigo da barra de espaco
        je      interrompe_elevador ; Para calibracao
        cmp     byte [tecla_u], 82h; Codigo do 1
        je      binter_1  ; Botao interno 1
        cmp     byte [tecla_u], 83h; Codigo do 2
        je      binter_2  ; Botao interno 2
        cmp     byte [tecla_u], 84h; Codigo do 3
        je      binter_3  ; Botao interno 3
        cmp     byte [tecla_u], 85h; Codigo do 4
        je      binter_4  ; Botao interno 4
        cmp     byte [tecla_u], 90h;  Codigo da letra Q
        je      sair
        jmp     L1

emergencia_on:
        mov byte [status], 0003h
        mov  dx, int_esc
        call imprime
        ; mov dx, [status]  ; conferir o resultado
        ; call imprime_byte
        jmp L1

emergencia_off:
        mov byte [status], 01h ; 'subindo' < alterar depois
        mov dx, int_g
        call imprime
        jmp L1

interrompe_elevador:
        mov byte [status], 00h ; parado
        mov dx, int_barra
        call imprime
        ; mov dx, [status]
        ; call imprime_byte
        jmp L1

binter_1:
        add byte [botoes_internos], 01h
        mov dx, int_binter1
        call imprime
        ; mov dx, [botoes_internos]
        ; call imprime_byte
        jmp L1

binter_2:
        add byte [botoes_internos], 02h
        mov dx, int_binter2
        call imprime
        jmp L1

binter_3:
        add byte [botoes_internos], 03h
        mov dx, int_binter3
        call imprime
        jmp L1

binter_4:
        add byte [botoes_internos], 04h
        mov dx, int_binter4
        call imprime
        jmp L1

imprime:
        mov     ah, 9 ; coloca a função de imprimir DX no INT 21h
        int     21h ; imprime o conteúdo de DX (teclasc)
        ret

imprime_byte:
        add dl, '0' ; Transforma o byte em caractere
        mov ah, 2
        int 21h
        mov dl, 13
        int 21h
        mov dl, 10
        int 21h
        ret

sair: ; Restaura a tabela de interrupção da BIOS
        mov     dx, int_o
        call imprime
        cli
        xor     ax, ax
        mov     es, ax
        mov     ax, [cs_dos]
        mov     [es:int9*4+2], ax
        mov     ax, [offset_dos]
        mov     [es:int9*4], ax
        mov     ah, 4Ch ; Retorna o controle para o sistema (finaliza o programa)
        int     21h


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

segment data
        kb_data equ 60h  ;PORTA DE LEITURA DE TECLADO - pega o código da tecla
        kb_ctl  equ 61h  ;PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
        pictrl  equ 20h  ; finaliza operação do sistema
        eoi     equ 20h   ; finaliza operação do sistema
        int9    equ 9h  ; 09h é interrupção de teclado
        cs_dos  dw  1
        offset_dos  dw 1
        tecla_u db 0
        tecla   resb  8
        p_i     dw  0   ;ponteiro p/ interrupcao (qnd pressiona tecla)
        p_t     dw  0   ;ponterio p/ interrupcao ( qnd solta tecla)
        teclasc db  0,0,13,10,'$'
        status  db  0 ; 0: parado; 1: descendo; 2: subindo; 3: emergencia ativado
        int_o   db  'Q: saindo do programa', 13, 10, '$'
        int_esc          db  'ESC: emergencia ligado', 13, 10, '$'
        int_g            db  'G: emergencia desativado', 13, 10, '$'
        int_barra        db  'BARRA DE ESPACO: calibracao', 13, 10, '$'
        int_binter1      db  'Botao interno 1', 13, 10, '$'
        int_binter2      db  'Botao interno 2', 13, 10, '$'
        int_binter3      db  'Botao interno 3', 13, 10, '$'
        int_binter4      db  'Botao interno 4', 13, 10, '$'
        botoes_externos  db  00h ; 0001: B1 | 0010: B2 | 0100: B3 | 0100: B4 | 0001 0000: B5 | 0010 0000: B6
        botoes_internos  db  00h ; 0001: I1 | 0010: I2 | 0100: I3 | 0100: I4

segment stack stack
    resb 256
stacktop:
