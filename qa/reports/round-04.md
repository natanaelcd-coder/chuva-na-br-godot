# Rodada 04: Chuva na BR

Data: 2026-11-12. Fontes:
- `qa/run_qa.sh`: métricas em `qa/metrics/latest.json`, 6 capturas em `qa/shots/`, `fps.txt` (34,7 fps no renderizador por software) e `visibility.json`.
- Leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/hud.gd`, `scripts/cockpit.gd` e `tests/test_drive.gd`.
- Diff contra `qa/snapshots/round-03/`: mudaram `game.gd`, `world.gd` e `hud.gd`. `tests/test_drive.gd` não mudou. As cinco sugestões da rodada 03 e três itens de fora do top 5 entraram: brilho largo no buraco; ímã de faixa volta ao centro depois de 0,5 s sem tecla (`free_t`); cruise com curva de frenagem em raiz quadrada até 9.000 unidades; puxão lateral do buraco; ronco que segue `ROUGH`; volume da batida; respingo em dois leques; arfagem com `tanh`; reflexos em faixas finas; letreiro que rola; placa "PISTA IRREGULAR" só antes de trecho áspero.

Para checar o que o banco de testes não mede, usei **cópias** do projeto no scratchpad (`copy/` e `copy2/`). Nenhum arquivo do jogo foi alterado. Rodei:
- (a) **toque persistente**: deslocamento depois de um toque de 0,15 s e de 0,25 s, medido em 0,5 / 1,0 / 1,5 / 2,0 s;
- (b) **sem mãos na curva mais fechada** (±3), nas 3 faixas, a 70 e 95 km/h, com e sem toque de correção antes (o teste c da rodada 03);
- (c) **caminhão a 35 km/h**, saindo de 45 a 100 km/h, com 12.000 e 5.000 unidades de distância, sem mãos;
- (d) **desvio dentro da faixa**: buraco (w 0,09) sob a roda direita, o jogador segura ← por 0,25 s com 0,4 a 3,0 s de antecedência;
- (e) **visibilidade do buraco** com limiar de contraste (exata / > 0,03 / > 0,06), em 4 horas do dia, **com chuva e com o painel e as gotas no vidro**, estado congelado entre os dois quadros;
- (f) as variantes de código sugeridas abaixo, medidas antes de recomendar.

## 1. Nota final: **7,8 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **7,9** | Tudo na faixa boa: resposta de 0,167–0,183 s, faixa em 0,82–0,83 s, overshoot de 0,042–0,050, assentamento de 1,20–1,32 s, toque com pico de 0,074–0,075 e curva força 3 com RMS de 0,126/0,138 e offroad 0. O problema da rodada 03 sumiu: sem mãos na curva, com ou sem toque, as 24 combinações ficam com offroad 0 e desvio máximo de 0,17. Desconto novo: o ímã **desfaz qualquer ajuste fino depois de 0,5 s**. O carro volta ao centro da faixa em ~1 s (teste a), então desviar de buraco dentro da faixa só funciona como reflexo de última hora (teste d). |
| 2 | Suspensão e sensação | 20% | **8,0** | O buraco está ideal: 1,5 oscilação, assenta em 1,68 s, corpo de 9,8–15,8 px, arfagem de 14,7–25,3 px e agora um puxão lateral de 0,024 / 0,033 / 0,041 da pista. Ressalvas: a arfagem na estrada continua quase igual nas três velocidades (17,6 / 17,6 / 17,8 px). O `tanh` só arredondou o teto, então toda lombada ainda parece a mesma. E a arfagem do buraco a 95 km/h (25,3 px) passa um pouco do teto de 25. |
| 3 | Pista e desafio | 20% | **7,3** | Densidade de 11,5–12,5 perigos/min. O bot cuidadoso acerta 2/23 = 8,7% a 70 km/h e 4/25 = 16% a 90 (alvo ≤ 15%). A métrica de visibilidade bate o alvo no limite: legível até 21.000 unidades e margem de **1,50 s a 95**. Mas isso vale sem chuva e sem painel. Com o painel e as gotas no vidro, o buraco só fica legível até **15.000** (margem de 0,83 s a 95). Na câmera externa à noite, até **12.000** (margem de ~0,5 s). Num jogo que se chama "Chuva na BR", a condição real é a com chuva. |
| 4 | Feedback | 15% | **7,8** | Fechou o que faltava: o ronco segue o trecho áspero (`ROUGH`) e fica mudo na reta lisa da esquerda; a batida tem volume proporcional à diferença de velocidade; o respingo externo virou dois leques visíveis (`chase_puddle`); o volante dá o tranco e o carro puxa junto. Falta: de longe, o buraco é só um risco claro, da mesma cor da poça e dos riscos de chuva. No cockpit, o aviso ("ESSE PEGOU...", `cockpit_pothole`) é desenhado em cima do retrovisor. |
| 5 | Fluxo relaxante | 10% | **8,0** | Piloto automático com 0 batidas, 1 buraco e 3 poças em 90 s. O cruise não bate mais no caminhão de 45 a 100 km/h (12.000 unidades: para a 1.600). Restam batidas quando um carro lento aparece perto: 1 no `full_drive` a 90 km/h e 1 no teste c com 5.000 unidades a 100 km/h. A batida corta a velocidade num único quadro e zera o multiplicador. Também incomoda o ímã que desfaz o desvio (item 1): o jogador faz a coisa certa cedo e mesmo assim cai no buraco. |
| 6 | Visual e desempenho | 5% | **7,7** | Melhorou: o letreiro do rádio rola, o respingo aparece e os reflexos não são mais estacas. Continua: as rodas são dois blocos pretos altos pendurados abaixo do para-choque, e os reflexos novos, colados embaixo dos pneus, parecem blocos marrons de barro (`chase_drive`, `chase_lane_change`). O letreiro anda em passos de 2 px, ou seja, 15 passos/s a 30 px/s, e fica um pouco serrilhado. O render tem 34,7 fps, normal para software. |

Cálculo: 0,30×7,9 + 0,20×8,0 + 0,20×7,3 + 0,15×7,8 + 0,10×8,0 + 0,05×7,7 = 7,785, arredondado para **7,8**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. O ímã de faixa desfaz o desvio dentro da faixa depois de 0,5 s (Dirigibilidade +0,4, Pista +0,3, Fluxo +0,1)
- **Sintoma:** a correção da rodada 03 (`free_t > 0.5` → `press_lane = -1`) segurou o carro na curva, mas transformou todo toque num ajuste temporário. 0,5 s depois de soltar a tecla, o ímã forte (`px += (LANES[lane] - px) * 2.5 * dt`) arrasta o carro de volta ao centro da faixa. Os buracos ficam a até ±0,22 do centro, quase sempre sob uma roda. Desviar deles com um ajuste fino só dá certo se o jogador agir no último instante. Quem lê a pista cedo, como a visibilidade nova convida, é desfeito pelo jogo.
- **Prova:**
  - Teste a, toque de 0,15 s a 70 km/h: px = 0,074 em 0,5 s, 0,020 em 1,0 s e 0,006 em 1,5 s. O toque de 0,25 s vai a 0,178 e cai para 0,049 em 1,0 s.
  - Teste d, buraco sob a roda direita, ← por 0,25 s: a 70 km/h o desvio funciona com antecedência de 0,4–0,7 s e **falha com 1,0 / 1,5 / 2,0 / 3,0 s** (px no buraco: 0,595 / 0,648 / 0,662 / 0,667, de volta ao centro). A 95 km/h já falha com 0,7 s.
  - `tap.lateral_move_after_2_5s_road` = 0,000 (era 0,05 na rodada 03).
- **Onde:** `scripts/game.gd`, `_process`, ramo manual (`free_t` / `press_lane`) e o bloco do ímã logo depois de `vx += (steer …)`.
- **Mudança sugerida (testada em `copy2`):** depois do ajuste, segurar a linha que o jogador escolheu, limitada a ±0,2 do centro da faixa e com a força da curva compensada só nesse modo. Declarar `var hold_x := 0.0` e trocar o reset por:
  ```gdscript
  free_t = 0.0 if dir != 0.0 else free_t + dt
  if free_t > 0.5 and free_t - dt <= 0.5 and lane == press_lane:   # the nudge is over: keep the line the player chose
  	hold_x = clampf(px, LANES[lane] - 0.2, LANES[lane] + 0.2)
  ```
  No ímã, entre o ramo `lane != press_lane` e o ímã fraco:
  ```gdscript
  elif free_t > 0.5:       # hands off after a nudge: hold that line, even through the bend
  	px += (hold_x - px) * minf(1.0, 2.5 * dt) + curve * sp * sp * dt * 0.16
  ```
  Resultado na cópia:
  - teste d: **desvio funciona com 0,4 a 3,0 s de antecedência**, nas duas velocidades (px no buraco ≈ 0,49);
  - toque: o deslocamento fica (0,074 aos 2 s);
  - sem mãos na curva depois de um toque: desvio máximo de 0,010–0,035, offroad 0 nas 24 combinações;
  - sem toque, nada muda (0,094 / 0,172);
  - troca de faixa, pico do toque, curva e piloto automático idênticos; `full_drive` a 70 km/h: buracos de 2 → 1.

### P2. Com chuva no vidro, ou à noite na câmera externa, o buraco só é legível bem mais perto (Pista +0,5)
- **Sintoma:** a margem de 1,50 s a 95 km/h só existe nas condições do teste, sem chuva e sem painel. Com o painel e as gotas no vidro, que são a condição normal do jogo (chuva de 0,8 e até 230 gotas), o risco de brilho fica coberto. À noite, `pud_h = hor.lerp(WHITE, 0.25)` é um azul escuro (`1a2547`) e quase não contrasta na câmera externa. O brilho também tem a mesma cor e forma dos riscos de chuva e dos tracejados.
- **Prova (teste e; pixels alterados por um buraco, limiar > 0,03; legível ≥ 30):**

  | Condição | 12.000 | 15.000 | 18.000 | 21.000 | Margem a 95 km/h |
  |---|---|---|---|---|---|
  | Cabine, seco, sem painel (como o banco) | 62 | 51 | 41 | 34 | 1,50 s |
  | Cabine, chuva com painel e gotas (entardecer / noite / manhã) | 61–62 | 38 | 26–27 | 21–26 | **0,83 s** |
  | Câmera externa, noite | 35 | 28 | 28 | 31 | **~0,5 s** |

  O limiar de contraste (0,03 ou 0,06) quase não muda a contagem, então o problema é a cobertura, e não a cor exata.
- **Onde:** `scripts/world.gd`, `_draw`, laço "potholes, patches and puddles", ramo do buraco.
- **Mudança sugerida (testada em parte):** um brilho com piso de luminosidade e menos névoa na faixa larga:
  ```gdscript
  var glint := pud_h.lerp(Color("c8d4e8"), 0.5)
  draw_rect(Rect2(f2 - hw * 0.8, hy2, hw * 1.6, 0.5), glint.lerp(fog, fa))
  draw_rect(Rect2(f2 - hw * 1.2, hy2 - 1.0, hw * 2.4, 1.5), glint.lerp(fog, fa * 0.3))
  ```
  Na cópia:
  - cabine com chuva: legível até **18.000** (33–34 px), a qualquer hora, o que dá margem de **1,16 s a 95 km/h** e 1,87 s a 70;
  - câmera externa à noite: legível até **25.000** (37 px);
  - seco: 21.000 → 25.000.

  Para chegar a 1,5 s com chuva falta reduzir as gotas na faixa do horizonte, por exemplo nascer as gotas com `y` entre 40 e 119 em vez de 15 e 119 em `_splash` e no laço de `drops` (não testado). Também falta dar ao buraco uma forma própria, como a borda escura dupla ou o galho espetado da rodada 03, para não confundir com a poça e com a chuva.

### P3. Batida por entrada lateral: a velocidade cai num quadro e o multiplicador zera (Fluxo +0,3, Feedback +0,1)
- **Sintoma:** o cruise novo resolve a aproximação por trás, mas o limite de desaceleração de 34 km/h/s não basta quando um carro lento aparece a menos de ~5.000 unidades, por exemplo depois de uma troca de faixa. Aí vem a batida: `v = maxf(0.0, cv - 6.0)` leva de 100 a 29 km/h num único quadro, toca "OPA! SEM PRESSA" e zera `clean` e `mult`.
- **Prova:** teste c com 5.000 unidades a 100 km/h: 1 batida (menor distância de 1.297). `full_drive` a 90 km/h: `car_bumps` = 1.
- **Onde:** `scripts/game.gd`, `_process`, bloco do cruise e laço de trânsito.
- **Mudança sugerida (testada):** uma freada firme quando alguém aparece perto:
  ```gdscript
  var close := false            # antes do laço do cruise
  ...
  	close = close or (dd < 4000.0 and v > c.v + 15.0)   # dentro do if dd > 250 …
  v += clampf(tgt - v, (-70.0 if close else -34.0) * dt, 13.0 * dt)
  ```
  Na cópia, o caso de 5.000 a 100 km/h vira **0 batidas** (para a 1.480). Os casos de 12.000 e todas as outras métricas não mudam. A batida do `full_drive` a 90 km/h continua: ela vem de o bot entrar de lado na faixa de um carro a menos de 1.250 unidades. Para ela, sugiro também suavizar a punição: trocar `mult = 1` por `mult = maxi(1, mult - 1)` e `clean = 0.0` por `clean = minf(clean, (mult - 1) * 25.0)`, e trocar o corte instantâneo por `v = lerpf(v, maxf(0.0, cv - 6.0), 0.6)` (não testado).

### P4. Na estrada, a arfagem continua saturada: toda lombada parece igual (Suspensão +0,2)
- **Sintoma:** com `0.035 * tanh((sl - slope) / 0.035)`, a entrada quase sempre passa de 0,035, e o `tanh` fica no teto do mesmo jeito que o `clamp`. A arfagem máxima não muda com a velocidade e o RMS cresce pouco.
- **Prova:** `ride.pitch_max_screen_px` = 17,6 / 17,6 / 17,8 a 50 / 70 / 95 km/h (eram 19,5 / 18,9 / 18,6). `pitch_rms` = 0,019 / 0,023 / 0,025.
- **Onde:** `scripts/game.gd`, `_process`, linha `var pt := …`.
- **Mudança sugerida (testada):**
  ```gdscript
  var pt := (0.025 + 0.015 * sp) * tanh((sl - slope) / 0.05) - …
  ```
  Na cópia, a arfagem máxima fica em **14,0 / 16,0 / 18,8 px** e o RMS em 0,015 / 0,021 / 0,024. Agora cresce com a velocidade e continua dentro de 8–25 px. Buraco, troca de faixa e curva não mudam. Opcional: limitar o tranco de arfagem do buraco a 95 km/h (`pitch_v += 0.7 * minf(k, 1.35)`) para ficar em ≤ 25 px (não testado).

### P5. O carro na câmera externa: rodas "de pernas" e reflexos que parecem barro; aviso sobre o retrovisor (Visual +0,5, Feedback +0,1)
- **Sintoma:**
  - As rodas são dois retângulos pretos de 9k × 12k abaixo do para-choque, e a carroceria parece flutuar.
  - `_reflect` desenha as faixas a partir de `sy`, logo embaixo dos pneus, com o vermelho escurecido pelo asfalto. O resultado lê como blocos marrons de lama (recortes de `chase_drive` e `chase_lane_change`).
  - No cockpit, os avisos em y = 46 cobrem o retrovisor (`cockpit_pothole`).
- **Onde:**
  - `scripts/world.gd`, `_draw_player`: o laço das rodas e as duas chamadas de `_reflect`;
  - `scripts/hud.gd`, `_ready`: `l_toast = _centered("", 16, AMBER, 46)`.
- **Mudança sugerida:**
  - Rodas: altura de 7k, com o topo escondido 3k atrás do para-choque (`sy - 9.0 * k`).
  - Reflexos: começar 2k abaixo do pneu e com metade da largura (`_reflect(sx ± 23k, sy + 2.0 * k, 4.0 * k, 12.0 * k, …)`), com alfa máximo de 0,3 mesmo freando.
  - Aviso: descer para y ≈ 70 só na câmera interna, ou dar a ele uma tarja escura semitransparente.

Fora do top 5:
- O letreiro anda em passos de 2 px (`roundf(…/2)*2` em `hud.gd`, `_process`), 15 passos/s. Com passo de 1 px e 30 px/s fica mais liso.
- A placa "PISTA IRREGULAR" fica 40 segmentos (8.000 unidades) antes do trecho: 0,84 s a 100 km/h entre passar pela placa e o áspero começar. Ela é visível de longe, mas 60–80 segmentos dariam mais tempo de trocar de faixa.
- A arfagem do buraco a 95 km/h dá 25,3 px, acima do teto de 25 (P4).

## 3. Problemas da própria métrica (descontados na nota)

- **`visibility_rendered` desliga a chuva e esconde o painel.** Foi assim que o P2 passou despercebido: com chuva e gotas, o alcance cai de 21.000 para 15.000 (teste e). Sugiro rodar a mesma medição com `rain = 0.8`, o painel visível e o estado congelado (`g.set_process(false)` entre os dois quadros). A grade de distâncias (…18.000, 21.000, 25.000) é grossa, e a margem de 1,50 s é exatamente o degrau de 21.000. Descontei da Pista.
- **O `full_drive` só troca de faixa.** Ele não testa o desvio dentro da faixa, por isso não vê o P1. Sugiro portar o teste d (`t/qa4.gd`, `nudge_dodge`): buraco sob uma roda, desvio com 0,4–3,0 s de antecedência.
- **`tap.lateral_move_after_2_5s_road`** = 0 parece "estável", mas mostra que o ajuste foi desfeito. Com a mudança do P1 ele volta a ~0,074, que é o valor certo.
- **`ride.pitch_max_screen_px`** dentro da faixa não significa variedade. Vale olhar o RMS e a diferença entre velocidades.
- A batida do `full_drive` a 90 km/h é do bot (entrada lateral perto de carro lento). Pesou pouco na nota.

## 4. Comparação com a rodada 03

A nota foi de **7,5 para 7,8**. As cinco sugestões entraram e os números previstos na cópia se confirmaram (visibilidade de 21.000, puxão de 0,024–0,041, 0 batidas no caminhão, offroad 0 sem mãos).

| Métrica | Rodada 03 | Rodada 04 | Alvo |
|---|---|---|---|
| Troca de faixa: tempo / overshoot / assenta | 0,82–0,83 s / 0,042–0,050 / 1,20–1,32 s | igual | 0,6–1,0 / < 0,10 / < 1,5 |
| Toque: pico / depois de 2,5 s | 0,074–0,075 / 0,05 | 0,074–0,075 / **0,000** | 0,05–0,12 |
| Sem mãos na curva depois de um toque | offroad de 3,6–5,8 s | **0 s** | 0 |
| Desvio dentro da faixa com ≥ 1 s de antecedência | (não medido) | **falha** | funciona |
| Curva força 3: RMS / offroad | 0,126–0,138 / 0 | igual | < 0,15 / 0 |
| Buraco: puxão lateral | 0,007 | **0,024–0,041** | perceptível |
| Arfagem na estrada (50 / 70 / 95 km/h) | 19,5 / 18,9 / 18,6 px | 17,6 / 17,6 / 17,8 px | 8–25, variando |
| Buraco legível até (banco de testes) | 15.000 (margem de 0,83 s a 95) | **21.000 (1,50 s)** | ≥ 1,5 s |
| Buraco legível com chuva, na cabine | (não medido) | 15.000 (0,83 s) | ≥ 1,5 s |
| Bot: perigos acertados | 13% / 17% | 8,7% / 16% | ≤ 15% |
| Caminhão a 35 km/h, saindo de 75–100 km/h | 1 batida | **0** | 0 |
| Piloto automático em 90 s | 0 / 1 / 3 | igual | — |

- **Melhorou:** visibilidade nas condições do teste, segurança sem mãos na curva, cruise, puxão do buraco, ronco no áspero, volume da batida, respingo externo, letreiro e reflexos.
- **Piorou:** o ajuste fino virou temporário (P1), efeito colateral da correção do ímã.
- **Ficou igual:** rodas "de pernas", arfagem saturada (o `tanh` quase não mudou nada) e batida que corta a velocidade num quadro.
- **Novos achados:**
  - o desvio dentro da faixa que é desfeito (P1);
  - a visibilidade com chuva no vidro e à noite na câmera externa (P2);
  - a batida por entrada lateral (P3);
  - o aviso sobre o retrovisor (P5).
