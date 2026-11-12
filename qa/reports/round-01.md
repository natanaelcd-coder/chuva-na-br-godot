# Rodada 01: Chuva na BR

Data: 2026-11-12. Fonte: `qa/run_qa.sh` (métricas em `qa/metrics/latest.json`, capturas em `qa/shots/`, 39,3 fps no renderizador por software), leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/cockpit.gd`, `scripts/hud.gd` e `tests/test_drive.gd`. Para separar defeito do jogo de defeito da métrica, reproduzi a física de `game.gd` num script à parte (mesmas constantes, dt = 1/60). A reprodução bate com o JSON: troca de faixa 0,233 s / 0,883 s / overshoot 0,438; ride body_rms 44,0; pothole a 40 km/h com pico de 33,8 e assentamento em 1,68 s.

## 1. Nota final: **4,7 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **3,8** | O toque está bom (0,105 em 0,15 s) e a troca de faixa leva 0,88–0,92 s, mas a resposta é lenta (0,233–0,25 s, alvo ≤ 0,20). O overshoot é de 0,44–0,46 da pista, 4,5× o limite e quase 2/3 de uma faixa. Na curva mais fechada (força 3) o carro sai da pista por 1,65–1,98 s, com RMS de 0,33–0,36 (alvo 0 s e < 0,15). |
| 2 | Suspensão e sensação | 20% | **5,0** | O buraco isolado está na faixa: assenta em ~1,7 s com ~2 oscilações visíveis. Na estrada, porém, a arfagem chega a 45,6 px (alvo 8–25) e encosta no limite de 0,12 rad. A 95 km/h as ondulações da pista excitam a mola na ressonância: o corpo vai a 178 de 240 unidades só com a pista, sem buraco. |
| 3 | Pista e desafio | 20% | **3,5** | Há cerca de 40 perigos/min a 70 km/h e 52/min a 90 km/h. A métrica mostra 31,5, mas conta só uma volta (ver seção 3). O alvo é 6–14. O bot cuidadoso precisa de 31–51 trocas de faixa em 2 min e ainda acerta 9–12 buracos (~11–19%). Nada disso é relaxante. |
| 4 | Feedback | 15% | **6,5** | Todo evento tem resposta visual e sonora: toast, dado, cachorrinho, volante com kick, gotas no vidro e respingo. Mas o som não acompanha a força do impacto (`_sfx` toca tudo no mesmo volume). Falta som de pista áspera, de acostamento e de pneu na curva. O respingo na câmera externa é quase invisível (`chase_puddle.png`). |
| 5 | Fluxo relaxante | 10% | **5,0** | Não há game over e as punições são leves. Mas o piloto automático bate 1 vez e pega 12 buracos e 3 poças em 90 s: um "EITA, BURACO!" a cada ~7 s, justo no modo "só curta a viagem". |
| 6 | Visual e desempenho | 5% | **7,5** | A pixel art é coerente e bonita: cabine, chuva, hora do dia, postes com fios. Os 39 fps são normais neste teste. Na câmera externa a carroceria flutua solta acima das rodas, e os reflexos das lanternas parecem duas estacas marrons sob o carro (`chase_drive.png`, `chase_curve.png`). O HI-SCORE 035.155 vem dos testes gravando em `user://hiscore.txt`. |

Cálculo: 0,30×3,8 + 0,20×5,0 + 0,20×3,5 + 0,15×6,5 + 0,10×5,0 + 0,05×7,5 = 4,69, arredondado para **4,7**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. Direção com atraso em cadeia e overshoot enorme (Dirigibilidade, ganho estimado de +2,5 na categoria)
- **Sintoma:** ao soltar a tecla perto do centro da faixa, o carro ainda anda mais de meia faixa. Não existe retorno ao centro, então ele para onde a inércia o deixa e o jogador precisa sempre contra-esterçar.
- **Prova:** `lane_change`: overshoot 0,438 / 0,438 / 0,46 (alvo < 0,10), resposta 0,233–0,25 s (alvo 0,10–0,20) e `settle_s` = -1. Esse -1 é consequência do overshoot somado à falta de centralização, não de um defeito da métrica. O bot solta em px ≤ 0,1, e daí a caixa de direção leva 0,28 s para voltar de 1 a 0 (taxa 3,6/s). Mais ~0,33 s de constante de tempo do pneu (`3,6·grip`, grip ≈ 0,83 na chuva) e vx ainda vale ~1,3 no momento em que se solta a tecla.
- **Onde:** `scripts/game.gd`, `_process`, linhas 567 (`steer += clampf(dir - steer, -dt * 3.6, dt * 3.6)`) e 572 (`vx += (steer * 1.3 * ... - vx) * minf(1.0, dt * 3.6 * grip)`).
- **Mudança sugerida:**
  - Taxa assimétrica no volante, com ataque de 5,0/s e retorno de 12,0/s: `var rate := 5.0 if absf(dir) > absf(steer) else 12.0`.
  - Pneu de 3,6 para 9,0 (`dt * 9.0 * grip`).
  - Ganho lateral de 1,3 para 1,0.
  - Na simulação isso dá resposta de 0,167–0,183 s, faixa em 0,83–0,85 s, overshoot de 0,058 / 0,058 / 0,075 (0,075 a 95 km/h com chuva máxima) e toque de 0,08. Tudo na faixa boa.
  - Opcional: um ímã de faixa fraco quando nenhuma tecla está apertada (`vx += (LANES[lane] - px) * 1.5 * dt` com |dir| = 0), para que `settle_s` deixe de ser -1.

### P2. A força da curva empurra demais para fora (Dirigibilidade, ganho de +1,5 na categoria, somado ao P1)
- **Sintoma:** na curva mais fechada o carro escapa para o acostamento mesmo com o jogador corrigindo, e sai de novo na saída da curva, quando o empurrão some e a correção ainda está aplicada.
- **Prova:** `curve_follow` com curva 3,0: offroad de 1,65 s a 70 km/h e 1,98 s a 95 km/h; RMS de 0,329 / 0,355; erro máximo de 0,70 / 0,82. O empurrão é `curve·sp²·0,26` = 0,38/s a 70 km/h e 0,70/s a 95 km/h, ou seja, 54% e 100% da autoridade lateral se o ganho cair para 1,0. O bot é de teclado liga/desliga com zona morta de 0,05 e atraso de 0,15 s. É duro, mas representa bem um jogador de teclado.
- **Onde:** `scripts/game.gd`, `_process`, linha 573 (`curve * sp * sp * dt * 0.26`).
- **Mudança sugerida:** de 0,26 para 0,16. Na simulação, junto com o P1, dá RMS de 0,130 / 0,137, erro máximo de 0,27 / 0,30 e **offroad 0 s** nas duas velocidades. Só o P1, sem mexer aqui, ainda deixa 0,68 s fora da pista a 95 km/h. Ajustar `lat` e `wheel_a` (linhas 581 e 583) na mesma proporção, para o volante não mostrar uma força que já não existe.

### P3. Densidade de buracos ~3× acima do alvo, em rajadas (Pista e Fluxo, ganho de +3 em Pista e +1 em Fluxo)
- **Sintoma:** nas zonas ásperas há um buraco a cada ~25 segmentos (~0,75 s a 70 km/h). O jogador vira um slalom contínuo, o oposto de "sem pressa".
- **Prova:** a geração rende ~50,6 buracos e ~12 grupos de poças por volta. Isso dá ≈ 40 perigos/min a 70 km/h e ≈ 52/min a 90 km/h (alvo 6–14). O bot cuidadoso fez 31 e 51 trocas de faixa em 2 min (15–25 por minuto) e ainda acertou 9 e 12 buracos.
- **Onde:** `scripts/game.gd`, `_build_surface`, linha 270 (`randf() < 0.005 + ROUGH[i] * 0.035`) e linha 274 (poças com `randf() < 0.55`).
- **Mudança sugerida:**
  - Buracos: `0.001 + ROUGH[i] * 0.008`, cerca de 11 por volta.
  - Poças: 0,55 → 0,2, cerca de 4 grupos.
  - Resultado esperado: ≈ 10 perigos/min a 70 km/h e ≈ 13,5 a 95 km/h.
  - Impor espaçamento mínimo de 12 segmentos entre buracos.
  - Nunca bloquear as 3 faixas na mesma janela de ~20 segmentos.

### P4. Ondulações da pista em ressonância com a mola e arfagem saturada (Suspensão, ganho de +2,5 na categoria)
- **Sintoma:** em reta lisa o carro "nada", com o horizonte subindo e descendo 45 px. A 95 km/h o corpo entra em ressonância. Os buracos se perdem nesse balanço, e a viagem enjoa.
- **Prova:**
  - `ride`: `pitch_max_screen_px` 45,6 (alvo 8–25), `pitch_max_rad` 0,12, que é exatamente o clamp; `body_rms` 44.
  - Comprimento de onda de `sin(a*78)`: N/78 = 39,5 segmentos = 7.900 unidades. Isso excita o corpo a 0,84 Hz a 70 km/h e 1,14 Hz a 95 km/h. A mola tem 1,08 Hz (√46/2π) com ζ = 0,22: ressonância.
  - O `pothole` a 95 km/h tem pico de 178 mesmo sem o buraco: na simulação, só a pista já dá 178,4.
- **Onde:** `scripts/game.gd`, `_build_surface`, linha 263 (`95.0 * sin(a * 78.0)`), e `_process`, linhas 622–623 (clamp de `pt` ±0,08 e amortecimento de arfagem 3,2).
- **Mudança sugerida:**
  - Trocar para `70.0 * sin(a * 40.0)`: excitação de 0,43–0,59 Hz, longe da mola.
  - Clamp de `pt` de ±0,08 para ±0,045.
  - Amortecimento da arfagem de 3,2 para 6,0.
  - Na simulação: arfagem máxima de 23–24 px em 50/70/95 km/h e body_rms de 21,6 a 70 km/h.
  - Manter a mola vertical em 46/3,0 (no máximo 3,5). O buraco isolado já está bom (1,7 s, ~2 oscilações). Com 5,0 ele assentaria em 0,9 s e ficaria "duro".

### P5. O piloto automático ignora buracos (Fluxo, ganho de +2 na categoria)
- **Sintoma:** o modo "PILOTO AUTOMÁTICO: SÓ CURTA A VIAGEM" acerta buraco a cada ~7 s, com toast, pancada e perda de "direção suave". Ainda bate em carro (1 vez em 90 s).
- **Prova:** `autopilot`: 12 buracos, 3 poças e 1 batida em 90 s (alvo: 0 batidas e poucos buracos).
- **Onde:** `scripts/game.gd`, `_process`, linhas 550–564 (lógica de `is_auto`, que só olha `_lane_busy`) e `_lane_busy` (linha 505). Hoje a batida acontece porque a troca de faixa só é avaliada com |px − faixa| < 0,15, e a zona de colisão é d < 1250.
- **Mudança sugerida:**
  - Dar ao automático o mesmo olhar à frente do bot de teste: soma de 1/k dos buracos (t = 0) e poças nos próximos ~1,6 s por faixa. Trocar de faixa se a vizinha tiver menos da metade do perigo e estiver livre.
  - Começar a frear para o carro da frente em d < 2500 (e não só trocar de faixa).
  - De quebra: tocar `hole` e `splash` com `volume_db = linear_to_db(0.35 + 0.65 * clampf(k / 1.45, 0, 1))` em `_hit_feat` (linhas 491 e 503), para o som acompanhar a força (Feedback).

## 3. Problemas da própria métrica (descontados na nota, não punidos)

- **`pothole.oscillations` está sempre 0.** O contador em `tests/test_drive.gd:224` exige `|amostra anterior| > 10% do pico` exatamente no cruzamento do zero, o que quase nunca acontece. Pela física (ζ = 0,22, queda de 0,49 por meio ciclo) e pela minha simulação, são ~2 oscilações visíveis, dentro da faixa. Sugestão: contar picos acima de 10% do pico ou cruzamentos com histerese.
- **`pothole.settle_s` = 6,0 a 70 e 95 km/h é contaminação.** Em `longest_straight()` não há ondulação no começo (zona = 0), mas a 70–95 km/h os 6 s de medição passam da reta de 320 segmentos e entram em trecho ondulado. Isolando o buraco (com buraco menos sem buraco), o assentamento é 1,68 s em todas as velocidades. Sugestão: medir a diferença contra uma corrida de referência sem buraco, ou zerar `Y` no teste.
- **`full_drive.hazards_per_min` subconta.** `counted` usa o índice do segmento sem número de volta, então cada perigo é contado uma vez só. 63 é o total de uma volta, não o que passou em 2 min (70 km/h dá 1,3 volta; 90 km/h, 1,7). O valor real fica entre ~40 e ~52/min. Também conta poças em qualquer faixa e conta poças, mas a porcentagem de acerto usa só buracos.
- **`visibility` ignora a neblina.** A distância de leitura de 29.030 unidades cai no segmento ~145 de 150, onde a névoa de `world.gd:221` tem alfa ≈ 0,87. Com névoa < 0,5 (segmento ~102, cerca de 20.500 unidades), a margem a 95 km/h seria ~1,35 s, abaixo de 1,5. Considerei a visibilidade "no limite", não "folgada".
- **`lane_change.settle_s` = -1** é real (consequência do overshoot), mas a definição pressupõe algum retorno ao centro que o jogo não tem. Se o P1 entrar sem o ímã de faixa, essa métrica continuará -1 mesmo com overshoot de 0,06. Nesse caso, avaliar pelo overshoot.

## 4. Comparação com a rodada anterior

Primeira rodada, sem base de comparação.
