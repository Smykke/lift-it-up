segment code
..start:
    mov ax,data
    mov ds,ax
    mov ax,stack
    mov ss,ax
    mov sp,stacktop

; Obs: [int9*4] = IP  ; [int9*4+2] = CS
; https://en.wikibooks.org/wiki/X86_Assembly/Advanced_Interrupts#The_Interrupt_Vector_Table

        XOR     AX, AX  ; zera o AX
        MOV     ES, AX  ; Faz o ES [Extra Segment Register] apontar para 0h, que é o espaço reservado para vetores de interrupção
; Salvando o segmento antigo
        MOV     AX, [ES:int9*4] ; AX recebe o endereço antigo da próxima instrução [IP - Instruction Pointer] (que INT 9h estava apontando)
        MOV     [offset_dos], AX  ; Esse endereço é guardado em offset_dos
        MOV     AX, [ES:int9*4+2] ; AX recebe o endereço antigo de CS (que estava sendo apontado por INT 9h)
        MOV     [cs_dos], AX  ; Esse endereço é guardado em cs_dos
        CLI     ; Clear Interruption Flag - faz o processador ignorar as interrupções mascaradas
; Substituindo a tabela da BIOS pela nossa tabela
        MOV     [ES:int9*4+2], CS ; Guarda o CS como nova próxima instrução depois da interrupção
        MOV     WORD [ES:int9*4],keyint ; Salva a nova sequência de tratamento de interrupção
        STI     ; Set Interruption Flag - ativa as interrupções

L1:
        mov     ax,[p_i]  ; pont p/ int quando pressiona a tecla
        CMP     ax,[p_t]  ; verifica se soltou a tecla
        JE      L1  ; se soltou, permanece no loop
        inc     word[p_t] ; se a tecla estiver pressionada, incrementa
        and     word[p_t],7 ; pega os três últimos bits de [p_t]
        mov     bx,[p_t]
        XOR     AX, AX  ; zera AX
        MOV     AL, [bx+tecla]  ;
        mov     [tecla_u],al ; Recebe o código da tecla (depois de solta)

        CMP     BYTE [tecla_u], 81h ; 81h é o código gerado ao soltar a tecla ESC
        JE      emergencia_on  ; Liga a emergencia
        CMP     BYTE [tecla_u], 0A2H ; Codigo da letra G
        JE      emergencia_off ; Desliga a emergencia
        CMP     BYTE [tecla_u], 0B9h ; Codigo da barra de espaco
        JE      interrompe_elevador ; Para calibracao
        CMP     BYTE [tecla_u], 82h; Codigo do 1
        JE      binter_1  ; Botao interno 1
        CMP     BYTE [tecla_u], 83h; Codigo do 2
        JE      binter_2  ; Botao interno 2
        CMP     BYTE [tecla_u], 84h; Codigo do 3
        JE      binter_3  ; Botao interno 3
        CMP     BYTE [tecla_u], 85h; Codigo do 4
        JE      binter_4  ; Botao interno 4
        CMP     BYTE [tecla_u], 90h;  Codigo da letra Q
        JE      sair
        JMP     L1

emergencia_on:
        MOV  DX, int_esc
        call imprime
        JMP L1

emergencia_off:
        MOV DX, int_g
        call imprime
        JMP L1

interrompe_elevador:
        MOV DX, int_barra
        call imprime
        JMP L1
binter_1:
        MOV DX, int_binter1
        call imprime
        JMP L1
binter_2:
        MOV DX, int_binter2
        call imprime
        JMP L1
binter_3:
        MOV DX, int_binter3
        call imprime
        JMP L1
binter_4:
        MOV DX, int_binter4
        call imprime
        JMP L1

imprime:
        MOV     AH, 9 ; coloca a função de imprimir DX no INT 21h
        int     21h ; imprime o conteúdo de DX (teclasc)
        RET

sair: ; Restaura a tabela de interrupção da BIOS
        MOV     DX, int_o
        call imprime
        CLI
        XOR     AX, AX
        MOV     ES, AX
        MOV     AX, [cs_dos]
        MOV     [ES:int9*4+2], AX
        MOV     AX, [offset_dos]
        MOV     [ES:int9*4], AX
        MOV     AH, 4Ch ; Retorna o controle para o sistema (finaliza o programa)
        int     21h


keyint:
; Guarda os valores antigos
        PUSH    AX
        push    bx
        push    ds
; Define os novos
        mov     ax,data ; segment data
        mov     ds,ax
        IN      AL, kb_data ; Lê do teclado
        inc     WORD [p_i]  ; incrementa quando pressiona a tecla
        and     WORD [p_i],7
        mov     bx,[p_i] ; Coloca os três primeiros bits de [p_i] em BX
        mov     [bx+tecla],al ; Guarda o código da tecla pressionada
        IN      AL, kb_ctl
        OR      AL, 80h ; Pega os 4 últimos bits de AL
        OUT     kb_ctl, AL
        AND     AL, 7Fh ; Pega os 7 primeiros bits de AL
        OUT     kb_ctl, AL
        MOV     AL, eoi
        OUT     pictrl, AL
; Restaura os valores anteriores
        pop     ds
        pop     bx
        POP     AX
        IRET

segment data
        kb_data EQU 60h  ;PORTA DE LEITURA DE TECLADO - pega o código da tecla
        kb_ctl  EQU 61h  ;PORTA DE RESET PARA PEDIR NOVA INTERRUPCAO
        pictrl  EQU 20h  ; finaliza operação do sistema
        eoi     EQU 20h   ; finaliza operação do sistema
        int9    EQU 9h  ; 09h é interrupção de teclado
        cs_dos  DW  1
        offset_dos  DW 1
        tecla_u db 0
        tecla   resb  8
        p_i     dw  0   ;ponteiro p/ interrupcao (qnd pressiona tecla)
        p_t     dw  0   ;ponterio p/ interrupcao ( qnd solta tecla)
        teclasc DB  0,0,13,10,'$'
        int_o   DB  'O: saindo do programa', 13, 10, '$'
        int_esc    DB  'ESC: emergencia ligado', 13, 10, '$'
        int_g    DB  'G: emergencia desativado', 13, 10, '$'
        int_barra  DB  'BARRA DE ESPACO: calibracao', 13, 10, '$'
        int_binter1  DB  'Botao interno 1', 13, 10, '$'
        int_binter2  DB  'Botao interno 2', 13, 10, '$'
        int_binter3  DB  'Botao interno 3', 13, 10, '$'
        int_binter4  DB  'Botao interno 4', 13, 10, '$'

segment stack stack
    resb 256
stacktop:
