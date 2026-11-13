# Chuva na BR: brainstorm de design

Data: 2026-11-13. Base: leitura de `scripts/catalog.gd`, `scripts/game.gd`, `scripts/menu.gd`, `scripts/hud.gd`, `scripts/cockpit.gd` (por cima), `README.md` e `qa/reports/round-09.md` (nota 8,6).

Custo: **P** = até ~1 dia de trabalho, **M** = alguns dias, **G** = uma semana ou mais. "Onde" aponta o ponto do código atual em que a ideia entra.

---

## 1. Diagnóstico

### O que já prende

- **Sensação física muito boa.** A suspensão macia (mola, arfagem e rolagem separadas por carro), o buraco que puxa o volante, a aquaplanagem na poça, o tranco na troca de marcha. O Besouro, a Picape e o GT se dirigem de jeitos diferentes de verdade (`catalog.gd`, `CARS`).
- **Uma cabine com alma.** Terço e dados no Besouro, fitas de igreja na Picape, pinheirinho no GT, o cachorrinho de painel que balança, o ventilador, o limpador tirando gota a gota. É disso que o jogador vai lembrar.
- **Três estradas com identidade.** Cafezal, pasto com vaca, capela e porteira no Sítio. Posto, caminhão e guard-rail na BR-116. Pórtico, painel de LED e telefone SOS na Expressa.
- **Hora e clima bonitos.** Céu com 4 momentos por clima, lua, luzes de cidade no horizonte à noite, poeira vermelha no sol.
- **Rádio com humor.** Nomes como "Zé da Balsa - Último Pedágio" e o "SÓ A CHUVA" quando o rádio está desligado.
- **Fricção zero.** Sem game over, piloto automático que não bate, menu com prévia ao vivo e as escolhas lembradas (`viagem.cfg`).
- **Meta curta clara.** O multiplicador x1 a x4 de direção suave dá um motivo para dirigir com capricho sem punir de verdade (uma batida custa um degrau).

### O que falta

- **A estrada é um circuito de 1 a 1,5 minuto.** `_build_track` fecha a pista em loop. A BR-116 tem 3.080 segmentos × 200 = 616.000 unidades: a 70 km/h (6.650 unidades/s) é uma volta a cada **~93 s**. O Sítio dá ~73 s a 50 km/h e a Expressa ~69 s a 100 km/h. A mesma capela, a mesma placa e o mesmo posto voltam toda hora. **Não existe sensação de viagem**, e esse é o maior problema para o "só mais uma viagem".
- **Pouco motivo de longo prazo.** A única coisa salva entre sessões é o recorde por estrada (`his` em `_save_cfg`). Nada se acumula: nem km, nem lembrança, nem item.
- **A pontuação fala a língua errada.** "1P: 000.000" e "HI-SCORE" são de fliperama, não de viagem. O placar ainda trava em 999.999 (`hud.gd`, `fmt` com `mini(999999, …)`). A 70 km/h em x4 isso dá 560 pontos/s, ou seja ~30 minutos. Com o GT a 140 km/h, ~15 minutos. O recorde vira um teto justamente para quem joga por mais tempo.
- **O posto não é uma decisão.** O tanque cheio dura ~250 s a 70 km/h e há dois postos por volta (`_add_stops`, em 30% e 78%), então passa um posto a cada ~45 s. Abastecer é só passar na faixa da direita: o jogo não para, não tem cena e não tem lanche.
- **O rádio se repete.** Cada estação é **um** `.ogg` em loop. As "3 músicas" são o mesmo áudio com o nome trocado quando o arquivo termina (`radio_song`). Não tem locutor, vinheta nem recado.
- **Nada surpreende.** Não existe evento: o mundo é sorteado uma vez em `setup()` e fica igual. O clima não muda de verdade (no sol a chuva nunca vem, na chuva ela só varia de 0,55 a 1,0).
- **Pouca expressão pessoal.** Os penduricalhos vêm fixos de cada carro (`layout.hang`). Não dá para escolher cor nem objeto, e a sua viagem não deixa marca.
- **O ciclo do dia é rápido demais para uma viagem.** No `ciclo`, `tday` avança 1 a cada 110 s, então o dia inteiro dura 7min20s. Uma sessão de 20 min passa por quase três dias.
- **O piloto automático deixa a pessoa sem ter o que fazer.** É ótimo para relaxar, mas fora trocar de estação não há nada para olhar, colecionar ou registrar.

---

## 2. Ideias

### A. Viagens e destinos

**1. Hodômetro de verdade: km da viagem e km da vida do carro (P)**
- **O que é:** o contador principal passa a ser **km rodados** (`v * dt / 3600`), no painel (o `cockpit.gd` já desenha dígitos para o relógio do GT, em `_digit`) e no HUD. Cada carro guarda o seu total: "ESTE BESOURO JÁ RODOU 1.284 KM". Os pontos de direção suave continuam como número secundário ("km suaves"), sem teto.
- **Por que volta:** o número só cresce, nunca se perde, e é **do carro**: dá apego. Também serve de base para os desbloqueios das ideias 7 e 18.
- **Clima relaxante:** km é a unidade de quem viaja, não de quem compete. Não tem ranking, só o "olha quanto a gente já andou".
- **Onde:** `game.gd`, linha do `score += v * dt * 2.0 * mult` (somar `km`). `_save_cfg`/`_load_cfg` ganham uma seção `[hodometro]` por carro. `hud.gd`, `set_values` (trocar "1P/HI-SCORE" por "KM HOJE / KM DO CARRO"). `menu.gd`, `refresh` (mostrar o total do carro escolhido).

**2. A estrada não se repete (M)**
- **O que é:** manter a geometria em loop, mas **revestir** os segmentos que ficaram para trás, fora da vista (a câmera só desenha `DRAW = 150` segmentos à frente). Quando o carro passa do segmento `i`, o segmento `i − 200` é limpo e sorteado de novo: outra zona de cafezal/pasto/mata, outras placas, outros buracos e poças. Depois, sortear também a curva e o morro de cada trecho novo, mantendo a altura das pontas.
- **Por que volta:** "o que vem depois da próxima curva?" é o motor de qualquer jogo de estrada. Sem isso, as ideias de coleção (5, 6, 11) se esgotam em 90 s.
- **Clima relaxante:** é infinito e sem objetivo obrigatório, como uma viagem longa de verdade.
- **Onde:** `game.gd`. Quebrar `_populate_br/_terra/_expressa` e `_build_surface` numa função por segmento (`_dress(i)`), chamada no laço que já percorre segmentos ao andar (bloco "move, and whatever the wheels run over"). Os `postos` deixam de ser fixos em 30%/78% e passam a ser colocados por distância. Cuidado com `_clear_around` e com os segmentos de aviso `sign3`/`placa_gado`, que olham 95 segmentos para trás.

**3. Placas de distância e viagem com chegada (M)**
- **O que é:** placas verdes com "SANTA RITA DO SAPUCAÍ 42" (nomes inventados com cara de verdade, como as rádios), que descem a cada trecho. A viagem tem um destino opcional escolhido no menu ("ATÉ A PRÓXIMA CIDADE: ~25 KM" / "SEM DESTINO"). Ao chegar, a cidade aparece no horizonte, o carro entra no pórtico de boas-vindas e o jogo mostra o cartão-postal (ideia 22). Depois dá para seguir viagem.
- **Por que volta:** dá um fim natural e satisfatório para a sessão ("cheguei"), e a próxima viagem tem outro nome no mapa. Um caderno de cidades visitadas cresce.
- **Clima relaxante:** sem relógio. O destino é só um norte, e "sem destino" continua existindo.
- **Onde:** `catalog.gd` (lista de cidades por estrada), `menu.gd` (nova linha "DESTINO" em `KEYS`), `world.gd` (texto desenhado por cima de uma placa em branco: `_sign_far` já desenha placas sem texto quando estão longe), `game.gd` (km restante, gatilho de chegada).

**4. Cidadezinha com lombada (M; só a lombada é P)**
- **O que é:** de vez em quando a estrada atravessa um trecho urbano curto. Placa "REDUZA 40", **quebra-molas** pintado de amarelo, padaria, igreja matriz, orelhão, gente na calçada. A lombada é um novo `feat` (`t: 3`) que empurra o corpo para cima devagar.
- **Por que volta:** o Besouro passando a lombada a 30 km/h e flutuando nas molas é o tipo de momento que o jogo já faz bem. Também quebra o ritmo da estrada.
- **Clima relaxante:** desacelerar é gostoso, não é punição. O piloto automático reduz sozinho.
- **Onde:** `game.gd`, `_hit_feat` (novo tipo: `zb_v` positivo e suave, `pitch_v`), `_danger` (piloto reduz antes). `world.gd` desenha a faixa amarela. Arte nova em `tools/art/art.js` (o `build_art.js` gera os PNGs).

### B. Coleção e progressão suave

**5. Caderneta de figurinhas da estrada (M)**
- **O que é:** um álbum (no espírito do álbum de figurinhas de Copa) com ~16 figurinhas por estrada. Cada coisa avistada pela primeira vez cola uma figurinha: vaca malhada, porteira, capela, ipê-amarelo, ipê-roxo, trator, ônibus, caminhão, posto, venda, pórtico, telefone SOS, painel de LED. **Raras:** arco-íris (ideia 13), lua cheia, boiada (ideia 11), tucano no poste, ipê florido fora de época, carro de som. Cada figurinha tem uma legenda curta e engraçada ("VACA. NÃO DÁ SETA.").
- **Por que volta:** "faltam 4 da Estrada do Sítio" é o gancho clássico de coleção, e é suave porque **ver** é o único requisito.
- **Clima relaxante:** contemplar a paisagem vira o próprio jogo. Funciona até no piloto automático.
- **Onde:** `game.gd`, `_add_spr` (guardar o `name` do sprite junto da `tex`) e o laço de segmentos ao andar (detectar o que passou com `|off| < ~3`). `_save_cfg` ganha a seção `[caderneta]`. `menu.gd` ganha a tela "CADERNETA" (item novo no menu e na pausa). O aviso de figurinha nova deve aparecer no rodapé (`hud.set_now`) ou como ícone, não no `toast` (ver Riscos).

**6. Frases de para-choque de caminhão (P/M)**
- **O que é:** os caminhões (`car7`) e ônibus ganham frase no para-choque, legível quando você chega perto: "SE A VIDA FOSSE FÁCIL, NÃO COMEÇAVA CHORANDO", "NÃO ME SIGA, TAMBÉM ESTOU PERDIDO", "DEUS É FIEL", "FILHO DE PEIXE, PEIXINHO É". As frases lidas entram numa página da caderneta.
- **Por que volta:** colecionar frases é muito brasileiro e engraçado, e dá motivo para **encostar** atrás do caminhão (com calma) em vez de ultrapassar.
- **Clima relaxante:** recompensa justamente o comportamento lento.
- **Onde:** `game.gd`, `_spawn_cars` (sortear `phrase` para os `car7`/`onibus`). `world.gd`, no desenho do trânsito (texto em 8 px com `Estrada2P` quando a escala passa de um limiar). Lista de frases em `catalog.gd`.

**7. Penduricalhos e santinhos ganhos com km (P por item, M para a tela)**
- **O que é:** marcos de km do carro (ideia 1) liberam itens para o retrovisor e o painel: **santinho de São Cristóvão** (padroeiro dos motoristas) aos 50 km, fita do Senhor do Bonfim, chaveiro de time genérico, terço de madeira, cachorrinho de painel para a Picape e o GT, flor de plástico, CD pendurado contra radar, adesivo "BEBÊ A BORDO". O jogador escolhe até 2 pendurados e 1 de painel.
- **Por que volta:** "faltam 38 km para a fita do Bonfim". Expressão pessoal visível o tempo todo, com a física de balanço que já existe.
- **Clima relaxante:** é progressão sem perda e sem pressa, e o item balança mais em estrada ruim (é graça, não aviso).
- **Onde:** `catalog.gd` (`layout.hang`, `dog` e `fan` passam a ser padrão e o save sobrescreve). `cockpit.gd`, o `match item` do bloco "whatever hangs from the rear-view mirror" (novos casos desenhados com `_cap_line`/`R`, como o terço e as fitas). `menu.gd`, sub-tela "CABINE".

### C. Rádio e música

**8. Locutor, recado de ouvinte e previsão do tempo, em texto (P)**
- **O que é:** entre uma "música" e outra, o rodapé mostra falas da estação. "SERRA FM 98,7: A RÁDIO QUE SOBE A SERRA COM VOCÊ". "ALÔ, DONA CIDA DO KM 43: SEU FILHO CHEGOU BEM E MANDOU UM BEIJO". "PREVISÃO: CHUVA FRACA NA SERRA, CAPRICHE NO LIMPADOR". "HORA CERTA: 18 HORAS". A previsão lê `rain_goal` e `tday` de verdade. Depois dá para pôr vinhetas de áudio curtas.
- **Por que volta:** conteúdo novo e bem-humorado a cada viagem, por um custo baixíssimo (é texto). Dá personalidade às três rádios.
- **Clima relaxante:** é a companhia que o rádio faz em viagem de verdade.
- **Onde:** `game.gd`, `STATIONS` (somar `spots: [...]` por estação) e o bloco do rádio no fim de `_process` (quando `radio_time` vira, alternar música e spot). `hud.set_now` já rola o texto longo.

**9. Rádio que depende do lugar e da hora (P)**
- **O que é:** a **NOITE AM 1040 pega melhor à noite** (o AM viaja mais longe à noite, de verdade) e chia de dia. A FM falha com estática nos trechos de serra/mata e volta no alto do morro. Um toast discreto avisa: "SINAL DA SERRA FM VOLTANDO".
- **Por que volta:** cada estação tem a sua "hora", e trocar de rádio vira um pequeno ritual ligado à hora e ao lugar.
- **Clima relaxante:** a estática é suave e sempre passa. Nunca corta a música de vez.
- **Onde:** `game.gd`. Volume de `a_music` e um `a_hiss`/`static` leve em função de `tday`, `radio_st` e `ROUGH`/`Y` do segmento. `cockpit.gd` já troca o rótulo para estática com `static_t`.

**10. Mais músicas e a fita K7 do Besouro (M, depende de áudio)**
- **O que é:** 3 a 4 faixas reais por estação, cada uma com o seu nome. O Besouro tem rolos de fita no painel (`layout.reels`): ele ganha um **toca-fitas**. Cada música ouvida até o fim pode ser "gravada" na sua fita, e a fita vira uma quarta "estação" montada pelo jogador. Na Picape é o rádio AM simples; no GT, um CD-player com equalizador (`layout.eq` já existe).
- **Por que volta:** colecionar música ("9/12 ouvidas") e montar a própria fita é expressão pessoal pura.
- **Clima relaxante:** música é o centro de um jogo relaxante.
- **Onde:** `assets/audio`, `_init_audio` (lista de streams por estação em vez de uma só), `_tune`/`next_station`. `cockpit.gd`, desenho dos rolos girando (`reels`).

### D. Mundo vivo e eventos de beira de estrada

**11. Eventos raros de beira de estrada (M para o sistema, P a M por evento)**
- **O que é:** um sorteador de eventos (1 a cada ~3 minutos, nunca dois seguidos), cada um preso a estrada, clima ou hora:
  - **Sítio:** boiada atravessando com o peão a cavalo (o trânsito anda a 8 km/h por 20 s), cavalo solto no acostamento, carro de boi, vendedor de pamonha e milho verde, romeiros a pé.
  - **BR-116:** comboio de caminhões-cegonha, carro de som anunciando quermesse ("É HOJE, NA PRAÇA DA MATRIZ!"), borracharia 24 h com placa pintada à mão, vira-lata caramelo sentado no acostamento.
  - **Expressa:** painel de LED com mensagem engraçada ("BEBEU? CHAME UM AMIGO PARA DIRIGIR, COMO VOCÊ"), helicóptero de reportagem, revoada de maritacas no fim de tarde.
  - **Noite:** vaga-lumes no Sítio, festa junina com fogueira e bandeirinhas (em junho, ver ideia 14), céu estrelado depois que a chuva para.
- **Por que volta:** surpresa. "Uma vez eu vi a boiada" é história para contar, e cada evento visto entra na caderneta.
- **Clima relaxante:** nada bloqueia nem exige reflexo. O que atravessa a pista é lento, avisado por placa e resolvido pelo cruise/piloto que já seguem o carro da frente.
- **Onde:** `game.gd`, um `_events(dt)` novo no `_process`. A boiada pode entrar como "carros" lentos com `dir > 0` na lista `cars`, e a lógica de seguir/ultrapassar já trata. Os sprites estáticos entram com `_add_spr` à frente (`cur_i + DRAW`). A arte vai em `tools/art/art.js`.

**12. Caminhão dá a seta: "pode passar" (P/M)**
- **O que é:** na Estrada do Sítio, quando a contramão está livre, o trator ou caminhão lento à frente **pisca a seta esquerda**, o costume de estrada brasileira para "pode ultrapassar". Se você passa enquanto ele pisca, ele dá duas buzinadas curtas de agradecimento e entra a figurinha "CAMARADAGEM DE ESTRADA".
- **Por que volta:** ensina a ultrapassagem segura da mão dupla sem tutorial, e cria um momento social caloroso.
- **Clima relaxante:** troca a tensão da ultrapassagem por cooperação.
- **Onde:** `game.gd`. `_oncoming_clear` já existe e o piloto já usa `_oncoming_clear(60000.0)`. Marcar `c.blink_t` nos veículos `dir > 0` do Sítio. `world.gd` desenha um pixel âmbar piscando na traseira. O `_sfx("horn")` já existe (dá para usar um pitch mais alto para o "obrigado").

**13. Clima variável: pancada de verão e arco-íris (M)**
- **O que é:** uma terceira opção de clima, **VARIÁVEL**: começa no sol, fecha o céu, cai a pancada de 2 a 3 minutos (o limpador acorda sozinho, as poças aparecem) e, quando abre, surge um **arco-íris** no horizonte, que é figurinha rara.
- **Por que volta:** a viagem tem um arco dramático, sem nenhuma ameaça. Ver a chuva chegando no para-brisa é o coração do título do jogo.
- **Clima relaxante:** a chuva nunca é um perigo maior, e a aderência só cai o que já cai hoje (`grip`).
- **Onde:** `catalog.gd`, `WEATHER`. `game.gd`, `rain_goal` no `_process`. Hoje `cfg.weather` decide coisas fixas no `setup` (céu `SKIES`, `fog_k`, poças em `_build_surface`, estrelas), e elas precisam passar a misturar sol e chuva pelo valor de `rain`. Com a ideia 2, as poças só aparecem nos trechos novos sorteados enquanto chove. O arco-íris é desenhado em `world.gd`, perto de `_sun_moon`.

**14. Calendário de verdade: ipês, festa junina, Natal (P/M)**
- **O que é:** o jogo lê a data do sistema (`Time.get_date_dict_from_system`). **Agosto e setembro:** ipês-amarelos e roxos florescem (o sprite `ipe` já existe; muda a cor e aumenta a frequência). **Junho:** bandeirinhas nas vendas, fogueira à noite e a rádio tocando "forró de estrada". **Dezembro:** pisca-pisca nas casas do sítio e na capela. **Carnaval:** a Litoral FM vira marchinha.
- **Por que volta:** o mundo muda ao longo do ano, então "faz tempo que não jogo, deve ter coisa nova".
- **Clima relaxante:** é sazonal **sem FOMO**. Depois de visto uma vez, o evento fica disponível o ano todo num seletor "ÉPOCA" (ver Riscos).
- **Onde:** `game.gd`, `_populate_terra` (cor/frequência de `ipe`) e `_init_weather`. Opção "ÉPOCA: HOJE / …" em `menu.gd`.

### E. Paradas e passageiros

**15. Parar de verdade: lanche no posto, na venda ou na parada (M)**
- **O que é:** entrar devagar no pátio (faixa da direita e abaixo de ~30 km/h) **para** o carro numa cena estática em pixel art, com a chuva batendo no toldo e o rádio baixinho. Você escolhe um lanche de estrada: **pão de queijo com café no copo americano**, **pastel com caldo de cana**, coxinha, **queijo e doce de leite** na venda do Sítio, **pamonha**. O frentista pergunta "COMPLETA?". Cada lanche e cada lugar dá um **carimbo** na caderneta. Passar direto na faixa da direita continua abastecendo como hoje.
- **Por que volta:** uma pausa com escolha e com cor local. Os lanches viram coleção ("já provei 7 de 12").
- **Clima relaxante:** é literalmente uma pausa dentro do jogo, sem tempo correndo.
- **Onde:** `game.gd`, o bloco `if postos.has(i)` (abastecimento) e a máquina de estados (`state := "menu|drive|pause"`, somar `"parada"`). A cena é um `CanvasLayer` como o `menu.gd`, com a pausa de áudio (`_set_paused_audio`). Os pátios já existem (`road.stop`: `venda`, `posto`, `parada`).

**16. Passageiro que cochila (M)**
- **O que é:** um passageiro opcional no banco da direita, na borda da cabine: **a vó**, **um vira-lata caramelo** com a cabeça para fora da janela, ou ninguém. Com direção suave ele vai relaxando até cochilar. Num buraco ele acorda e reclama ("AI, MEU FILHO!" / "AU!") e depois dorme de novo. O multiplicador x1 a x4 passa a ser mostrado por ele, não pelo número.
- **Por que volta:** dá um rosto e um afeto ao multiplicador que hoje é só número. "Chegar com a vó dormindo" é uma meta que ninguém sente como competição.
- **Clima relaxante:** o feedback de erro vira uma reclamação carinhosa, não um castigo.
- **Onde:** `game.gd`, o bloco do multiplicador (`var m := 1 + mini(3, int(clean / 25.0))`) e os toasts de `_hit_feat`/batida. `cockpit.gd` desenha o passageiro (área perto de `layout.side`). `catalog.gd` ganha posições por carro, e `menu.gd` a escolha "COMPANHIA".

### F. Direção com capricho

**17. Manobras bonitas reconhecidas (P)**
- **O que é:** o jogo **nota** quando você faz coisa de motorista experiente e dá um aviso discreto e uma contagem no diário: **"ENTRE AS RODAS!"** (buraco passando entre os pneus), **"POÇA DESVIADA"**, **"ULTRAPASSAGEM LIMPA"** (Sítio, voltando para a faixa sem buzina da contramão), **"CURVA NO TRAÇADO"** (curva forte sem perder o x4).
- **Por que volta:** é maestria sem pressão. Dá orgulho e não pune quem não faz.
- **Clima relaxante:** só reconhece o acerto, nunca o erro.
- **Onde:** `game.gd`, `_hit_feat`. Hoje ele faz `return` quando `not l and not r`, e é ali que se detecta o "quase". **Depende de corrigir o P3 da rodada 09** (tirar o `or absf(d) < 0.06`), porque hoje passar entre as rodas é impossível. A ultrapassagem usa `overtaking`/o `honk_t` dos carros `dir < 0`.

### G. Personalização do carro e da cabine

**18. Garagem: cor, capa de banco e adesivo (M)**
- **O que é:** cores de época por carro (Besouro verde-limão, bege, azul-calcinha; Picape vermelha com faixa; GT prata ou preto), **capa de banco de bolinhas de madeira** (a de taxista), tapete felpudo, adesivo no vidro traseiro (visto na câmera externa). Tudo liberado por km do carro.
- **Por que volta:** "o meu Besouro" é diferente do de qualquer outro jogador, e o km tem onde ser "gasto" sem nunca ser descontado.
- **Clima relaxante:** é só estética, sem efeito na direção.
- **Onde:** os sprites `player*`/`cockpit*` são gerados por `tools/art/build_art.js` a partir de `tools/art/art.js`. Gerar variantes de cor ali, ou trocar cor por shader (`shaders/palette.gdshader` já processa o quadro). `world.gd`, `_draw_player`. `menu.gd`, tela "GARAGEM".

### H. Modos de jogo calmos

**19. Modo descanso e timer de sono (P)**
- **O que é:** no menu de pausa, a opção **"SÓ CURTIR"** liga o piloto automático, esconde o HUD e alterna a câmera devagar (cabine, externa, e depois uma câmera de janela lateral). Com o **timer de sono** (15/30/60 min), o rádio vai baixando e o carro encosta num posto à noite com a chuva no teto.
- **Por que volta:** vira o "jogo de deixar ligado" para estudar ou dormir, e o hodômetro conta enquanto isso.
- **Clima relaxante:** é o caso extremo do jogo relaxante, feito de propósito.
- **Onde:** `menu.gd`, `PAUSE_ITEMS`. `game.gd`, `set_auto`, `set_cam` e `hud.set_drive(false)`. O fade usa `a_music.volume_db`.

**20. Viagem do dia (P)**
- **O que é:** um botão no menu, **"VIAGEM DE HOJE"**: carro, estrada, clima, hora e semente do sorteio vêm da data. É a mesma viagem para todo mundo naquele dia, com um evento garantido (ideia 11). Não tem ranking: só o carimbo "13/11: BR-116, CHUVA, ENTARDECER" no diário.
- **Por que volta:** é um motivo diário, leve e **sem sequência que se quebra**.
- **Clima relaxante:** tira o peso de escolher. É só "vamos ver como está a estrada hoje".
- **Onde:** `game.gd`, `_ready`/`setup`. O `seed()` já é usado nos testes (`Engine.get_meta("test_seed")`), e basta usar `hash(data)`. `menu.gd`, um botão acima de "PEGAR A ESTRADA".

### I. Fotografia e memórias

**21. Modo foto com legenda (P)**
- **O que é:** a tecla F congela o quadro, esconde o HUD e salva um PNG com uma legenda pixelada no rodapé: "BR-116 · KM 87 · ENTARDECER · CHUVA · BESOURO 1973". Opções simples: com ou sem cabine, moldura de Polaroid. Na versão web, o PNG é baixado.
- **Por que volta:** a chuva no para-brisa ao entardecer já é linda, e dar um jeito de guardar isso cria memória e divulgação espontânea.
- **Clima relaxante:** contemplar e registrar, sem nenhuma pressão.
- **Onde:** `game.gd`, `_unhandled_input` (somar `KEY_F`). A captura usa `get_viewport().get_texture().get_image().save_png("user://fotos/…")`, com `hud.set_drive(false)` durante a captura. Na web (`web/`), `JavaScriptBridge.download_buffer`.

**22. Diário de bordo e cartão-postal do fim da viagem (P/M)**
- **O que é:** ao sair da viagem (`to_menu`) ou chegar ao destino (ideia 3), aparece um **cartão-postal**: a última foto (ideia 21) ou um quadro automático, mais o resumo. "47 KM · 52 MIN · 6 BURACOS (2 ENTRE AS RODAS) · 3 POÇAS · CAFÉ COM PÃO DE QUEIJO NA PARADA · OUVIU 'CAFÉ DE BEIRA DE ESTRADA' · A VÓ DORMIU 31 MIN". Os postais ficam num **diário** no menu.
- **Por que volta:** fecha a sessão com sensação de "valeu a pena", e o diário cheio é a coleção mais pessoal do jogo.
- **Clima relaxante:** é um resumo de lembranças, não um placar de desempenho.
- **Onde:** `game.gd`, `to_menu`. Os contadores `n_holes`, `n_puddles` e `n_bumps` já existem (são ganchos de teste). O diário é salvo em `user://diario/` e a tela vai em `menu.gd`.

### J. Acessibilidade e conforto

**23. Ajustes de conforto (P cada)**
- **O que é:** um menu "AJUSTES" com:
  - **Balanço da câmera** 0/50/100%. A arfagem chega a 22,5 px num buraco a 95 km/h (QA rodada 09), o que pode enjoar.
  - **Placar visível** sim/não.
  - **Buracos:** poucos/normal/estrada ruim.
  - **Trânsito:** leve/normal.
  - **Volumes separados** para rádio, chuva, motor e efeitos.
  - **Ciclo do dia** rápido (7 min, como hoje) ou **lento** (o dia inteiro em ~45 min, o que combina com uma sessão).
  - **Avisos** em texto: todos ou só os essenciais.
- **Por que volta:** quem passa mal ou se irrita com um detalhe não volta, e quem ajusta o jogo do seu jeito volta.
- **Clima relaxante:** o conforto é o produto.
- **Onde:** `menu.gd`, `PAUSE_ITEMS`. `game.gd`: escala de `pitch`/`roll`/`zb` usada por `world.gd` e `cockpit.gd`, `road.hole_p`, a quantidade em `_spawn_cars`, `dt / 110.0` no ciclo, e buses de áudio. Hoje tudo vai para o bus 0: o `set_sound` muta o bus 0 inteiro.

### K. Compartilhamento

**24. Código da viagem (P/M)**
- **O que é:** cada viagem tem um código legível, "BESOURO-SITIO-CHUVA-NOITE-4821" (cfg + semente). Colar o código no menu recria a mesma estrada, os mesmos eventos e a mesma hora. Na versão web, vira um link (`?viagem=…`).
- **Por que volta:** "olha essa estrada que eu peguei, tem boiada e arco-íris" é um convite entre amigos, sem ranking.
- **Clima relaxante:** é compartilhar experiência, não resultado.
- **Onde:** `game.gd`, `setup`/`seed`, `_load_cfg`. `menu.gd` ganha um campo de texto. Para o link, `JavaScriptBridge` na exportação web.

---

## 3. Top 5 para fazer primeiro

Ordem pela relação impacto/custo, respeitando as dependências.

1. **Hodômetro de verdade, km da viagem e km do carro (ideia 1, P).** É o mais barato e muda a língua do jogo de fliperama ("1P/HI-SCORE", com teto em 999.999) para viagem. É a moeda suave que alimenta os desbloqueios (penduricalhos, garagem) sem nunca ser descontada.
2. **Rádio vivo: locutor, recados, previsão e AM melhor à noite (ideias 8 e 9, P).** É quase só texto e volume em cima de `STATIONS` e do bloco de rádio. Dá conteúdo novo a cada viagem e muita personalidade. Ataca a repetição do `.ogg` único enquanto não chegam mais músicas.
3. **A estrada não se repete (ideia 2, M).** Resolve o maior problema estrutural (a volta de ~90 s) e é **pré-requisito** para coleção e eventos fazerem sentido. Também corrige o posto a cada 45 s, que passa a ser colocado por distância.
4. **Caderneta de figurinhas, com penduricalhos como prêmio (ideias 5 e 7, M).** É a motivação de longo prazo, usando sprites que já existem (vaca, capela, ipê, trator, pórtico, SOS). Os primeiros prêmios (São Cristóvão aos 50 km, fita do Bonfim) aparecem na cabine, onde o jogador olha o tempo todo.
5. **Parada com lanche e cartão-postal no fim (ideias 15 e 22, M).** Dá **estrutura** à sessão: um respiro no meio e um fechamento com memória no fim. O posto vira um lugar em vez de uma faixa, e o "valeu, amanhã tem mais" fica explícito.

Brindes baratos para encaixar em qualquer etapa: **modo foto** (21), **ajustes de conforto** (23, principalmente o balanço e o ciclo lento) e **manobras bonitas** (17, logo depois de corrigir o P3 da rodada 09).

### Loop de uma sessão de 10 a 20 minutos (com o top 5)

1. **Menu (30 s).** "SEU BESOURO: 1.284 KM · CADERNETA DO SÍTIO 11/16 · FALTAM 38 KM PARA A FITA DO BONFIM". Escolhe Sítio, chuva, entardecer. A prévia ao vivo já mostra a chuva no vidro.
2. **Primeiros km (0 a 5 min).** A Serra FM toca, e o locutor manda um recado: "ALÔ, SEU JOÃO DA PORTEIRA AZUL…". A estrada se reveste a cada curva: um cafezal que você não tinha visto, uma placa de queijo nova. Primeira figurinha nova do dia: ipê-roxo (aviso discreto no rodapé).
3. **Meio (5 a 9 min).** Um trecho de pasto sorteado traz uma vaca malhada: outra figurinha. O tanque entra na reserva, e o próprio locutor avisa: "QUEM VAI PELO SÍTIO, A VENDA DO SEU ZICO TEM CAFÉ FRESQUINHO".
4. **Parada (9 a 10 min).** Encosta. Pão de queijo e café no copo americano, carimbo novo. A chuva bate no toldo, o rádio está baixinho. Volta para a estrada.
5. **Segunda metade (10 a 17 min).** Escurece. A Noite AM 1040 passa a pegar limpo. A lua aparece entre as nuvens: figurinha rara de noite. O hodômetro cruza 1.300 km e o **santinho de São Cristóvão** aparece pendurado no retrovisor, balançando no próximo buraco.
6. **Fim (17 a 18 min).** Sai pelo menu de pausa e recebe o cartão-postal: "21 KM · 18 MIN · 2 FIGURINHAS NOVAS · PÃO DE QUEIJO NA VENDA DO SEU ZICO". O gancho para voltar aparece sem cobrança: "FALTAM 5 FIGURINHAS NO SÍTIO · O IPÊ-AMARELO SÓ SE VÊ DE DIA". Depois do top 5, os eventos (11) e a seta do caminhão (12) entram neste mesmo loop como surpresas do meio da viagem.

---

## 4. Riscos: o que evitar

- **Sequência diária que se quebra.** A "Viagem do dia" e o calendário nunca podem cobrar presença ("você perdeu sua sequência de 12 dias"). Sem contador de dias seguidos.
- **FOMO sazonal.** Ipê em setembro e festa junina em junho são charme. Depois de vistos uma vez, ficam disponíveis o ano todo no seletor "ÉPOCA", e nada da caderneta é exclusivo de uma data que já passou.
- **Figurinha virar loot box.** A metáfora do álbum lembra pacotinho pago. Nunca vender, nunca sortear pacote, nunca dar repetidas. A figurinha vem de **ver** a coisa. As raras precisam de uma garantia: depois de X km na condição certa (chuva, manhã, Sítio), o evento acontece.
- **Pressa disfarçada.** Nada de "chegue em 10 min", de entrega com relógio ou de bônus por velocidade alta (o GT a 140 km/h já ganha pontos mais rápido; o hodômetro não pode virar corrida). Os marcos devem ser por km e por coisas vistas, não por km/h.
- **Punir o piloto automático.** Ele é a forma mais relaxante de jogar. Km, caderneta, eventos e rádio contam no piloto. Só as "manobras bonitas" (17) exigem as mãos no volante, e isso não tira nada de quem não faz.
- **Avisos demais na tela.** O `hud.toast` tem um único espaço e sobrescreve o anterior (só o buraco checa `toast_t`). Caderneta, rádio, manobras e eventos ao mesmo tempo poluiriam a tela, que hoje é limpa. Criar uma fila com prioridade, mandar o que é de coleção para o rodapé ou um ícone pequeno, e manter o toast central para o essencial (reserva, posto, contramão).
- **Evento que trava a pista.** Boiada e romeiros na mão dupla não podem prender o jogador atrás por mais de ~20 s nem exigir reflexo. Precisam ser lentos, avisados por placa e resolvidos pelo cruise (que já segue o carro da frente).
- **Enjoo.** Mais lombada, mais buraco e mais câmera alternando no modo descanso aumentam o balanço. O ajuste de balanço (23) deve vir antes ou junto do que adiciona solavancos.
- **Desempenho.** O jogo roda a 30,6 fps no renderizador por software (QA rodada 09). Revestir trechos (2) e desenhar eventos (11) deve manter a quantidade de sprites por segmento parecida com a de hoje, e o rejuvenescimento precisa ser espalhado por quadros, não feito de uma vez.
- **Perder o progresso.** Agora o save passa a valer muito (km, caderneta, diário). Gravar de forma atômica (arquivo temporário e depois renomear) e manter compatibilidade com o `viagem.cfg` e o `hiscore.txt` antigos, como o `_load_cfg` já faz.
- **Menu pesado.** O menu hoje é bonito porque tem 4 linhas. Caderneta, garagem, diário e ajustes devem ficar em telas próprias, chamadas por um item, sem crescer a tela de partida. A regra é ir da abertura do jogo à estrada em um Enter.
