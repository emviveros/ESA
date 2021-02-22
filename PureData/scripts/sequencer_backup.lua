--[[--------------------------- CABEÇALHO --------------------------------------
    Lua script do [esa_sequencer]

        Este sequencer analiza e armazena os dados válidos que chegam
        em tabelas para servir na automação de parâmetros e instrumentos
        presentes no patch.

        O objeto [ofelia d $0-seq] se encontra em:
        E2-A2 -> [pd message_manager]

                                                    Esteban Viveros 2021
                                        https://github.com/emviveros/ESA

-------------------------------------------------------------------------------]]

--[[Variáveis globais]]
local SamplerStatus = 0   --[[0 -> off, 1 -> on]]
local SynthStatus = 0     --[[0 -> off, 1 -> on]]
local Dimensao = ofValue("padSeq_dim")    --[[ recupera valor da dimensão da tabela PadSeq ]]
local PadSeq_dim = Dimensao:get() --[[ calculada a partir do valor da resolução do sequenciador ]]
                                  --[[ em E2-A2 [pd sequencer_timestamp]->[pd init_Seq_dim] ]]
local Pads_estado = ofArray("pads_ativos")  --[[ recupera pd array com estado de ativação dos pads ]]
                                            --[[ em: E3-D1->[controles_looper] ]]
--[[ tabela com o estado de ativação dos pads ]]
local Estado_do_pad = {-1}
local Quantidade_de_pads = #Estado_do_pad    --[[ quantidade de pads do instrumento ]]

--[[ processadores DSP controlados via sequenciador ]]
--[[ Em caso de alteração, verificar PadSeq[i][j] em inicializar_PadSeq() ]]
local Processadores = {'sampler', 'synth', 'fx'}
local logs = 1  --[[ referente ao controle de mensagens de retorno na console do Pd ]]


--[[---------------------------------------------------------------------------
Estrutura de dados do sequencer

    PadSeq[idx][pad_idx][processador][mensagens][atoms_da_mensagem]

    onde:
        [idx] -> index na tabela base. (1 até PadSeq_dim)

        [pad_idx] -> index do pad (1 até Quantidade_de_pads)

        [processador] -> qualquer nome na tabela Processadores (sampler/synth/fx)

        [mensagens] -> tabela com todas as mensagens recebidas para o mesmo processador
                       no mesmo instante de "tempo do sequenciador" (idx)

        [atoms_da_mensagem] -> pode ter mais de um elemento, onde cada elemento é uma
                               tabela contendo um pd atom referente a formação da
                               mensagem para o processador. As mensagens são formatadas
                               conforme especificação do processador endereçado

    Ex.: em [atoms_da_mensagem]
    sendo: { {'notein'}, {60}, {127} }, temos:
        PadSeq[250][0][sampler][1][1] = 'notein'
        PadSeq[250][0][sampler][1][2] = 60
        PadSeq[250][0][sampler][1][3] = 127
    [idx] = 250
    [pad_idx] = 0
    [processador] = 'sampler'
    [mensagens] = { {{'notein'}, {60}, {127}}, {{'notein'}, {60}, {0}} }
    [atoms_da_mensagem] podendo ser:
                            {{'notein'}, {60}, {127}} ou
                            {{'notein'}, {60}, {0}}

-------------------------------------------------------------------------------]]

--[[ Declaração da Tabela base do sequencer (Global) ]]
local PadSeq={}


--[[ Calcula tamanho das tabelas de referência ]]
--[[ https://pt.stackoverflow.com/questions/33301/tamanho-do-array ]]
function table.map_length(t)
    local c = 0
    for k,v in pairs(t) do
         c = c+1
    end
    return c
end


--[[ debug_inicializar_PadSeq() ]]
local function debug_entrada_inicializar_PadSeq(pads)
    print('-----------------------------------------------')
    print('--------- debug_inicializar_PadSeq() ----------')
    print('------------------- ENTRADA -------------------')
    print('pads = ', pads)
    print('PadSeq_dim = ', PadSeq_dim)
    print('#PadSeq = ', #PadSeq)
    print('------------------- - FIM - -------------------')
    print('')
end
local function debug_saida_inicializar_PadSeq(pads)
    print('-----------------------------------------------')
    print('--------- debug_inicializar_PadSeq() ----------')
    print('-------------------- SAÍDA --------------------')
    print('pads = ', pads)
    print('PadSeq_dim = ', PadSeq_dim)
    print('#PadSeq = ', #PadSeq)
    print('#seq = ', #PadSeq[1])
    print('#pad_n = ', table.map_length(PadSeq[1][16]))
    print('#mensagens_em_sampler (pad_n=1) = ', table.map_length(PadSeq[1][1]['sampler']))
    print('#tamanho da mensagem em sampler = ', table.map_length(PadSeq[1][1]['sampler'][1]))
    print('mensagem em sampler (-1 significa vazio) -> ', PadSeq[1][1]['sampler'][1][1])
    print('------------------- - FIM - -------------------')
    print('')
end

--[[ Inicializar tabela PadSeq ]]
local function inicializar_PadSeq(pads)
    --debug_entrada_inicializar_PadSeq(pads)
    for i=1, PadSeq_dim do
        PadSeq[i] = {}
        for j=1, pads do
            PadSeq[i][j] = {sampler={{-1}}, synth={{-1}}, fx={{-1}}}
        end
    end
    --debug_saida_inicializar_PadSeq(pads)
end


--[[ Atualizar estado de atividade dos pads ]]
local function atualizar_estado_de_atividade_dos_pads()
    for i=1, Pads_estado:getSize() do Estado_do_pad[i] = Pads_estado:getAt(i-1) end
    Quantidade_de_pads = #Estado_do_pad
end


--[[ debug de adicionar_evento ]]
local function debug_entrada_adicionar_evento(idx, pad_idx, processador, mensagem)
    print('---------------------------------')
    print('--- debug_adicionar_evento() ---')
    print('---------    ENTRADAS    ---------')
    print('idx = ', idx)
    print('#PadSeq[idx] = ', #PadSeq[idx])
    print('pad_idx = ', pad_idx)
    print('#PadSeq[idx][pad_idx] = ', #PadSeq[idx][pad_idx])
    print('processador = ', processador)
    print('#PadSeq[idx][pad_idx][processador] = ', #PadSeq[idx][pad_idx][processador])
    print('#mensagem = ', #mensagem)
    print('mensagem table id = ', mensagem)
    print('mensagem = (', mensagem[1]..', ',mensagem[2]..', ',mensagem[3]..' )')
    print('------------  FIM  ---------------')
    print('')
end
local function debug_saida_tabela_apos_adicionar_evento(idx, pad_idx, processador)
    print('---------------------------------')
    print('--- debug_adicionar_evento() ---')
    print('------------    SAÍDA    ------------')
    print('#PadSeq[idx][pad_idx][',processador,'][1] = ', table.map_length(PadSeq[idx][pad_idx][processador][1]))
    print('PadSeq[idx][pad_idx][',processador,'][1][1] = ', PadSeq[idx][pad_idx][processador][1][1])
    print('PadSeq[idx][pad_idx][',processador,'][1][2] = ', PadSeq[idx][pad_idx][processador][1][2])
    print('PadSeq[idx][pad_idx][',processador,'][1][3] = ', PadSeq[idx][pad_idx][processador][1][3])
    print('PadSeq[idx][pad_idx][synth][1][1] = ', PadSeq[idx][pad_idx]['synth'][1][1])
    print('PadSeq[idx][pad_idx][synth][1][2] = ', PadSeq[idx][pad_idx]['synth'][1][2])
    print('PadSeq[idx][pad_idx][synth][1][3] = ', PadSeq[idx][pad_idx]['synth'][1][3])
    print('PadSeq[idx][pad_idx][fx][1][1] = ', PadSeq[idx][pad_idx]['fx'][1][1])
    print('PadSeq[idx][pad_idx][fx][1][2] = ', PadSeq[idx][pad_idx]['fx'][1][2])
    print('PadSeq[idx][pad_idx][fx][1][3] = ', PadSeq[idx][pad_idx]['fx'][1][3])
    print('------------  FIM  ---------------')
    print('')
end

--[[ Adiciona mensagem na tabela PadSeq[] ]]
local function adicionar_evento(idx, pad_idx, processador, mensagem)
    --debug_entrada_adicionar_evento(idx, pad_idx, processador, mensagem)

    local n = table.map_length(PadSeq[idx][pad_idx][processador])
    if (PadSeq[idx][pad_idx][processador][1][1] == -1) then
        for i=1, table.map_length(mensagem) do
            PadSeq[idx][pad_idx][processador][1][i] = mensagem[i]
        end
    else
        PadSeq[idx][pad_idx][processador][n+1] = {}
        for i=1, table.map_length(mensagem) do
            PadSeq[idx][pad_idx][processador][n+1][i] = mensagem[i]
        end
    end
    --debug_saida_tabela_apos_adicionar_evento(idx, pad_idx, processador)
end


--[[ debug de retorna_mensagens_no_indice ]]
local function debug_retorna_mensagens_no_indice(idx, pad_idx, i, processador, j, n, out_idx, out)
    print('-----------------------------------------------')
    print('--- debug_retorna_mensagens_no_indice() ---')
    print('idx = ', idx)
    print('pad_idx = ', pad_idx)
    print('quantidade de processadores do Sequencer -> i = ', i)
    print('#Processadores =', #Processadores)
    print('processador = ', processador)
    print('mensagens dentro do processador -> n = ', n)
    print('índice da mensagem atual sendo linkada com a saída -> j = ', j)
    print('out_idx = ', out_idx)
    local temp={{}}; temp[1] = PadSeq[idx][pad_idx][processador][j]
    print('PadSeq['..idx..']['..pad_idx..']['..processador..']['..j..'] = ', temp[1])
    print('#out[out_idx] = ', table.map_length(out[out_idx]))
    print('out[out_idx] = ', out[out_idx])
    print('out[out_idx][até 4] = ', out[out_idx][1], out[out_idx][2], out[out_idx][3], out[out_idx][4])
    print('------------------- - FIM - -------------------')
    print('')
end
local function debug_mensagem_de_saida_formatada_em_retorna_mensagens_no_indice(out, out_idx, p, n)
    print('-----------------------------------------------------------------------------')
    print('--- debug_mensagem_formatada_em_retorna_mensagens_no_indice() ---')
    print('---------------------------------- SAÍDAS -----------------------------------')
    print('mensagens a recuperar -> n = ', n)
    print('pad do laço -> p = ', p)
    print('#out = ', table.map_length(out))
    print('#out[out_idx] = ', table.map_length(out[out_idx]))
    print('out[out_idx] = ', out[out_idx])
    print('out[out_idx][até 5] = ', out[out_idx][1], out[out_idx][2], out[out_idx][3], out[out_idx][4], out[out_idx][5])
    print('-------------------------------- - FIM - ------------------------------------')
    print('')
end
local function debug_pads_ativos()
    for i=1, Quantidade_de_pads do
        print('Estado_do_pad[', i-1, '] = ', Estado_do_pad[i])
    end
end

--[[ Retorna mensagens contidas em um pad especifico (se houver mensagens) ]]
local function retorna_mensagens_no_indice(idx)
    local out = {}; out[1] = {-1}     --[[ inicialização da variável de saída de dados ]]
    local out_idx = 1   --[[ contador de mensagens a retornar de PadSeq[idx][pad_idx] ]]

    atualizar_estado_de_atividade_dos_pads()
    --debug_pads_ativos()

    for i=1, table.map_length(Processadores) do --[[ varre todos os processadores ]]
        local processador = Processadores[i]

        --[[ varre pads ativos e segue se pad estiver ativado ]]
        for p=1, Quantidade_de_pads do
            if (Estado_do_pad[p] == 1) then
                --[[ segue se processador tiver mensagens ]]
                if (PadSeq[idx][p][processador][1][1] ~= -1 or nil) then
                    --[[ quantas mensagens no processador ]]
                    local n = table.map_length(PadSeq[idx][p][processador])

                    --[[ varre mensagens em PadSeq[idx][pad_idx][processador] ]]
                    for j=1, n do
                        out[out_idx] = {}
                        out[out_idx] = {processador}   --[[ adiciona nome do processador a mensagem de saída ]]
                        --[[ varre conteúdo de cada mensagem em PadSeq[idx][pad_idx][processador] ]]
                        for k=1, table.map_length(PadSeq[idx][p][processador][j]) do
                            --[[ adiciona mensagem à mensagem da saída ]]
                            out[out_idx][k+1] = PadSeq[idx][p][processador][j][k]
                        end
                        --debug_mensagem_de_saida_formatada_em_retorna_mensagens_no_indice(out, out_idx, p, n)
                        out_idx = out_idx + 1
                    end
                end
            end
        end
    end
    --print('retorna_mensagens_no_indice() #out = ', table.map_length(out))
    return out
end


--[[ Reinicia mensagens de evento em um índice de PadSeq em um processador determinado ]]
local function resetar_mensagens_do_evento(phase_idx, pad_idx, processador)
    local pad = pad_idx+1

    PadSeq[phase_idx][pad][processador]={-1}
end


--[[ Controla envio de mensagens no Pd console ]]
function M.logs(a)
    if a==0 then
        logs = 0
    else
        logs = 1
    end
end

--[[ Retorna mensagem de erro no console do Pd ]]
local function erro(a)
    local log = ofLog();
    local msg = a

    if logs==1 then log:error(tostring(msg)) end
end

--[[ Retorna mensagem de aviso no console ]]
local function aviso(a)
    local log = ofLog()
    local msg = a

    if logs ==1 then log:post(tostring(msg)) end
end


--[[ Retorna erro em caso de recebimento de mensagens fora da formatação ]]
function M.list(a)
    local out = ''
    for i=1, #a do out = out..a[i]..' ' end
    erro('ESA E2-A2_Sequencer - Recebida mensagem inválida:'..out)
end
function M.float(f)
    erro('ESA E2-A2_Sequencer - Recebida mensagem inválida: '..f)
end
function M.bang()
    erro('ESA E2-A2_Sequencer - Recebida mensagem inválida: bang')
end
function M.symbol(s)
    erro('ESA E2-A2_Sequencer - Recebida mensagem inválida: symbol '..s)
end


--[[ Processa mensagens vindas do Sampler ]]
function M.sampler(a)
    if (a=='on') then
        SamplerStatus = 1
    elseif (a=='off') then
        SamplerStatus = 0
    else
        erro('ESA E2-A2_Sequencer - Mensagem inválida por Sampler: '..a)
    end
end

--[[ processa mensagens vindas do Synth ]]
function M.synth(a)
    if (a=='on') then
        SynthStatus = 1
    elseif (a=='off') then
        SynthStatus = 0
    else
        erro('ESA E2-A2_Sequencer - Mensagem inválida por Synth: '..a)
    end
end


--[[ debug de M.notein() ]]
local function debug_Mnotein(entrada, pad_idx, idx, notein, processador, mensagem)
    print('---------------------------')
    print('--- debug_M.notein() ---')
    print('-- ENTRADA:',#entrada..' elementos -> ',entrada[1]..', ',entrada[2]..', ',entrada[3]..', ',entrada[4]..', ')
    print('idx = ', idx)
    print('pad_idx = ', pad_idx)
    print('notein = (', notein.pitch,', '..notein.velocity..' )')
    print('processador = ', processador)
    print('mensagem = (', mensagem[1]..', ',mensagem[2]..', ',mensagem[3]..' )')
    print('-----------  FIM  -----------')
    print('')
end

--[[ armazena entrada de notas MIDI no instrumento ativado]]
function M.notein(entrada)
    local idx = entrada[1]+1
    local pad_idx = entrada[2]+1
    local notein = {pitch=entrada[3], velocity=entrada[4]}
    local processador = {}
    local mensagem = {}
    --debug_Mnotein(entrada, pad_idx, idx, notein, 'pré_processador', {'pré', -1, -1})

    if (SamplerStatus==1) then
        processador = 'sampler'
        mensagem = {'midiNote', notein.pitch, notein.velocity}
        --debug_Mnotein(entrada, pad_idx, idx, notein, processador, mensagem)

        adicionar_evento(idx, pad_idx, processador, mensagem)

    elseif (SynthStatus==1) then
        processador = 'synth'
        mensagem = {'midiNote', notein.pitch, notein.velocity}
        --debug_Mnotein(entrada, pad_idx, idx, notein, processador, mensagem)

        adicionar_evento(idx, pad_idx, processador, mensagem)

    else
        erro('[esa_sequencer](E2-A2) - nenhum instrumento selecionado')
        local saida = ''
        for i=1, #entrada do saida = saida..' '..tostring(entrada[i])..' ' end
        aviso('mensagem MIDI recebida: notein '..saida)
    end
end


--[[ retorna dados de entrada de valores de sliders ou knobs MIDI ]]
function M.ctlin(l)
    return l
end


--[[ Inicialização do Sequencer ]]
local function init_sequencer()
    atualizar_estado_de_atividade_dos_pads()
    inicializar_PadSeq(Quantidade_de_pads)
    print('[esa_sequencer](E2-A2) - Sequenciador Inicializado')
end


--[[ Reseta o sequencer - apaga todos os valores armazenados ]]
function M.reset()
    atualizar_estado_de_atividade_dos_pads()
    inicializar_PadSeq(Quantidade_de_pads)
    erro('[esa_sequencer](E2-A2) - Sequenciador Resetado')
end


--[[ Modifica a quantidade de pads do Sequencer -- deprecada]]
function M.numero_de_pads(pads)
    Quantidade_de_pads = pads
end


--[[ debug de M.play() ]]
local function debug_Mplay(entrada, idx, out)
    print('---------------------------')
    print('-------- debug_M.play() --------')
    print('-- ENTRADA:',entrada)
    print('idx = ', idx)
    print('out = ', out)
    local dim = table.map_length(out)
    print('quantidade de elementos em out = ', dim)
    for i=1, dim do
        print('out[',i,'][até 5] = ', out[i][1], out[i][2], out[i][3], out[i][4], out[i][5])
    end
    print('----------- - FIM - -----------')
    print('')
end

--[[ Reproduz streaming de dados armazenados em todos os Processadores de um pad específico ]]
function M.play(entrada)
    --[[ relacionado ao controle do fluxo de dados dos outlets do objeto ofelia ]]
    local saida=ofOutlet(this)

    local idx = entrada + 1
    local out = retorna_mensagens_no_indice(idx)

    -- debug_Mplay(entrada, idx, out)

    if (out[1][1] ~= -1) then
        for i=1, table.map_length(out) do
            if (out[i][1]=='sampler') then
                saida:outletList(0, out[i]) --[[ mensagem sai pelo primeiro outlet da esquerda ]]
            elseif (out[i][1]=='synth') then
                saida:outletList(1, out[i]) --[[ mensagem sai pelo segundo outlet]]
            elseif (out[i][1]=='fx') then
                saida:outletList(2, out[i]) --[[ mensagem sai pelo terceiro outlet]]
            else
                erro('[esa_sequencer](E2-A2) - algo deu errado na saída de dados da função M.play()')
            end
        end
    end
end


--[[ PROGRAMA ]]
init_sequencer()