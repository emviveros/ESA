--[[---------------------------------- - CABEÇALHO - ------------------------------------------
    Lua script do [esa_sequencer]

        Testes da classe_pad do sequencer.

        O objeto [ofelia d testes_classe_pad] se encontra em:
        E2-A2 -> [esa_sequencer] -> [pd ofelia-classes]

                                                    Esteban Viveros 2021
                                        https://github.com/emviveros/ESA

---------------------------------------------------------------------------------------------]]



--[[-------------------- -  Funções Auxiliares - ------------------------------]]

--[[ Gera cadeia de caracteres aleatória ]]
--[[ https://www.codegrepper.com/code-examples/lua/random+string+generator+lua ]]
local function RandomVariable(length)
	local res = ""
	for i = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

--[[ Gera string aleatória para processador ]]
local function gera_string()
    return RandomVariable(math.random(8))
end

--[[ Gera lista com itens aleatórios ]]
local function gera_mensagem()
    local out = {}
    local n = math.random(2, 4)

    out[1] = gera_string()
    for i = 2, n do
        out[i] = math.random(128)
    end

    return out
end

--[[ Gera entrada de evento aleatória para testes ]]
local function gera_evento()
    local _processador = gera_string()
    local mensagem = gera_mensagem()

    return {processador = _processador, evento = mensagem}
end

local function cabecalho()
    print('')
    print('---------------------------------------------------------------')
    print('------------------------- - INICIO - ---------------------------')
    print('---------------------------------------------------------------')
end

local function rodape()
    print('')
    print('---------------------------------------------------------------')
    print('--------------------------- - FIM - ----------------------------')
    print('')
end

--[[--------------- - FIM - Funções Auxiliares - FIM - ------------------------]]
--[[---------------------------------------------------------------------------]]



--[[----------------------------- -  TESTES - ---------------------------------]]

--[[ testa se todos os valores contidos na tabela do sequencer são iguais a -1 ]]
function M.inicializacao_de_tabela(nome, tabela, pad_n)
    local n = #tabela
    cabecalho()
    print('TESTE de INICIALIZAÇÃO DA TABELA ')
    print(tostring(nome)..' em PAD', pad_n)
    for i=1, n do
        for j=1, #tabela[i] do
            if tabela[i][j].processador == -1 then
                for k=1, #tabela[i][j].evento do
                    for l=1, #tabela[i][j].evento[k] do
                        if tabela[i][j].evento[k][l] ~= -1 then
                            print('Falha na tabela '..tostring(nome)..' = ', tabela)
                            print(tostring(tabela)..'['..tostring(n)..']['..tostring(j)..'].evento['..tostring(k)']['..tostring(l)..'] = ', tabela[i][j].evento[k][l])
                            return false
                        end
                    end
                end
            else
                print('Teste de inicialização da tabela '..tostring(tabela)..' falhou')
                print(tostring(tabela)..'['..tostring(n)..']['..tostring(j)..'].processador = ', tabela[i][j].processador)
                return false
            end
        end
    end
    print('Sucesso na tabela '..tostring(nome)..' = ', tabela)
    rodape()
end


--[[ testa a armazenamento e recuperação de eventos em uma tabela ]]
function M.adicao_e_retorno_de_eventos(adicionar_evento, retornar_evento, nome, tabela, pad_n)
    local function print_falha(idx)
        print('Falhou na tabela '..tostring(nome)'['..tostring(idx)'] = ', tabela)
    end

    cabecalho()
    print('-- - TESTE de ADIÇÃO E RETORNO DE EVENTOS DA TABELA - --')
    print('')
    print(tostring(nome)..' em PAD', pad_n)
    for idx=1, #tabela do
        local entrada = gera_evento()
        adicionar_evento(tabela, idx, entrada.processador, entrada.evento)

        local out = retornar_evento(tabela, idx)

        for chave in pairs(out) do
            if chave == 'processador' then
                if out.processador ~= entrada.processador then
                    print_falha(idx)
                end
            elseif chave == 'evento' then
                for indice, value in ipairs(out.evento) do
                    if out.evento[indice] ~= entrada.evento[indice] then
                        print_falha(idx)
                    end
                end
            end
        end
    end
    print('Sucesso na tabela '..tostring(nome)..' = ', tabela)
    rodape()
end


--[[ testa se duas tabelas são independentes uma da outra ]]
function M.imparidade_de_tabelas(tabela1, tabela2, pad_n)
    cabecalho()
    print('--------- TESTE de PARIDADE DE TABELAS ----------')
    print('')
    print('PAD ', pad_n)

    if tabela1 == tabela2 then
        print('Erro, as tabelas são a mesma'); rodape()
    else
        print(' Sucesso! As duas tabelas são diferentes '); rodape()
    end
    print('')
end


--[[ teste da função classePad.consolidar_eventos(idx) ]]
function M.consolidacao_de_eventos(adicionar_evento, consolidar_buffer, PadSeq, Buffer)
    local passou = true --[[ se teste bem sucedido ]]

    cabecalho()
    print('-- - - - - - - - Teste de Consolidação de eventos - - - - - - - -- ')
    print('')

    for idx in ipairs(Buffer) do
        local nova_entrada = gera_evento()

        adicionar_evento(Buffer, idx, nova_entrada.processador, nova_entrada.evento)
        consolidar_buffer(idx)

        for n in ipairs(Buffer[idx]) do
            if Buffer[idx][n].processador ~= PadSeq[idx][n].processador then
                print('Teste FALHOU ao verificar consolidação do campo processador no evento '..tostring(n)' em idx = ', idx)
                passou = false
            else
                for i, v in ipairs(Buffer[idx][n].evento) do
                    if PadSeq[idx][n].evento[i] ~= v then
                        passou = false
                        print('Teste FALHOU ao verificar consolidação do campo evento '..tostring(n)..' no índice', i)
                    end
                end
            end
        end
    end

    if passou then
        print('Teste realizado com sucesso'); rodape()
    else
        print('Teste realizado com sucesso'); rodape()
    end
end


--[[---------------------- - FIM - TESTES - FIM - -----------------------------]]
--[[---------------------------------------------------------------------------]]