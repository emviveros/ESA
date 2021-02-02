--[[---------------------------------------------------------------------------
    Lua script com código para acesso a inlets e outlets do objeto [abl_link~]

                                                    Esteban Viveros 2021
                                        https://github.com/emviveros/ESA

-------------------------------------------------------------------------------]]


--[[Variável para controle na saída de dados dos outlets do objeto [ofelia] ]]
local out=ofOutlet(this)

--[[Variáveis globais para recuperação de dados]]
M.step_atual, M.fase_atual, M.tempo_decorrido, M.peers_ativos = 0,0,0,0
M.resolution_value, M.time_value, M.offset_value, M.beat_de_reinicio, M.quantum_da_secao = 0,0,0,0,0
M.is_playing_value, M.abl_link_connected = 0,0

--[[parâmetros padrão]]
function init()
    M.tempo(120); M.play(0); M.peers(0); M.connect(0); M.resolution(1)
    M.play(0); M.connect(0); M.beat(0); M.quantum(4); M.offset(0)
end


--[[Funções para controle e retomada de dados do objeto [abl_link~] ]]
function M.connect(a)
    if (a == nil) then
        print("of_abl_link_metro: argumento inválido para mensagem connect")
    elseif (a == 0) then
        M.abl_link_connected = a
    else
        a = 1
        M.abl_link_connected = a
    end
    out:outletList(1, ofTable('connect', a) )
end

function M.play(a);
    if (a == nil) then
        print("of_abl_link_metro: argumento inválido para mensagem play")
    elseif (a == 0) then
        M.is_playing_value = a
    else
        a = 1
        M.is_playing_value = a
    end
    out:outletList(1, ofTable('play', a) )
end

function M.beat(a)
    if (a == nil) then
        print("of_abl_link_metro: argumento inválido para mensagem beat")
    else
        a = math.abs(a)
        M.beat_de_reinicio = a
        out:outletList(1, ofTable('reset', M.beat_de_reinicio, M.quantum_da_secao) )
    end
end

function M.quantum(a)
    if (a == nil) then
        return M.quantum_da_secao
    else
        a = math.abs(a)
        M.quantum_da_secao = a
        out:outletList(1, ofTable('reset', M.beat_de_reinicio, M.quantum_da_secao) )
    end
end

function M.reset(fv)
    if (fv == nil) or (fv[1] == nil) or (fv[2] == nil) then
        print("of_abl_link_metro: argumento inválido para mensagem reset")
    else
        M.beat_de_reinicio = fv[1]
        M.quantum_da_secao = fv[2]
        out:outletList(1, ofTable('reset', M.beat_de_reinicio, M.quantum_da_secao) )
    end
end

function M.resolution(a)
    if (a == nil) then
        return M.resolution_value
    else
        M.resolution_value = a
        out:outletList(1, ofTable('resolution', a) )
    end
end

function M.tempo(a)
    if (a == nil) then
        print("of_abl_link_metro: argumento inválido para mensagem tempo")
    else
        M.time_value = a
        out:outletList(1, ofTable('tempo', a) )
    end
end

function M.offset(a)
    if (a == nil) then
        print("of_abl_link_metro: argumento inválido para mensagem offset")
    else
        M.offset_value = a
        out:outletList(1, ofTable('offset', a) )
    end
end

function M.step(a)
    if (a == nil) then
        return M.step_atual
    else
        M.step_atual = a
    end
end

function M.phase(a)
    if (a == nil) then
        return M.fase_atual
    else
        M.fase_atual = a
    end
end

function M.beat_time(a)
    if (a == nil) then
        return M.tempo_decorrido
    else
        M.tempo_decorrido = a
    end
end

function M.peers(a)
    if (a == nil) then
        return M.peers_ativos
    else
        M.peers_ativos = a
    end
end

function M.bpm()
    return M.time_value
end

function M.is_playing()
    return M.is_playing_value
end

function M.is_connected()
    return M.abl_link_connected
end


--[[inicialização dos parâmetros padrão]]
init()