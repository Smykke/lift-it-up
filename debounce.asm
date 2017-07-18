; Debounce da chave ótica do elevador acrílico antigo
debounce_chave:
  mov cx, 20  ; Verificar quanto corresponde em segundos
  mov dx, 319h
l_debounce_chave:
  in ah, dx ; Lê chave + botões externos
  and ah, 01000000b ; Fica apenas com chave
  in al, dx ; Segunda leitura
  and al, 01000000b
  cmp ah, al
  jne debounce_chave  ; Se diferente, reseta o contador
  loop l_debounce_chave ; Se igual, decrementa o contador

conta_volta:
  cmp ah, 0
  jne debounce_chave  ; Se não for 0, não chegou no buraco e tem que continuar movimentando
  add byte[voltas], 1
  cmp byte[voltas], 5 ; Verifica se deu 5 voltas
  je para
  call debounce_chave

para:
  mov dx, 318h
  out dx, 00100000b ; Desliga o motor e acende o L6
  mov voltas, 0 ; reseta as voltas
