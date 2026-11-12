# Rodada 03: Chuva na BR

Data: 2026-11-12. Fontes:
- `qa/run_qa.sh`: métricas em `qa/metrics/latest.json`, capturas em `qa/shots/` (6 PNG), `fps.txt` (35,4 fps no renderizador por software) e `visibility.json`.
- Leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/cockpit.gd` e `tests/test_drive.gd`.
- Diff contra `qa/snapshots/round-02/scripts/`: mudaram `game.gd` e `world.gd`. As cinco sugestões da rodada 02 entraram: buracos desenhados depois da pista, com tamanho mínimo e brilho molhado; placa "PISTA IRREGULAR"; cruise que cede ao carro da frente; ímã de faixa forte depois de uma troca; tranco do buraco maior; loops de ronco e chiado; volume da poça; tremor do volante no acostamento; o HI-SCORE não é mais gravado pelos testes. O `tests/test_drive.gd` também foi corrigido: pico do toque e do buraco, `ride` em 3 velocidades, voltas no `full_drive` e visibilidade medida na imagem.

Para checar o que o banco de testes não mede, usei uma **cópia** do projeto no scratchpad. Nenhum arquivo do jogo foi alterado. Rodei:
- (a) motorista sem mãos, com trânsito, por 60 s: sementes 1, 3 e 7, faixas direita e central, cruise em 70 e 100 km/h;
- (b) aproximação de um caminhão a 35 km/h, saindo de 45 a 100 km/h, sem mãos;
- (c) curva mais fechada (força ±3) sem mãos, nas 3 faixas, a 70 e 95 km/h, com e sem um toque curto de correção antes;
- (d) visibilidade do buraco ao entardecer, à noite e de manhã, contando só pixels com diferença de cor > 0,03 e > 0,06;
- (e) as variantes de código sugeridas abaixo, medidas antes de recomendar.

## 1. Nota final: **7,5 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **7,8** | Todas as métricas estão na faixa boa. Resposta de 0,167–0,183 s, faixa em 0,82–0,83 s, overshoot de 0,042–0,050 e assentamento de 1,20–1,32 s (era 3–4 s). O toque tem pico de 0,074–0,075. Na curva força 3 o RMS é 0,126/0,138, com offroad 0. Desconto: o ímã de faixa depende do histórico de teclas. Sem mãos na curva, depois de um toque de correção, o carro escorrega uma faixa inteira ou **sai da pista por 3,6–5,8 s**. Sem o toque, fica a ±0,17 do centro (teste c). |
| 2 | Suspensão e sensação | 20% | **7,8** | O buraco isolado está ideal: 1,5 oscilação e assentamento em 1,68 s. O tranco agora é maior que o balanço da pista: corpo de 9,8–15,8 px e arfagem de 14,7–25,3 px, contra 18,6–19,5 px de arfagem na estrada. Duas ressalvas. A arfagem na estrada é igual nas três velocidades (0,049–0,051 rad), sinal de que o clamp de ±0,035 corta todos os topos: toda lombada parece a mesma. E o buraco quase não puxa o carro de lado (pico de 0,007 da pista). |
| 3 | Pista e desafio | 20% | **6,8** | Densidade de 11,5–12,5 perigos/min, dentro da faixa e agora contada certo. O bot cuidadoso acerta 13% a 70 km/h e 17% a 90 (alvo ≤ 15%). A visibilidade melhorou muito: o buraco é legível até 15.000 unidades, com margem de **1,43 s a 70 km/h e 0,83 s a 95** (alvo ≥ 1,5 s). Também há a placa "PISTA IRREGULAR". A 95 km/h ainda sobra pouco tempo de reação. |
| 4 | Feedback | 15% | **7,4** | O que melhorou: volume do buraco e da poça proporcional à força, loop de ronco e de chiado de pneu, tremor no acostamento, toasts certos ("ESSE PEGOU..." em `cockpit_pothole`). O que falta: o ronco **ignora os trechos ásperos** (`ROUGH`), porque segue só o fator de faixa. Na faixa da esquerda fica mudo. O som de batida tem volume fixo. O respingo na câmera externa ainda são pontinhos no para-choque (`chase_puddle`). |
| 5 | Fluxo relaxante | 10% | **7,4** | Piloto automático com 0 batidas, 1 buraco e 3 poças em 90 s. O laço de batidas sumiu: sem mãos a 70 km/h, 0–1 batida/min (era 16–23). Restam dois problemas. O cruise ainda bate quando a diferença de velocidade passa de ~40 km/h (teste b: 1 batida, "OPA! SEM PRESSA" e o multiplicador zerado sem culpa do jogador). E há a saída de pista sem mãos na curva do item 1, que também zera o multiplicador. |
| 6 | Visual e desempenho | 5% | **7,5** | A pixel art segue coerente e o HI-SCORE está limpo (000.351 = 1P). O resto continua: os reflexos das lanternas parecem duas estacas marrons sob o carro (`chase_drive`, `chase_puddle`, `chase_curve`), a carroceria flutua sobre rodas "de pernas" e o letreiro "…SERRA FM 98…" segue cortado. O render tem 35,4 fps, normal para software. |

Cálculo: 0,30×7,8 + 0,20×7,8 + 0,20×6,8 + 0,15×7,4 + 0,10×7,4 + 0,05×7,5 = 7,485, arredondado para **7,5**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. A 95 km/h o buraco só fica legível 1,66 s antes, e a margem é de 0,83 s (Pista +1,0)
- **Sintoma:** em velocidade de estrada, o jogador vê o buraco, mas sobra menos de 1 s depois de descontar a troca de faixa (0,83 s). Com o tempo de reação humano (~0,3 s), desviar vira reflexo, e não leitura da pista. O bot cuidadoso, que lê os dados 1,6 s à frente, já acerta 17% a 90 km/h.
- **Prova:** `visibility_rendered`: legível (≥ 30 px) até 15.000 unidades nas duas câmeras. A margem é de 1,43 s a 70 km/h e de 0,83 s a 95. No teste d, os mesmos números aparecem com limiar de contraste de 0,03 e de 0,06 e também à noite, então a métrica é honesta. Ela é um pouco otimista por não ter chuva nem gotas no vidro.
- **Onde:** `scripts/world.gd`, `_draw`, segundo laço ("potholes, patches and puddles"), na linha do brilho: `draw_rect(Rect2(f2 - hw * 0.8, hy2, hw * 1.6, 0.5), …)`.
- **Mudança sugerida (testada na cópia):** depois desse `draw_rect`, acrescentar uma faixa de brilho mais larga e mais alta, com menos névoa:
  ```gdscript
  draw_rect(Rect2(f2 - hw * 1.2, hy2 - 0.5, hw * 2.4, 1.0), pud_h.lerp(fog, fa * 0.5))
  ```
  Resultado na cópia (cabine, sem painel, contraste > 0,03): legível até **21.000 unidades**, ao entardecer e à noite. Isso dá 2,33 s de antecedência a 95 km/h (margem **+1,50 s**) e 3,16 s a 70. Visualmente continua um traço de água brilhando, coerente com a pixel art.

  Alternativa, também testada: um galho espetado no buraco, um costume bem de beira de estrada brasileira. É um retângulo marrom de `a_s*900*hh` de altura com um tufo verde. Chega a 25.000 unidades (2,77 s), mas muda o visual e pede um sprite próprio.

### P2. O ímã de faixa muda de força conforme a última tecla, e sem mãos na curva o carro sai da pista (Dirigibilidade +0,4, Fluxo +0,3)
- **Sintoma:** se a última tecla foi uma correção dentro da faixa (`lane == press_lane`), o ímã fica fraco: puxa `vx` com 1,5/s e perde para a força da curva (`curve*sp²*0.16`). O carro escorrega uma faixa inteira e "gruda" na vizinha. Se já está na faixa de fora, vai para o acostamento, onde o ímã se desliga (`absf(px) < 1.02`) e o carro fica lá. Se a última tecla foi uma troca de faixa, ou se não houve tecla, o ímã forte segura o carro. O mesmo gesto dá resultados opostos.
- **Prova (teste c, curva ±3, 8 s sem mãos):**

  | Situação | Sem toque antes | Com toque de 0,07 s antes |
  |---|---|---|
  | Faixa externa | px fica entre 0,49 e 0,84, offroad 0 s | offroad de **4,2 s / 5,8 s** (curva +3) e **3,6 s / 5,3 s** (curva −3) |
  | Faixa central | — | o carro termina na faixa vizinha (−0,58 / +0,67) |
- **Onde:** `scripts/game.gd`, `_process`, bloco `else:` da direção (`press_lane`) e o ímã logo depois de `vx += (steer …)`.
- **Mudança sugerida (testada):** depois de 0,5 s sem tecla, voltar ao modo "segurar o centro da faixa". Declarar `var free_t := 0.0` e, no ramo manual, logo após `press_lane = lane`:
  ```gdscript
  free_t = 0.0 if dir != 0.0 else free_t + dt
  if free_t > 0.5:   # hands off for a while: hold the lane centre again
  	press_lane = -1
  ```
  Na cópia, as 24 combinações do teste c ficam com offroad 0 e o carro termina na própria faixa. Nada mais muda: troca de faixa (0,817–0,833 s; overshoot de 0,042–0,050; assenta em 1,20–1,32 s), pico do toque (0,075 / 0,074), curva (RMS 0,126 / 0,138), `full_drive` e piloto automático. Só `tap.lateral_move_after_2_5s_road` vai a 0, o que é esperado: o toque desloca e depois o carro volta ao centro.

### P3. O cruise ainda bate no caminhão quando a diferença de velocidade passa de ~40 km/h (Fluxo +0,6, Feedback +0,2)
- **Sintoma:** chegando a 75–100 km/h atrás de um caminhão a 35, o cruise começa a ceder a 3.000 unidades seguindo uma rampa linear (`c.v + (dd - 1600) * 0.01`). Essa rampa pede no máximo +14 km/h a 3.000 unidades, mas a desaceleração é limitada a 34 km/h/s e não dá tempo. Vem "OPA! SEM PRESSA", o multiplicador zera e o som de batida toca, sem o jogador ter feito nada.
- **Prova (teste b, caminhão a 35 km/h, sem mãos):**

  | Velocidade inicial | Código atual | Variante |
  |---|---|---|
  | 45 e 60 km/h | 0 batidas | 0 batidas |
  | 75, 90 e 100 km/h | **1 batida** cada (menor distância de 1.229–1.302) | **0 batidas**, para a 1.600 unidades |

  No teste a, com cruise em 100, houve 1 batida em cada uma das 6 corridas. Com a variante, sobra só a da semente 1 na faixa direita, que é artefato do teste: o carro nasce a 1.200 unidades do caminhão. A 70 km/h, a variante também elimina a batida da semente 3.
- **Onde:** `scripts/game.gd`, `_process`, bloco "cruise control yields to the car ahead".
- **Mudança sugerida (testada):** uma curva de frenagem em raiz quadrada e um alcance maior:
  ```gdscript
  if dd > 250.0 and dd < 9000.0:
  	tgt = minf(tgt, c.v + signf(dd - 1600.0) * sqrt(absf(dd - 1600.0) * 0.5))
  ```
  A desaceleração exigida fica em ~24 km/h/s, abaixo do limite de 34. As métricas de direção, `full_drive` e piloto automático não mudam.

### P4. O som não acompanha a pista áspera e o respingo externo é fraco (Feedback +0,6)
- **Sintoma:** o ronco usa `rough`, que é o fator de faixa (0,6 / 1,0 / 1,3 / 1,7), e não `ROUGH[i]` do trecho. Por isso o trecho anunciado por "PISTA IRREGULAR" soa igual à reta lisa. Na faixa da esquerda o volume é `(0.6 - 0.6) * … = 0`, ou seja, −80 dB. O `bump` tem volume fixo. Em `chase_puddle`, o respingo de uma poça a 70 km/h é uma fileira de pontos de 0,5–1 unidade no para-choque.
- **Onde:** `scripts/game.gd`: bloco "audio follows the drive" em `_process`, `_splash`, e o bloco de trânsito (`_sfx("bump")`).
- **Mudança sugerida:**
  - Ronco: `a_rumble.volume_db = linear_to_db(maxf(0.0001, ((rough - 0.6) * 0.04 + ROUGH[base.i] * 0.10) * sp + (0.1 if off else 0.0)))`. No trecho áspero a 70 km/h isso dá ~0,08 (≈ −22 dB, no nível do motor). Na reta lisa da esquerda fica em silêncio.
  - Batida: `sfx["bump"].volume_db = linear_to_db(0.4 + 0.6 * clampf((v - c.v) / 40.0, 0.0, 1.0))`, antes de mudar `v`.
  - Respingo externo: em `_splash`, partículas de tamanho 1–2 (hoje 0,5–1), espalhadas em dois leques laterais (`vx ±(60..140)`) e com vida de 0,4–0,9 s.

### P5. O buraco não puxa o carro de lado (Suspensão +0,3, Feedback +0,2)
- **Sintoma:** o volante dá o tranco visual (`kick`), mas o carro mal se mexe: `pothole.lateral_kick_peak_road` é 0,007 nas três velocidades. O impulso `vx += side * 0.1` é anulado em poucos quadros pelo pneu (9·grip/s) e pelo ímã de faixa. Num carro antigo, buraco de uma roda só puxa a direção.
- **Onde:** `scripts/game.gd`, `_hit_feat`, ramo `f.t == 0`.
- **Mudança sugerida (testada):** trocar `vx += side * 0.1` por:
  ```gdscript
  vx += side * 0.25 * k / 1.45   # the wheel is yanked toward the hole
  aqua = maxf(aqua, 0.2)         # a moment with loose grip and no lane magnet
  ```
  O puxão vai a **0,024 / 0,033 / 0,041** da pista a 40 / 70 / 95 km/h: perceptível, metade de um toque e sem tirar o carro da faixa. Corpo, arfagem, assentamento (1,68 s) e oscilações (1,5) ficam iguais. Efeito colateral bom: o chiado (`aqua * 0.12`) soa um instante, como pneu raspando.

Fora do top 5:
- A arfagem na estrada satura no clamp de ±0,035 (máximo igual a 50, 70 e 95 km/h). Trocar por `0.035 * tanh((sl - slope) / 0.035)` daria topos diferentes sem passar do teto.
- Na câmera externa, os reflexos das lanternas parecem estacas (`world.gd`, `_draw_player`: retângulos de 8k × 18k com alfa 0,22, e o mesmo nos carros). Sugestão: 2–3 faixas finas com alfa decrescente e altura de 10k.
- A carroceria flutua sobre as rodas.
- O letreiro do rádio é cortado (`hud.gd`, `clip_text`). Sugestão: rolagem.
- Um "sign3" (PISTA IRREGULAR) também entra no rodízio comum de placas de `_populate` (k = 3), e pode aparecer longe de qualquer trecho áspero.

## 3. Problemas da própria métrica (descontados ou corrigidos na nota)

- **Quase tudo que apontei na rodada 02 foi corrigido no banco de testes:**
  - pico do toque e do buraco;
  - `ride` em 3 velocidades;
  - contagem de perigos por volta;
  - visibilidade medida na imagem;
  - capturas sem batida;
  - HI-SCORE limpo.
- **`visibility_rendered` esconde o painel e desliga a chuva.** No teste d, a contagem não muda com limiar de contraste (0,03 / 0,06), nem à noite, então os números valem. Faltam as gotas no vidro e os riscos de chuva, que cobrem a faixa do horizonte (y 15–119), por isso a métrica é levemente otimista. A imagem é de 768×432 (2 px por unidade lógica), e não 1600×900. O limiar de 30 px corresponde a uma mancha de ~3×10 px.
- **`tap.lateral_move_after_2_5s_road`** deixa de fazer sentido com um ímã que devolve o carro ao centro (P2). Vale usar só o pico.
- **`ride.pitch_max_screen_px`** cai na faixa boa, mas porque o clamp corta os topos. O `pitch_rms` (0,022–0,027) diz mais.
- **Falta no banco de testes um cenário sem mãos com trânsito e curva.** Os dois maiores problemas de fluxo (P2 e P3) só aparecem nele. Sugiro portar meus testes a, b e c, que estão na cópia: `t/hands.gd` e `t/appr.gd`.
- `full_drive` a 90 km/h teve 1 batida causada pelo próprio bot, ao trocar para uma faixa com carro lento perto. Não descontei do jogo.

## 4. Comparação com a rodada 02

A nota foi de **6,7 para 7,5**. As cinco sugestões entraram e os efeitos medidos bateram com a previsão da cópia.

| Métrica | Rodada 02 | Rodada 03 | Alvo |
|---|---|---|---|
| Assentamento após troca de faixa | 3,1–4,1 s | **1,20–1,32 s** | < 1,5 |
| Overshoot | 0,055–0,070 | 0,042–0,050 | < 0,10 |
| Toque: pico | (não medido) | 0,074–0,075 | 0,05–0,12 |
| Curva força 3: RMS / offroad | 0,128–0,137 / 0 | 0,126–0,138 / 0 | < 0,15 / 0 |
| Buraco: corpo / arfagem | 7–11 / 5–10 px | 9,8–15,8 / 14,7–25,3 px | maior que o balanço |
| Arfagem na estrada (50 / 70 / 95 km/h) | 24,0 / 23,6 / 23,2 px | 19,5 / 18,9 / 18,6 px | 8–25 |
| Buraco legível até | ~3.000–4.000 un. (margem negativa) | **15.000 un.** (+1,43 s a 70, +0,83 s a 95) | ≥ 1,5 s a 95 |
| Perigos/min | ~11,7–15 (corrigido à mão) | 11,5–12,5 | 6–14 |
| Bot: perigos acertados | ~13% | 13% (70) / 17% (90) | ≤ 15% |
| Sem mãos atrás de carro lento (70 km/h) | 16–23 batidas/min | 0–1 | 0 |
| Piloto automático em 90 s | 0 batidas, 1 buraco, 3 poças | igual | — |
| Som de pista | nenhum | ronco por faixa e chiado de pneu | proporcional |
| HI-SCORE nas capturas | poluído | limpo | — |

- **Melhorou:** dirigibilidade (assentamento), proporção do tranco do buraco, visibilidade dos buracos (de margem negativa para quase na faixa a 70), o laço de batidas e o som de pista.
- **Ficou igual:** reflexos-estaca, carroceria flutuante, letreiro cortado, respingo externo fraco.
- **Novos achados:**
  - o ímã de faixa inconsistente (P2), que nasceu do próprio `press_lane` desta rodada;
  - o cruise que ainda bate com diferença de velocidade alta (P3);
  - o ronco que segue a faixa em vez do trecho áspero (P4).
