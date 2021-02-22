--[[--------------------------------- - CABEÇALHO - -----------------------------------------
    Funções de Debug de classePad em pad_class.lua

                                                                Esteban Viveros 2021
                                                    https://github.com/emviveros/ESA
-------------------------------------------------------------------------------------------]]


--[[ debug.inicializar_PadSeq(PadSeq, PadSeq_dim) ]]
function M.entrada_inicializar_PadSeq(PadSeq, PadSeq_dim)
    print('-----------------------------------------------')
    print('--------- debug_inicializar_PadSeq() ----------')
    print('------------------- ENTRADA -------------------')
    print('PadSeq_dim = ', PadSeq_dim)
    print('#PadSeq = ', #PadSeq)
    print('------------------- - FIM - -------------------')
    print('')
end

--[[ debug.saida_inicializar_PadSeq(PadSeq, PadSeq_dim) ]]
function M.saida_inicializar_PadSeq(PadSeq, PadSeq_dim)
    print('-----------------------------------------------')
    print('--------- debug_inicializar_PadSeq() ----------')
    print('-------------------- SAÍDA --------------------')
    print('PadSeq_dim = ', PadSeq_dim)
    print('#PadSeq = ', #PadSeq)
    print('#eventos_msmo_idx (#PadSeq[1]) = ', #PadSeq[1])
    print('processador (PadSeq[1][1].processador) = ', PadSeq[1][1].processador)
    print('pd atoms em evento (#evento) = ', #PadSeq[1][1].evento)
    local evento = PadSeq[1][1].evento
    for indice in pairs(PadSeq[1][1].evento) do
        print('#PadSeq[1][1].evento['..indice..'] = ', #PadSeq[1][1].evento[indice])
        for n in ipairs(PadSeq[1][1].evento[indice]) do
            print('PadSeq[1][1].evento['..indice..']['..n..'] = ', PadSeq[1][1].evento[indice][n])
        end
    end
    print('------------------- - FIM - -------------------')
    print('')
end


--[[ debug estado do processador ]]
function M.estado_de_ativacao_sampler(sampler)
    print('')
    print('--------------------------------------------------')
    print('----- debug_estado_de_ativacao_sampler() ------')
    print('classePad.SamplerAtivado = ', sampler)
    print('------------------- - FIM - ----------------------')
    print('')
end


--[[ debug entradas da funcção sampler ]]
function M.entrada_processador(processador, pad_n, mensagem)
    print('-----------------------------------------------')
    print('-------- debug_entrada_processador() ----------')
    print('Processador = ', processador)
    print('Pad = ', pad_n)
    print('#mensagem: ', #mensagem)
    for i = 1, #mensagem do
        print('mensagem[', i,'] = ', mensagem[i])
    end
    print('------------------- - FIM - -------------------')
    print('')
end


--[[ debug estado do processador ]]
function M.estado_de_ativacao_synth(synth)
    print('-----------------------------------------------')
    print('----- debug_estado_de_ativacao_synth() ------')
    print('classePad.SynthAtivado = ', synth)
    print('------------------- - FIM - -------------------')
    print('')
end


--[[ debug de adicionar_evento ]]
function M.entrada_adicionar_evento(tabela,idx, pad_idx, processador, mensagem, nome_da_tabela)
    print('---------------------------------')
    print('--- debug_adicionar_evento() ---')
    print('---------    ENTRADAS    ---------')
    print('Pad = pad_', pad_idx)
    print('idx = ', idx)
    print('#'..tostring(nome_da_tabela)..'[idx] = ', #tabela[idx])
    print('pad_idx = ', pad_idx)
    print('processador = ', processador)
    print(tostring(nome_da_tabela)..'[idx][1].processador = ', tabela[idx][1].processador)
    print(tostring(nome_da_tabela)..'[idx][1].evento = ', tabela[idx][1].evento)
    print('#mensagem = ', #mensagem)
    print('mensagem table id = ', mensagem)
    for index, value in ipairs(mensagem) do
        print('mensagem['..index..'] = ', value)
    end
    print('------------  FIM  ---------------')
    print('')
end

function M.saida_tabela_apos_adicionar_evento(tabela, idx, pad_idx, nome_da_tabela)
    print('---------------------------------')
    print('--- debug_adicionar_evento() ---')
    print('------------    SAÍDA    ------------')
    print('Pad = pad_', pad_idx)
    print('#'..tostring(nome_da_tabela)..'[idx] = ', #tabela[idx])
    print(tostring(nome_da_tabela)..'[idx][1].processador = ', #tabela[idx][1].processador)
    print(tostring(nome_da_tabela)..'[idx][1].evento = ', #tabela[idx][1].evento)
    for i in ipairs(tabela[idx]) do
        print(tostring(nome_da_tabela)..'['..idx..']['..i..'].processador = ', tabela[idx][i].processador)
        for n in ipairs(tabela[idx][i].evento) do
            print(tostring(nome_da_tabela)..'['..idx..']['..i..'].evento['..n..'] = ', tabela[idx][i].evento[n])
        end
    end
    print('------------  FIM  ---------------')
    print('')
end


--[[ debug.retorna_mensagens_no_indice ]]
function M.retorna_mensagens_no_indice(PadSeq, idx, pad_idx, i, processador, j, n, out_idx, out)
    print('-----------------------------------------------')
    print('--- debug_retorna_mensagens_no_indice() ---')
    print('idx = ', idx)
    print('pad_idx = ', pad_idx)
    print('quantidade de processadores do Sequencer -> i = ', i)
    print('processador = ', processador)
    print('mensagens dentro do processador -> n = ', n)
    print('índice da mensagem atual sendo linkada com a saída -> j = ', j)
    print('out_idx = ', out_idx)
    local temp={{}}; temp[1] = PadSeq[idx][pad_idx][processador][j]
    print('PadSeq['..idx..']['..pad_idx..']['..processador..']['..j..'] = ', temp[1])
    print('#out[out_idx] = ', #out[out_idx])
    print('out[out_idx] = ', out[out_idx])
    print('out[out_idx][até 4] = ', out[out_idx][1], out[out_idx][2], out[out_idx][3], out[out_idx][4])
    print('------------------- - FIM - -------------------')
    print('')
end
--[[ debug.saida_de_retorna_mensagens_no_indice_formatada ]]
function M.saida_de_retorna_mensagens_no_indice_formatada(out, out_idx, pad_n, n)
    print('-----------------------------------------------------------------------------')
    print('--- debug_mensagem_formatada_em_retorna_mensagens_no_indice() ---')
    print('---------------------------------- SAÍDAS -----------------------------------')
    print('mensagens a recuperar -> n = ', n)
    print('pad_n -> p = ', pad_n)
    print('#out = ', #out)
    print('#out[out_idx] = ', #out[out_idx])
    print('out[out_idx] = ', out[out_idx])
    print('out[out_idx][até 5] = ', out[out_idx][1], out[out_idx][2], out[out_idx][3], out[out_idx][4], out[out_idx][5])
    print('-------------------------------- - FIM - ------------------------------------')
    print('')
end

--[[ Debug de debug.notein ]]
function M.notein(entrada, pad_n, idx, notein, processador, mensagem)
    print('---------------------------')
    print('--- debug_M.notein() ---')
    print('-- ENTRADA:',#entrada, ' elementos -> ', entrada[1], ', ',entrada[2], ', ',entrada[3], ', ',entrada[4], ', ')
    print('idx = ', idx)
    print('pad_n = ', pad_n)
    print('notein = (', notein.pitch,', '..notein.velocity..' )')
    print('processador = ', processador)
    for i=1, #mensagem do
        print('mensagem[', i,'] = ', mensagem[i])
    end
    print('-----------  FIM  -----------')
    print('')
end


--[[ Debug de debug.play ]]
function M.play(entrada, idx, out)
    print('---------------------------')
    print('-------- debug_M.play() --------')
    print('-- ENTRADA:',entrada)
    print('idx = ', idx)
    print('out = ', out)
    local dim = #out
    print('quantidade de elementos em out = ', dim)
    for i=1, dim do
        print('out[',i,'][até 5] = ', out[i][1], out[i][2], out[i][3], out[i][4], out[i][5])
    end
    print('----------- - FIM - -----------')
    print('')
end