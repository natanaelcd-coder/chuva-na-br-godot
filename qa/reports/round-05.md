# Rodada 05: Chuva na BR

Data: 2026-11-12. Fontes:
- `qa/run_qa.sh`: métricas em `qa/metrics/latest.json`, 6 capturas em `qa/shots/`, `fps.txt` (36,6 fps no renderizador por software) e `visibility.json` (agora com 3 câmeras: cabine seca sem painel, externa e **cabine com chuva, painel e gotas**).
- Leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/hud.gd`, `scripts/cockpit.gd` e `tests/test_drive.gd`.
- Diff contra `qa/snapshots/round-04/`: mudaram `game.gd`, `world.gd`, `hud.gd` e `tests/test_drive.gd`. As cinco sugestões da rodada 04 entraram, e também três itens de fora do top 5:
  - linha mantida depois do ajuste (`hold_x`);
  - brilho do buraco com piso de luminosidade;
  - gotas nascendo abaixo da faixa do horizonte;
  - freada firme do cruise (`close`);
  - batida que custa um degrau do multiplicador;
  - arfagem `(0.025 + 0.015 * sp) * tanh(…/0.05)` e teto do tranco do buraco;
  - rodas menores e reflexos mais finos;
  - aviso descido para y = 74;
  - letreiro em passos de 1 px;
  - placa "PISTA IRREGULAR" 70 segmentos antes do trecho.
  
  O banco ganhou `nudge_dodge` e a visibilidade com chuva.

Para checar o que o banco não mede, usei uma **cópia** do projeto no scratchpad (`c5/`). Nenhum arquivo do jogo foi alterado. Rodei:
- (a) toque persistente (0,15 e 0,25 s);
- (b) sem mãos na curva mais fechada: 24 combinações de faixa, sentido, velocidade e toque prévio;
- (c) caminhão a 35 km/h, saindo de 45–100 km/h;
- (d) desvio dentro da faixa;
- (e) **novo: troca de faixa para a frente de um carro lento a 40 km/h**, com 1.500 / 2.500 / 3.500 unidades de distância, a 70 e 95 km/h. Medi a queda de velocidade por quadro e a menor distância com os carros sobrepostos de lado;
- (f) visibilidade com limiar de contraste (exata / > 0,03 / > 0,06), em 3 horas do dia, seco e com chuva forte (150 gotas extras), cabine e câmera externa, com recortes ampliados;
- (g) as variantes de código sugeridas abaixo, medidas antes de recomendar.

## 1. Nota final: **8,1 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **8,3** | Tudo na faixa boa e o P1 da rodada 04 está resolvido:<br>• resposta de 0,167–0,183 s; faixa em 0,82–0,83 s; overshoot de 0,042–0,050; assentamento de 1,20–1,32 s;<br>• o toque fica onde o jogador deixou: 0,074–0,075 depois de 2,5 s;<br>• o desvio dentro da faixa funciona com 0,4–3,0 s de antecedência (11 de 12; só falha com 0,4 s a 95 km/h, o que é reflexo);<br>• curva força 3 com RMS de 0,126/0,138 e offroad 0; sem mãos, offroad 0 nas 24 combinações.<br>Descontos: depois de um toque, a curva vira trilho (desvio de 0,010–0,035, sem nenhuma força para fora), mas sem toque o carro abre 0,094/0,172. São dois comportamentos diferentes para o mesmo volante solto (P4). A batida de lado ainda é um muro (P1). |
| 2 | Suspensão e sensação | 20% | **8,3** | A arfagem na estrada agora cresce com a velocidade: 14,0 / 16,0 / 18,8 px, RMS de 0,015 / 0,021 / 0,024. O buraco fica com 1,5 oscilação, assenta em 1,68 s, corpo de 9,8–15,8 px, arfagem de 14,7–23,4 px (abaixo do teto de 25) e puxão de 0,024–0,041. Desconto: **todo buraco é igual**. A força não depende da largura do buraco (0,07–0,12) nem de as duas rodas caírem juntas, e o assentamento dá 1,683 s nas três velocidades (P3). |
| 3 | Pista e desafio | 20% | **7,9** | Densidade de 11,5 / 14,5 perigos/min (o 14,5 a 90 km/h passa um pouco do teto de 14). O bot cuidadoso acerta 1/23 = 4,3% e 1/29 = 3,4%. Na cabine com chuva, o banco dá legível até 25.500 (margem de 2,0 s a 95). No meu teste com chuva forte, legível até 18.000–19.500 (margem de 1,2–1,3 s), ainda perto do alvo. Desconto: o banco conta pixels, e não forma. De longe, o buraco é um traço claro de 3–4 px, igual ao tracejado da faixa. Na cabine, a 18.000 na faixa da direita, ele fica atrás do fio do terço (P2). |
| 4 | Feedback | 15% | **7,9** | O aviso saiu de cima do retrovisor (`cockpit_pothole`: "ESSE PEGOU..." agora fica sobre o céu). O som do buraco, a batida, o respingo, o ronco no trecho áspero e o tranco do volante continuam proporcionais à velocidade. Descontos:<br>• a resposta ao buraco não é proporcional ao buraco (P3);<br>• **o carro atravessa outros carros** de lado sem nenhuma resposta (P1);<br>• quando bate por trás, a velocidade cai 21–37 km/h num único quadro. |
| 5 | Fluxo relaxante | 10% | **8,3** | Piloto automático com 0 batidas, 1 buraco e 3 poças em 90 s. O cruise nunca bate no caminhão (6 de 6, para a 1.480–1.600). A batida agora custa um degrau do multiplicador (3 → 2) e não zera tudo. Ainda tem 1 batida no `full_drive` a 90 km/h, e a entrada de lado na frente de um carro lento corta a velocidade de 95 para 55 ou 29 km/h quase de uma vez (P1). |
| 6 | Visual e desempenho | 5% | **7,8** | O aviso não cobre mais o retrovisor, o letreiro rola liso e as rodas encolheram. Continua: as rodas são blocos pretos de 9k × 9k e os reflexos sob elas ainda leem como dois quadradinhos marrons (`chase_lane_change`, recorte ampliado). De perto, o buraco parece uma chapa escura com uma barra branca em cima, e não um buraco. A placa "PISTA IRREGULAR" vira "PISTA :RREGULAR" a média distância, por amostragem do sprite (`cockpit_drive`, recorte). O render tem 36,6 fps, normal para software. |

Cálculo: 0,30×8,3 + 0,20×8,3 + 0,20×7,9 + 0,15×7,9 + 0,10×8,3 + 0,05×7,8 = 8,135, arredondado para **8,1**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. Batidas: o carro atravessa outros de lado, e a batida por trás ainda é um muro (Fluxo +0,3, Feedback +0,2, Dirigibilidade +0,1)
- **Sintoma:**
  - A colisão só existe com `250 < d < 1250` atrás do outro carro. Com `d ≤ 250`, isto é, lado a lado, nada acontece, e o jogador entra na faixa por cima de um carro.
  - Por trás, `v = lerpf(v, cv - 6, 0.6)` roda a cada quadro sem `dt`. Isso tira 60% da diferença por quadro: a 60 fps, é praticamente instantâneo; a 144 fps, mais ainda.
- **Prova (teste e, carro a 40 km/h, jogador troca da faixa do meio para a direita):**

  | Velocidade, distância | Batidas | Maior queda num quadro | v mínima | Menor distância com os carros sobrepostos |
  |---|---|---|---|---|
  | 70 km/h, 1.500 | 0 | 1,2 km/h | 67,7 | **44 unidades** (atravessou o carro) |
  | 70 km/h, 2.500 | 1 | **21,6 km/h** | 30,5 | 1.300 |
  | 95 km/h, 2.500 | 1 | **36,6 km/h** | 54,9 | **19 unidades** (bateu e atravessou) |
  | 95 km/h, 3.500 | 1 | **37,1 km/h** | 29,0 | 1.207 |

  `full_drive` a 90 km/h: `car_bumps` = 1.
- **Onde:** `scripts/game.gd`, `_process`, laço de trânsito (`if d < 1250.0 and d > 250.0 …`).
- **Mudança sugerida (testada em `c5`):** um esbarrão lateral que empurra o jogador para fora, e uma freada dependente de `dt`:
  ```gdscript
  var swipe := (d <= 250.0 or d > TRACK - 500.0) and dxl < 0.46   # alongside: no driving through cars
  if swipe:
  	var sgn := 1.0 if px >= c.x else -1.0
  	px = c.x + sgn * 0.46
  	vx = sgn * 0.45
  	kick = sgn * 0.5
  if (d < 1250.0 and d > 250.0 and dxl < 0.46 and v > c.v) or swipe:
  	sfx["bump"].volume_db = …
  	if not swipe:
  		v = lerpf(v, maxf(0.0, cv - 6.0), minf(1.0, dt * 10.0))   # a firm shove over ~0.2 s, not a wall
  	if bump_t <= 0.0 and started:
  		…   # (mesmo bloco de hoje)
  ```
  Resultado na cópia:
  - maior queda num quadro de **6,0 / 10,2 / 11,1 km/h** (era 21,6 / 36,6 / 37,1);
  - a entrada lado a lado agora conta como batida, com tranco no volante e som;
  - troca de faixa, toque, curva, piloto automático e caminhão idênticos.
  
  Num jogo relaxante, vale considerar também uma buzina do outro carro e uma desaceleração dele quando o jogador entra na frente (não testado).

### P2. De longe, o buraco é um traço branco igual ao tracejado da faixa (Pista +0,3, Visual +0,2)
- **Sintoma:** o brilho novo, `pud_h.lerp(Color("c8d4e8"), 0.5)`, é quase branco. Ele tem largura mínima de 3,6 unidades, altura de 1,5 e névoa reduzida (`fa * 0.3`). A 15.000–25.000, a forma e a cor são as de um traço de tinta da faixa. O banco diz "legível" porque conta pixels alterados, e não se o jogador entende que é um buraco.
- **Prova:**
  - Recorte ampliado de `v5_0.2_0.png`, cabine com chuva a 18.000: o buraco na faixa da direita fica atrás do fio do terço e se confunde com os tracejados "= =" ao lado.
  - Em `chase_lane_change`, de perto, o buraco lê como uma chapa escura com uma barra branca em cima.
  - Contagens no banco: 33–34 px a 27.000 com a cabine seca, ou seja, satura no fim da grade.
- **Onde:** `scripts/world.gd`, `_draw`, laço "potholes, patches and puddles", ramo do buraco (as duas `draw_rect` do brilho).
- **Mudança sugerida (testada em `c5`):** um brilho azul-céu, de água, e uma borda escura embaixo:
  ```gdscript
  var glint := pud_h.lerp(Color("8ec5ff"), 0.6)   # sky-blue water, not the white of the lane paint
  draw_rect(Rect2(f2 - hw * 1.2, hy2 - 1.0, hw * 2.4, 1.0), glint.lerp(fog, fa * 0.3))
  draw_rect(Rect2(f2 - hw * 0.8, hy2, hw * 1.6, 1.0), hole_c.lerp(fog, fa * 0.3))   # dark lip under it: a hole, not a dash
  ```
  Na cópia, pixels alterados (limiar > 0,03):

  | Condição | Atual | Variante |
  |---|---|---|
  | Cabine com chuva forte a 18.000 | 33 / 34 / 33 | 30 / 32 / 30 |
  | Cabine seca a 21.000 | 41–48 | 39–45 |
  | Câmera externa à noite a 12.000 | 47 | 39 |
  | Câmera externa à noite a 21.000 | 38 | 37 |

  A cor deixa de ser a da tinta (recorte `cmp_e.png`). Testei também uma variante só escura: à noite, na câmera externa, ela cai para 19 px a 12.000. Não recomendo.
  
  Para o problema do fio do terço, uma opção é desenhar o terço com alfa de 0,6 acima de y = 60 (não testado).

### P3. Todo buraco é igual (Suspensão +0,2, Feedback +0,2)
- **Sintoma:** em `_hit_feat`, a força é `k := 0.5 + sp`. Ela não depende de `f.w` (de 0,07 a 0,12, quase o dobro) nem de as duas rodas caírem juntas (`side == 0`). O jogador não aprende a escolher um buraco menor, nem a passar com o buraco entre as rodas.
- **Prova:**
  - `pothole.settle_s` = 1,683 nas três velocidades e `oscillations` = 1,5 sempre: só a amplitude muda.
  - No código, um buraco de 0,07 numa roda e um de 0,12 nas duas dão o mesmo `zb_v`.
- **Onde:** `scripts/game.gd`, `_hit_feat`.
- **Mudança sugerida (testada em `c5`):**
  ```gdscript
  var k := (0.5 + sp) * (0.75 + 5.0 * clampf(f.w - 0.07, 0.0, 0.05)) * (1.3 if side == 0.0 else 1.0)   # bigger hole, harder hit; both wheels, harder still
  ```
  Com o buraco de teste (w = 0,1):
  - corpo de **8,8 / 11,8 / 14,2 px** e arfagem de 13,0 / 18,2 / 22,5 px, tudo dentro da faixa;
  - puxão de 0,022–0,037;
  - assentamento sem mudança.
  
  Um buraco grande nas duas rodas chega a k × 1,3, com arfagem limitada pelo `minf(k, 1.35)` que já existe. O som do buraco já usa `k`, então fica proporcional sem mais código.

### P4. A curva vira trilho depois de um toque e empurra sem toque (Dirigibilidade +0,2)
- **Sintoma:** no modo "linha mantida" (`free_t > 0.5`), o ímã soma `+ curve * sp * sp * dt * 0.16`, que é exatamente o contrário do empurrão da curva. Depois de qualquer toque, a curva mais fechada passa sem nenhuma sensação de força. Sem toque, o ímã de centro de faixa não compensa e o carro abre 0,17. O mesmo volante solto se comporta de dois jeitos, e em nenhum dos dois a curva pede volante.
- **Prova (teste b):** desvio máximo sem toque de 0,094 (70) / 0,172 (95); com toque, de **0,010–0,035**. O bot da curva mais fechada pressiona a tecla 61–67% do tempo, mas isso é porque ele é liga-desliga: um humano não precisa.
- **Onde:** `scripts/game.gd`, `_process`, bloco do ímã (`elif free_t > 0.5`).
- **Mudança sugerida (testada em `c5`, junto com o P3):** compensar só 60% no modo "linha mantida":
  ```gdscript
  px += (hold_x - px) * minf(1.0, 2.5 * dt) + curve * sp * sp * dt * 0.16 * 0.6   # the bend still leans you out a little
  ```
  - Na cópia, sem mãos depois de um toque, o desvio máximo fica em 0,024–0,054 a 70 km/h e 0,053–0,099 a 95, com offroad 0 nas 24 combinações. O carro "abre" um pouco na curva, como deve.
  - **Não** aplicar a mesma compensação ao ramo de centro de faixa. Testei: o bot da curva a 95 km/h passa a sair da pista (offroad de 0,083 s) e a 70 km/h deixa de precisar de tecla (RMS 0,026).

### P5. O carro na câmera externa e a placa de longe (Visual +0,4)
- **Sintoma:**
  - As rodas são quadrados pretos lisos (9k × 9k) com três riscos.
  - Os reflexos sob as rodas (`_reflect(sx ± 23k, sy + 2k, 4k, 12k, …)`) ainda leem como dois tocos marrons logo abaixo do pneu (recorte de `chase_lane_change`).
  - A placa "PISTA IRREGULAR", reduzida com amostragem por ponto, perde colunas e vira ":RREGULAR" a média distância.
- **Onde:**
  - `scripts/world.gd`, `_draw_player`, laço das rodas e as duas chamadas de `_reflect`;
  - `_sprite`, para as placas.
- **Mudança sugerida:**
  - Rodas: um tom mais claro na metade de cima (pneu molhado pegando luz) e altura de 7k.
  - Reflexos: colocar os das lanternas no centro de cada lanterna (sx ± 22,5k, a mesma posição de `brake`), com alfa de 0,12 parado e 0,3 freando. Hoje eles caem fora das lanternas, embaixo das rodas.
  - Placas: não desenhar o sprite com texto quando `w < 24` unidades, e trocar por um retângulo verde com duas linhas claras. Assim, a placa nunca aparece com o texto quebrado.
  
  Nada disso foi testado.

Fora do top 5:
- Densidade de 14,5 perigos/min a 90 km/h, um pouco acima do teto de 14 (o bot acerta só 3,4%, então não incomoda).
- A placa "PISTA IRREGULAR" agora fica a 14.000 unidades, ou 1,47 s a 100 km/h, antes do trecho. Melhorou, mas 2 s (90–100 segmentos) daria tempo de trocar de faixa com calma.
- A batida do `full_drive` a 90 km/h é do bot, que entra de lado perto de um carro lento.

## 3. Problemas da própria métrica (descontados na nota)

- **`visibility_rendered` mede tamanho, e não forma nem contraste.** Qualquer pixel diferente conta. Com largura mínima de 1,5, altura mínima de 2 unidades e névoa reduzida (`fa * 0.3`), um buraco dá ≥ 30 px a qualquer distância. A grade satura: a cabine seca dá 33 px a 27.000, o último ponto, e o alcance real é "pelo menos 27.000". Sugiro:
  - contar só pixels com diferença de luminância > 0,06;
  - acrescentar uma métrica de "parece tracejado": a fração dos pixels alterados com cor a menos de 0,1 de `e_line`.
- **A chuva no banco é leve.** As gotas vêm de 4 s a 70 km/h com o limpador ligado. Com 150 gotas extras, o alcance na cabine cai de 25.500 para 18.000–19.500. Considerei os dois números.
- **`curve_follow` mede o bot, e não o jogo.** O bot liga-desliga aperta a tecla 61–67% do tempo, mas um humano pode soltar o volante depois de um toque e passar a curva com desvio de 0,01–0,035 (P4).
- **Nenhum cenário põe o jogador ao lado de um carro.** Foi assim que o atravessamento (P1) passou batido em quatro rodadas. Sugiro portar o teste e (`t/qa5.gd`, `side_merge`).

## 4. Comparação com a rodada 04

A nota foi de **7,8 para 8,1**. As cinco sugestões da rodada 04 entraram, e os números previstos na cópia se confirmaram: desvio dentro da faixa que funciona, toque persistente, arfagem crescente, 0 batidas no caminhão com 5.000 unidades e aviso fora do retrovisor.

| Métrica | Rodada 04 | Rodada 05 | Alvo |
|---|---|---|---|
| Troca de faixa: tempo / overshoot / assenta | 0,82–0,83 s / 0,042–0,050 / 1,20–1,32 s | igual | 0,6–1,0 / < 0,10 / < 1,5 |
| Toque: pico / depois de 2,5 s | 0,074–0,075 / 0,000 | 0,074–0,075 / **0,074–0,075** | 0,05–0,12 |
| Desvio dentro da faixa, 1–3 s de antecedência | falha | **funciona (11/12 de 0,4 a 3 s)** | funciona |
| Sem mãos na curva: desvio máximo (sem / com toque) | 0,094–0,172 / 0,010–0,035 | igual | dentro da pista |
| Curva força 3: RMS / offroad | 0,126–0,138 / 0 | igual | < 0,15 / 0 |
| Arfagem na estrada (50 / 70 / 95 km/h) | 17,6 / 17,6 / 17,8 px | **14,0 / 16,0 / 18,8 px** | 8–25, variando |
| Arfagem do buraco a 95 km/h | 25,3 px | **23,4 px** | ≤ 25 |
| Buraco legível até: cabine com chuva (banco) | 15.000 (medido por mim) | **25.500** (18.000–19.500 com chuva forte) | margem ≥ 1,5 s |
| Buraco legível até: externa à noite | ~12.000 | **≥ 25.000** | — |
| Bot: perigos acertados | 8,7% / 16% | **4,3% / 3,4%** | ≤ 15% |
| Caminhão a 100 km/h, 5.000 unidades | 1 batida | **0** | 0 |
| Batida: queda num quadro / custo | 70 km/h → corte / zera o multiplicador | 21–37 km/h / **−1 degrau** | suave |
| Piloto automático em 90 s | 0 / 1 / 3 | igual | — |
| FPS (software) | 34,7 | 36,6 | ~40 |

- **Melhorou:** o ajuste fino virou permanente e o desvio dentro da faixa funciona; a arfagem varia com a velocidade; a visibilidade com chuva melhorou muito; a punição da batida é mais leve; o aviso saiu do retrovisor; as rodas estão menores; o letreiro rola liso.
- **Piorou:** nada medido piorou. O brilho mais forte deixou o buraco de longe parecido com tinta de faixa (P2), efeito colateral da correção de visibilidade.
- **Ficou igual:** a batida que cai quase num quadro (o `lerpf(…, 0.6)` não depende de `dt`), as rodas em bloco e todo buraco com a mesma força.
- **Novos achados:**
  - o carro atravessa outros lado a lado (P1);
  - a força do buraco é independente do tamanho (P3);
  - a curva vira trilho depois de um toque (P4);
  - o texto da placa quebrado a média distância (P5);
  - a métrica de visibilidade satura (seção 3).
