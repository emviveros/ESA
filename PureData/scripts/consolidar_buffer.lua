--[[--------------------------- CABEÇALHO --------------------------------------
    Lua script do [esa_sequencer]

        Código para consolidação do buffer em pad determinado em sequencer.lua
        no objeto [ofelia d $0-seq]

        O objeto [ofelia d $0-seq] se encontra em:
        E2-A2 -> [pd message_manager]

                                                    Esteban Viveros 2021
                                        https://github.com/emviveros/ESA

-------------------------------------------------------------------------------]]


--[[----------------------- -  Variáveis globais - ----------------------------]]
local Consolidar_buffer = false  --[[ controla função dsp ]]
local Buffer_idx = 0    --[[ variável auxiliar para contador em M.perform() ]]
local Bloco_dsp = {}    --[[ sinal DSP de saída do objeto ]]
local Controle = 0  --[[ controla parada automática ]]

--[[----------------------------- - FIM - -------------------------------------]]



--[[-------------------- -  Funções Auxiliares - ------------------------------]]

--[[ Inicializa com zeros o bloco dsp de saída ]]
local function inicializar_Bloco_dsp_vazio()
    for i=1, 64 do
        Bloco_dsp[i] = 0
    end
end


--[[--------------- - FIM - Funções Auxiliares - FIM - ------------------------]]
--[[---------------------------------------------------------------------------]]



--[[-------------------- -  Recepção de Mensagens - ---------------------------]]

--[[ Mensagem que comanda o início e parada da função ]]
function M.consolidar_buffer(entrada)
    inicializar_Bloco_dsp_vazio()
    Buffer_idx = entrada[1]
    if entrada[2] ~= 0 then
        Consolidar_buffer = true
    else
        Consolidar_buffer = false
    end
    print('Consolidar_buffer = ', Consolidar_buffer)
end


--[[--------------- - FIM - Recepção de Mensagens - FIM - ---------------------]]
--[[---------------------------------------------------------------------------]]



--[[---------------------------------------------------------------------------]]
--[[---------------- - Função atrelada à cadeia DSP do Pd - -------------------]]

function M.perform()

    if Consolidar_buffer then

        if Controle < 10 then

            if Buffer_idx>511 then
                Buffer_idx = 0
                print('Se passaram 512 ciclos DSP em modulo_dsp -> Consolidar_buffer')
                Controle = Controle + 1
            end

            Buffer_idx = Buffer_idx + 1
        else
            Controle = 0
            Consolidar_buffer = false
        end

    end

    return Bloco_dsp
end


--[[--------- - FIM - Função atrelada à cadeia DSP do Pd - FIM - --------------]]
--[[------------------------------ - FIM - ------------------------------------]]