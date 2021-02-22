--[[--------------------------- CABEÇALHO --------------------------------------
    Lua script do [esa_sequencer]

        Código para inicialização do Sequenciador de Eventos ESA.
        Mais detalhes em pad_class.lua

        O objeto [ofelia d $0-seq] se encontra em:
        E2-A2 -> [pd message_manager]

                                                    Esteban Viveros 2021
                                        https://github.com/emviveros/ESA

-------------------------------------------------------------------------------]]

--[[ Carrega módulo com rotinas para debug do código ]]
local debug = require("classe_pad_debug")


--[[----------------------- -  Variáveis globais - ----------------------------]]
local Pad = require("classe_pad")    --[[ módulo da classe Pad ]]
local Pads = {}     --[[ tabela de sequenciadores dos Pads ]]
local Buffer


--[[----------------------------- - FIM - -------------------------------------]]



--[[-------------------- -  Funções Auxiliares - ------------------------------]]
local function inicializar_pad(n)
    local pad_n = Pad.criarPad(n)
    return pad_n
end

--[[ Rotina de recepção de entrada padrão ]]
local function recepcao(entrada)
    local pad_n = entrada[1]
    local mensagem = entrada
    table.remove(mensagem, 1)

    return pad_n, mensagem
end

--[[ Inicialização do buffer do sequencer ]]
local function inicializar_buffer()
    Buffer = Pad.criarPad(1)
    return Buffer
end

--[[ Copia eventos no buffer para o pad especificado ]]
local function consolidar_buffer_no_pad(pad_n)
    local moduloDSP = require("modulo_dsp");
    moduloDSP.consolidar_buffer(pad_n, true);
end


--[[--------------- - FIM - Funções Auxiliares - FIM - ------------------------]]
--[[---------------------------------------------------------------------------]]


--[[-------------------- -  Recepção de Mensagens - ---------------------------]]

--[[ Inicialização de n pads (0-n) + buffer ]]
function M.inicializar(n)
    for i=1, n do
        Pads[i] = inicializar_pad(i-1)
        Pads[i].inicializar()
    end
    inicializar_buffer()
end

--[[ Resetar memória do sequencer do Pad ]]
function M.reset(pad_n)
    Pads[pad_n+1].reset()
end


--[[ Recepção de mensagens tipo list ]]
function M.list(entrada)
    local mensagem = 'list '

    for i=1, #entrada do
        mensagem = mensagem..tostring(entrada[i])..' '
    end

    Pads[1].erro('ESA E2-A2_SequencerPad - Recebida mensagem inválida: '..tostring(mensagem))
end

--[[ Recepção de mensagens tipo bang ]]
function M.bang()
    Pads[1].erro('ESA E2-A2_SequencerPad - Recebida mensagem inválida: bang')
end

--[[ Recepção de mensagens tipo float ]]
function M.float(entrada)
    Pads[1].erro('ESA E2-A2_SequencerPad - Recebida mensagem inválida: '..tostring(entrada))
end

--[[ Recepção de mensagens tipo symbol ]]
function M.symbol(entrada)
    Pads[1].erro('ESA E2-A2_SequencerPad - Recebida mensagem inválida: symbol '..tostring(entrada))
end


--[[ Recepção de mensagens vindas do Sampler ]]
function M.sampler(entrada)
    local pad_n, mensagem = recepcao(entrada)

    -- debug.entrada_processador('sampler', pad_n, mensagem)

    Pads[pad_n+1].sampler(mensagem)
end


--[[ Recepção de mensagens vindas do Synth ]]
function M.synth(entrada)
    local pad_n, mensagem = recepcao(entrada)

    -- debug.entrada_processador('synth', pad_n, mensagem)

    Pads[pad_n+1].synth(mensagem)
end


--[[ Recepção de mensagens MIDI notein ]]
function M.notein(entrada)
    local pad_n = entrada[1]
    local idx = entrada[2]
    local pitch = entrada[3]
    local velocity = entrada[4]
    local mensagem = {idx, pitch, velocity}

    -- debug.notein(entrada, pad_n, idx, {pitch=pitch, velocity=velocity}, 'pre_proc', mensagem)

    Pads[pad_n+1].notein(mensagem)
end


--[[ Recepção de mensagens MIDI ctlin ]]
function M.cltin(entrada)
    local pad_n, mensagem = recepcao(entrada)

    Pads[pad_n+1].ctlin(mensagem)
end


--[[ Reprodução da sequência de eventos em Pad determinado ]]
function M.play(entrada)
    local saida=ofOutlet(this)
    local pad_n = entrada[1]
    local idx = entrada[2] + 1

    local out = Pads[pad_n+1].retorna_eventos_consolidados(idx)

    if (out[1][1] ~= -1) then
        for i=1, #out do
            if (out[i][1]=='sampler') then
                --[[ mensagem sai pelo primeiro outlet da esquerda ]]
                saida:outletList(0, out[i])
            elseif (out[i][1]=='synth') then
                --[[ mensagem sai pelo segundo outlet]]
                saida:outletList(1, out[i])
            elseif (out[i][1]=='fx') then
                --[[ mensagem sai pelo terceiro outlet]]
                saida:outletList(2, out[i])
            else
                Pads[pad_n].erro('[esa_sequencer](E2-A2) Pad '..tostring(pad_n)..':')
                Pads[pad_n].erro('algo deu errado na saída de dados da função play()')
            end
        end
    end
end

--[[--------------- - FIM - Recepção de Mensagens - FIM - ---------------------]]
--[[---------------------------------------------------------------------------]]