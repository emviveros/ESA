--[[--------------------------------- - CABEÇALHO - -----------------------------------------
    Lua script do [esa_sequencer]

        Classe pad do sequencer.
            contém atributos e métodos para sequenciamento de eventos de controle
            dos processadores de DSP: instrumentos Sampler, Synth e dos Efeitos (fx)
            no objeto [ofelia d pad_class]

        O objeto [ofelia d $0-seq] se encontra em:
        E2-A2 -> [pd message_manager]

                                                    Esteban Viveros 2021
                                        https://github.com/emviveros/ESA

-------------------------------------------------------------------------------------------]]

--[[---------------------------- - ESTRUTURA de DADOS - -------------------------------------
    Estrutura de dados do sequencer do Pad

    PadSeq[idx][eventos_msmo_idx][dados_do_evento]

    onde:
        [idx] -> index na tabela base. (1 até PadSeq_dim)

        [eventos_msmo_idx] -> indexa todas as mensagens recebidas em simultâneo, mesmo [idx].

        [dados_do_evento] -> contém a mensagem recebida no formato:

            {processador = '', evento = {}}

        onde processador pode ser: 'sampler', 'synth', 'fx', etc..


    [idx] -> inteiro de 1 a n
    [eventos_msmo_idx] -> inteiro de 1 a n
    [dados_do_evento] -> tabela com as chaves: 'processador' e 'evento'
    PadSeq -> Tabela de eventos do Pad
    PadSeq_dim -> Tamanho da tabela de eventos do Pad (PadSeq), calculada a partir
                  de entrada de resolução do sequencer do Pad.

    obs.: {-1} = vazio

-------------------------------------------------------------------------------------------]]

--[[ Carrega módulo com rotinas para debug do código ]]
local debug = require("classe_pad_debug")

--[[ Carrega módulo com rotinas dos testes do Pad ]]
local testes = require("testes_classe_pad")


--[[ Classe em ofelia ]]
function M.criarPad(pad_n)
    local classePad = {}

    --[[------------------- - Definição de Atributos da classePad - -------------------------]]

        classePad.Pad_n = pad_n --[[ identificador do Pad (0-n) ]]
        classePad.PadSeq = {}   --[[ tabela que armazena eventos no pad ]]
        classePad.PadSeq_dim = 0    --[[ dimensão da tabela PadSeq do sequenciador ]]
        classePad.Buffer_entrada = {}   --[[ tabela temporária para entrada de eventos ]]
        classePad.Estado_do_pad = 0  --[[ estado de ativação do Pad no Looper (0-1) ]]
        classePad.SamplerAtivado = false
        classePad.SynthAtivado = false
        classePad.logs = true --[[exibição de mensagens de retorno na console do Pd]]


    --[[-------------------------------- - FIM - --------------------------------------------]]


    --[[-------------------- - Definição dos Métodos da classePad - -------------------------]]

        --[[ Controla envio de mensagens no Pd console ]]
        function classePad.logs(a)
            if a==0 then
                classePad.logs = false
            else
                classePad.logs = true
            end
        end


        --[[ Retorna mensagem de erro no console do Pd ]]
        function classePad.erro(a)
            local log = ofLog();
            local msg = a

            if classePad.logs then log:error(tostring(msg)) end
        end


        --[[ Retorna mensagem de aviso no console ]]
        function classePad.aviso(a)
            local log = ofLog()
            local msg = a

            if classePad.logs then log:post(tostring(msg)) end
        end


        --[[ seta tamanho da tabela PadSeq ]]
        function classePad.tamanho()
            --[[ recupera valor da dimensão da tabela PadSeq no Pd ]]
            --[[ em E2-A2 [pd sequencer_timestamp]->[pd init_Seq_dim] ]]
            local padSeq_dim_PD = ofValue("padSeq_dim")
            classePad.PadSeq_dim = padSeq_dim_PD:get()
        end


        --[[ Cria tabela de armazenamento de eventos para o sequencer ]]
        function classePad.criar_tabela_de_eventos()
            local estrutura_tabela_de_eventos = {}
            for idx=1, classePad.PadSeq_dim do
                estrutura_tabela_de_eventos[idx] = {{processador=-1, evento={{-1}}}}
            end
            return estrutura_tabela_de_eventos
        end

        --[[ Inicializar tabela PadSeq ]]
        function classePad.inicializar_PadSeq()
            -- debug.entrada_inicializar_PadSeq(classePad.PadSeq, classePad.PadSeq_dim)
            classePad.PadSeq = classePad.criar_tabela_de_eventos()
            -- debug.saida_inicializar_PadSeq(classePad.PadSeq, classePad.PadSeq_dim)
            -- testes.inicializacao_de_tabela('PadSeq', classePad.PadSeq, classePad.Pad_n)
            -- testes.adicao_e_retorno_de_eventos(classePad.adicionar_evento, classePad.retorna_eventos, 'PadSeq', classePad.PadSeq, classePad.Pad_n)
        end


        --[[ Inicializar tabela Buffer de entrada ]]
        function classePad.inicializar_Buffer_entrada()
            -- debug.entrada_inicializar_PadSeq(classePad.Buffer_entrada, classePad.PadSeq_dim)
            classePad.Buffer_entrada = classePad.criar_tabela_de_eventos()
            -- debug.saida_inicializar_PadSeq(classePad.Buffer_entrada, classePad.PadSeq_dim)
            -- testes.inicializacao_de_tabela('Buffer_entrada', classePad.Buffer_entrada, classePad.Pad_n)
            -- testes.adicao_e_retorno_de_eventos(classePad.adicionar_evento, classePad.retorna_eventos, 'Buffer_entrada', classePad.Buffer_entrada, classePad.Pad_n)
        end


        --[[ Atualiza/Retorna estado de atividade do pad ]]
        function classePad.estado_de_atividade_do_pad()
            local pads_estado = ofArray("pads_ativos")
            classePad.Estado_do_pad = pads_estado:getAt(classePad.Pad_n)
            return classePad.Estado_do_pad
        end


        --[[ Adiciona evento em tabela de eventos fornecida ]]
        function classePad.adicionar_evento(tabela, idx, _processador, mensagem)
            --[[debug depende]]
            -- local nome_da_tabela = ''
            -- if tabela == classePad.Buffer_entrada then nome_da_tabela = 'Buffer_entrada' else nome_da_tabela = 'PadSeq' end
            --[[fim debug depende]]

            -- debug.entrada_adicionar_evento(tabela, idx, classePad.Pad_n, _processador, mensagem, nome_da_tabela)


            local n = #tabela[idx]

            if (tabela[idx][1].processador == -1) then
                tabela[idx][1].processador = _processador
                for k, v in pairs(mensagem) do
                    tabela[idx][1].evento[k] = v
                end
            else
                tabela[idx][n+1] = {processador=_processador, evento={{-1}}}
                for k, v in pairs(mensagem) do
                    tabela[idx][n+1].evento[k] = v
                end
            end
            -- debug.saida_tabela_apos_adicionar_evento(tabela, idx, classePad.Pad_n, nome_da_tabela)
        end


        --[[ Adiciona evento em índice determinado de PadSeq ]]
        function classePad.adicionar_evento_em_PadSeq(idx, processador, mensagem)
            classePad.adicionar_evento(classePad.PadSeq, idx, processador, mensagem)
        end


        --[[ Adicionaevento em índice determinado de Buffer_entrada ]]
        function classePad.adicionar_evento_em_Buffer_entrada(idx, processador, mensagem)
            classePad.adicionar_evento(classePad.Buffer_entrada, idx, processador, mensagem)
        end


        --[[ Retorna eventos contidos em uma tabela dada (se houver mensagens) ]]
        function classePad.retorna_eventos(tabela, idx)
            local out = {}; out[1] = {-1}     --[[ inicialização da variável de saída de dados ]]
            local out_idx = 1   --[[ contador de mensagens a retornar de PadSeq[idx][pad_idx] ]]

            classePad.estado_de_atividade_do_pad()  --[[ atualiza status de acionamento do pad ]]

            --[[ segue se houver mensagens válidas de evento no índice idx ]]
            if (tabela[idx][1].processador ~= -1 or nil) then
                --[[ quantas mensagens há no índice idx de PadSeq[idx] ]]
                local n = #tabela[idx]

                --[[ varre mensagens em PadSeq[idx] ]]
                for j=1, n do
                    out[out_idx] = {}

                    --[[ adiciona nome do processador a mensagem de saída ]]
                    out[out_idx][1] = tabela[idx][j].processador

                    --[[ varre conteúdo de cada mensagem em PadSeq[idx].evento ]]
                    for k=1, #tabela[idx][j].evento do
                        --[[ adiciona mensagem à mensagem da saída ]]
                        out[out_idx][k+1] = tabela[idx][j].evento[k]
                    end
                    -- debug.saida_de_retorna_mensagens_no_indice_formatada(out, out_idx, classePad.Pad_n, n)

                    out_idx = out_idx + 1
                end
            end
            -- print('retorna_mensagens_no_indice() #out = ', #out)
            return out
        end


        --[[ Retorna eventos consolidados na tabela principal (PadSeq) ]]
        function classePad.retorna_eventos_consolidados(idx)
            return classePad.retorna_eventos(classePad.PadSeq, idx)
        end


        --[[ Retorna eventos contidos em na tabela temporária (Buffer_entrada) ]]
        function classePad.retorna_eventos_em_Buffer_entrada(idx)
            return classePad.retorna_eventos(classePad.Buffer_entrada, idx)
        end


        --[[ Consolidação de eventos em índice determinado ]]
        function classePad.consolidar_eventos(idx)
            for n in ipairs(classePad.Buffer_entrada[idx]) do
                local processador = classePad.Buffer_entrada[idx][n].processador

                local mensagem = {}
                for i, v in ipairs(classePad.Buffer_entrada[idx][n].evento) do
                    mensagem[i] = v
                end

                classePad.adicionar_evento_em_PadSeq(idx, processador, mensagem)
            end
        end


        --[[ Retorna erro em caso de recebimento de mensagens fora da formatação ]]
        function classePad.lista_pd(a)
            local out = ''
            for i=1, #a do out = out..a[i]..' ' end
            classePad.erro('ESA E2-A2_SequencerPad '..tostring(classePad.Pad_n)..' - Recebida mensagem inválida:'..out)
        end

        function classePad.float(f)
            classePad.erro('ESA E2-A2_SequencerPad '..tostring(classePad.Pad_n)..' - Recebida mensagem inválida: '..f)
        end

        function classePad.bang()
            classePad.erro('ESA E2-A2_SequencerPad '..tostring(classePad.Pad_n)..' - Recebida mensagem inválida: bang')
        end

        function classePad.symbol(s)
            classePad.erro('ESA E2-A2_SequencerPad '..tostring(classePad.Pad_n)..' - Recebida mensagem inválida: symbol '..s)
        end


        --[[ Processa mensagens vindas do Sampler ]]
        function classePad.sampler(entrada)
            if (tostring(entrada[1])=='on') then
                classePad.SamplerAtivado = true
            elseif (tostring(entrada[1])=='off') then
                classePad.SamplerAtivado = false
            else
                classePad.erro('ESA E2-A2_SequencerPad '..tostring(classePad.Pad_n)..' - Mensagem inválida por Sampler: '..entrada)
            end
            -- debug.estado_de_ativacao_sampler(classePad.SamplerAtivado)
        end

        --[[ processa mensagens vindas do Synth ]]
        function classePad.synth(entrada)
            if (tostring(entrada[1])=='on') then
                classePad.SynthAtivado = true
            elseif (tostring(entrada[1])=='off') then
                classePad.SynthAtivado = false
            else
                classePad:erro('ESA E2-A2_SequencerPad '..tostring(classePad.Pad_n)..' - Mensagem inválida por Synth: '..entrada)
            end
            -- debug.estado_de_ativacao_synth(classePad.SynthAtivado)
        end


        --[[ armazena entrada de notas MIDI no instrumento ativado]]
        function classePad.notein(entrada)
            local idx = entrada[1]+1
            local notein = {pitch=entrada[2], velocity=entrada[3]}
            local processador = {}
            local mensagem = {}
            -- debug.notein(entrada, classePad.Pad_n, idx, notein, 'pré-proc', entrada)

            if classePad.SamplerAtivado then
                -- debug.notein(entrada, classePad.Pad_n, idx, notein, 'pré-proc', entrada)
                processador = 'sampler'
                mensagem = {'midiNote', notein.pitch, notein.velocity}
                -- debug.notein(entrada, classePad.Pad_n, idx, notein, processador, mensagem)

                classePad.adicionar_evento_em_Buffer_entrada(idx, processador, mensagem)

            elseif classePad.SynthAtivado then
                processador = 'synth'
                mensagem = {'midiNote', notein.pitch, notein.velocity}
                --debug.notein(entrada, classePad.Pad_n, idx, notein, processador, mensagem)

                classePad.adicionar_evento_em_Buffer_entrada(idx, processador, mensagem)

            else
                -- debug.notein(entrada, classePad.Pad_n, idx, notein, 'pré-proc', entrada)
                classePad.erro('[esa_sequencer](E2-A2) Pad '..tostring(classePad.Pad_n)..': nenhum instrumento selecionado')
                local saida = ''
                for i=1, #entrada do saida = saida..' '..tostring(entrada[i])..' ' end
                classePad.aviso('mensagem MIDI recebida: notein '..tostring(saida))
            end
        end


        --[[ retorna dados de entrada de valores de sliders ou knobs MIDI ]]
        function classePad.ctlin(entrada)
            return entrada
        end


        --[[ Rotinas de inicialização do Sequenciador do Pad ]]
        function classePad.inicializar()
            classePad.tamanho()
            classePad.inicializar_PadSeq()
            classePad.inicializar_Buffer_entrada()
            -- testes.imparidade_de_tabelas(classePad.PadSeq, classePad.Buffer_entrada, classePad.Pad_n)
            -- testes.consolidacao_de_eventos(classePad.adicionar_evento, classePad.consolidar_eventos, classePad.PadSeq, classePad.Buffer_entrada)
            classePad.estado_de_atividade_do_pad()
            if classePad.logs then
                local pad_atual = tostring(classePad.Pad_n)
                print('[esa_sequencer](E2-A2) - Sequenciador do Pad '..pad_atual..' Inicializado')
            end
        end


        --[[ Reseta o sequencer - apaga todos os valores armazenados ]]
        function classePad.reset()
            classePad.tamanho()
            classePad.inicializar_PadSeq()
            classePad.estado_de_atividade_do_pad()
            if classePad.logs then
                local pad_atual = tostring(classePad.Pad_n)
                classePad.erro('[esa_sequencer](E2-A2) - Sequenciador do Pad '..pad_atual..' Resetado')
            end
        end



    --[[----------------- - FIM de Definição dos Métodos da classePad - ---------------------]]

    return classePad
end
--[[--------------------------------- - FIM da Classe Pad - ---------------------------------]]