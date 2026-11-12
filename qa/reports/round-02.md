# Rodada 02: Chuva na BR

Data: 2026-11-12. Fontes:
- `qa/run_qa.sh`: métricas em `qa/metrics/latest.json` e capturas em `qa/shots/`. O renderizador por software rodou a 33,1 fps.
- Leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/cockpit.gd` e `tests/test_drive.gd`.
- Diff contra `qa/snapshots/round-00/scripts/`. Só `game.gd` mudou: as sugestões P1 a P5 da rodada 01 entraram quase ao pé da letra.

Para checar coisas que o banco de testes não mede, usei uma **cópia** do projeto no scratchpad. Nenhum arquivo do jogo foi alterado. Rodei:
- (a) `ride` a 50 e 95 km/h;
- (b) motorista sem mãos, com trânsito, por 60 s (sementes 1, 3 e 7; faixas direita e central);
- (c) capturas com um único buraco a distâncias conhecidas, em pista plana e sem chuva, comparadas pixel a pixel com uma captura sem buraco;
- (d) as variantes de código sugeridas abaixo, para medir o efeito antes de recomendar.

## 1. Nota final: **6,7 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **7,3** | Quase tudo está na faixa boa: resposta de 0,167–0,183 s, faixa em 0,83–0,85 s e overshoot de 0,055–0,070. Na curva força 3 o RMS é 0,128/0,137, com offroad de 0 s. O toque move 0,049–0,051, mas medido no fim e já corroído pelo ímã; o pico é maior. O que falta: o assentamento leva 3,1–4,1 s (alvo < 1,5), porque o ímã de faixa é fraco e superamortecido. Na curva o erro máximo ainda chega a 0,31, quase meia faixa. |
| 2 | Suspensão e sensação | 20% | **7,2** | O buraco isolado está ideal: 1,5 oscilação e assentamento em 1,68 s. A arfagem na estrada é de 23,6 px a 70 km/h e de 24,0 e 23,2 px a 50 e 95 km/h (cópia), dentro da faixa mas encostada no teto. O body_rms sobe para 33 a 95 km/h. O problema agora é de proporção: o tranco do buraco (corpo 7–11 px, arfagem 0,013–0,025 rad, ou 5–10 px) é **menor** que o balanço comum da pista (24 px). O "EITA, BURACO!" chega mais forte no texto do que no corpo do carro. |
| 3 | Pista e desafio | 20% | **5,0** | A densidade caiu para a faixa (contagem correta de ~11,7/min a 70 e ~15/min a 90), e o bot cuidadoso acerta ~13%. Mas o buraco **não é visível a tempo**. Na cabine ele só aparece a ~3.000–4.000 unidades, como uma fresta de 1–2 px de altura: 0,45–0,6 s de antecedência a 70 km/h e 0,33–0,44 s a 95, contra 0,83 s para trocar de faixa. A margem real é **negativa**, e a métrica `visibility` (2,4–3,5 s) está errada (seção 3). Desviar de buraco vira sorte, e não "dirigir bem". |
| 4 | Feedback | 15% | **6,8** | Agora o volume do som de buraco acompanha a força (`_hit_feat`). Continuam fixos o `splash` e o `bump`. Não há som de pista áspera, de acostamento (rough 1,7) nem de pneu na curva ou na aquaplanagem. O respingo na câmera externa melhorou pouco: pontinhos brancos em `chase_puddle.png`. O tranco visual do buraco é fraco (ver Suspensão). |
| 5 | Fluxo relaxante | 10% | **6,5** | O piloto automático está ótimo: 0 batidas, 1 buraco e 3 poças em 90 s. No modo manual, porém, quem fica atrás de um carro mais lento **bate de 16 a 23 vezes por minuto**: o cruise reacelera, vem "OPA! SEM PRESSA", o multiplicador zera, e repete (teste b). As capturas da cabine mostram justamente isso ("OPA! SEM PRESSA" com o caminhão colado). É uma punição em laço, contra a proposta do jogo. |
| 6 | Visual e desempenho | 5% | **7,5** | A pixel art continua coerente e bonita. O que piorou e o que segue igual: 33 fps, normal para o software. Os reflexos das lanternas ainda parecem duas estacas marrons sob o carro e sob o caminhão (`chase_drive`, `chase_lane_change`). As rodas aparecem "de pernas" sob a carroceria. O letreiro "TOCANDO: … SERRA FM 98…" aparece cortado. O HI-SCORE 054.818 ainda vem dos testes. |

Cálculo: 0,30×7,3 + 0,20×7,2 + 0,20×5,0 + 0,15×6,8 + 0,10×6,5 + 0,05×7,5 = 6,675, arredondado para **6,7**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. Buracos invisíveis até ~0,5 s antes do impacto (Pista +2,5, Feedback +0,5)
- **Sintoma:** o jogador não consegue ver o buraco a tempo de trocar de faixa. Num trecho plano ele surge como uma linha escura de 1 px a ~4.000 unidades. Antes disso não existe na tela.
- **Prova (teste c, buraco w = 0,09 na faixa direita, pixels alterados contra a captura sem buraco):**

  | Câmera | 3.000 | 4.000 | 5.000 | 6.000 a 26.000 |
  |---|---|---|---|---|
  | Cabine | 67 px | 23 px | 0 | 0 |
  | Externa | 37 px | 16 px | 0 | 0 |

  Com a troca de faixa em 0,83 s, a margem é de −0,25 a −0,4 s a 70 km/h e de −0,4 a −0,5 s a 95 km/h. Alvo: ≥ +1,5 s.
- **Causa (`scripts/world.gd`, `_draw`, laço "road, front to back"):** a pista é desenhada da frente para trás. O retângulo de grama/pista do segmento seguinte, `draw_rect(Rect2(X0, bsy, XW, hgt))` com `hgt = asy - bsy + 0.5`, e o retângulo de névoa (`fa`) pintam por cima o pixel superior do segmento anterior. Ao longe, um segmento tem menos de 1 px de altura (≈ 77.146·200/z² unidades lógicas), e o buraco desenhado dentro dele é apagado. As poças sofrem o mesmo corte.
- **Mudança sugerida (testada na cópia):**
  1. No primeiro laço, guardar `[sg, hgt, fa]` dos segmentos com `feat` e desenhar os buracos e poças num segundo laço, de trás para frente, depois do laço da pista. As cores devem ir `lerp(fog, fa * 0.6)`.
  2. Dar ao buraco altura mínima de 1 unidade lógica (2 px reais): `var ty := minf(sg.b_sy, asy - 1.0)`.
  3. Aumentar a largura desenhada em ×1,3.

  Resultado medido na cabine: 118 / 56 / 44 / 39 / 35 / 31 / 21 / 17 / 14 px a 3k / 4k / 5k / 6k / 7k / 9k / 12k / 16k / 20k. O buraco fica legível (≥ 30 px) até ~9.000–12.000 unidades, com margem de +0,5 a +1,0 s a 70 km/h.

  Para chegar a 1,5 s a 95 km/h (≈ 21.000 unidades), falta uma pista extra:
  - um brilho molhado no buraco (1 px de `pud_h` na borda de trás);
  - ou uma placa "PISTA IRREGULAR" (`_add_spr`) 40 segmentos antes de cada trecho com `ROUGH > 0.25`.

### P2. Batida em laço atrás de carro lento no modo manual (Fluxo +2,0, Feedback +0,3)
- **Sintoma:** sem trocar de faixa, o carro reacelera até o da frente, leva "OPA! SEM PRESSA", perde o multiplicador e volta a acelerar, a cada ~3 s.
- **Prova:** teste b, 60 s sem mãos.

  | Semente | Faixa direita | Faixa central |
  |---|---|---|
  | 1 | 23 batidas | 7 batidas |
  | 3 | 20 batidas | 0 batidas |
  | 7 | 16 batidas | 19 batidas |

  As capturas `cockpit_drive` e `cockpit_pothole` mostram o caminhão colado no para-brisa com o toast.
- **Onde:** `scripts/game.gd`, `_process`. O bloco de velocidade (`v += clampf(tgt - v, ...)`) ignora o trânsito. Só o bloco de trânsito (`if d < 1250.0 and d > 250.0 and dxl < 0.46 and v > c.v`) segura o carro, e faz isso com punição.
- **Mudança sugerida (testada):** um cruise que cede, logo antes de `var v0 := v`:
  ```gdscript
  if started and not auto:
  	for c in cars:
  		if c.dir > 0 and absf(c.x - px) < 0.46:
  			var d := fposmod(c.z - pos, TRACK)
  			if d > 250.0 and d < 3000.0:
  				tgt = minf(tgt, c.v + (d - 1600.0) * 0.01)
  ```
  Com isso, as batidas caem de 16–23/min para **0–1/min** nas mesmas sementes. O toast e a perda do multiplicador ficam só para quem joga o carro em cima de outro de propósito.

### P3. O carro leva 3–4 s para assentar no centro da faixa (Dirigibilidade +0,8)
- **Sintoma:** depois de uma troca de faixa, o carro para a ~0,05–0,07 do centro e vai escorregando devagar até lá.
- **Prova:** `lane_change.settle_s` de 3,13 / 3,07 / 4,07 s (alvo < 1,5).
  - O ímã atual, `vx += (LANES[lane] - px) * 1.5 * dt`, compete com o pneu, que puxa `vx` para 0 a 9·grip/s. A constante de tempo efetiva fica em ≈ 9·grip/1,5 ≈ 5 s.
  - Subir o ganho não resolve. Com 4,0 o assentamento vai a 1,9–2,3 s, com 8,0 a 1,7–2,0 s, e o toque cai para 0,02 e 0,005, matando o controle fino.
- **Onde:** `scripts/game.gd`, `_process`, logo após o cálculo de `vx` (linhas 615–616).
- **Mudança sugerida (testada):**
  - Aplicar o ímã só quando houve troca de faixa. Gravar `press_lane = lane` no quadro em que `dir` passa de 0 para ≠ 0. Ao soltar, se `lane != press_lane`, usar `px += (LANES[lane] - px) * minf(1.0, 2.5 * dt)`. Senão, manter o ímã fraco atual.
  - Resultado: assenta em **1,23 / 1,32 s**, overshoot de 0,042 / 0,050 e toque intacto (0,051 / 0,049). A curva fica igual (RMS 0,126 / 0,138, offroad 0).

### P4. O buraco mexe menos o carro que a ondulação comum (Suspensão +1,0, Feedback +0,3)
- **Sintoma:** o horizonte balança 24 px só com a pista. Já o buraco dá um tranco de corpo de 7–11 px, com arfagem de 5–10 px. O evento mais importante da viagem se perde no balanço de fundo.
- **Prova:**
  - `pothole.body_peak_screen_px` de 7,1 / 9,4 / 11,4 e `pitch_peak_rad` de 0,013 / 0,020 / 0,025 (×380 dá 4,9 / 7,6 / 9,5 px).
  - `ride.pitch_max_screen_px` de 23,6 (24,0 a 50 km/h e 23,2 a 95 na cópia).
- **Onde:** `scripts/game.gd`, `_hit_feat` (`zb_v += 360.0 * k`, `pitch_v += 0.3 * k`), e `_process` (`clampf(sl - slope, -0.045, 0.045)`).
- **Mudança sugerida (testada):**
  - `zb_v += 500.0 * k`.
  - `pitch_v += 0.7 * k` (testei 0,8).
  - Clamp de `pt` em ±0,035.

  Com 0,8, o tranco do buraco vai a 9,8–15,8 px de corpo mais 17–29 px de arfagem. O balanço da pista cai para 18,6–19,5 px nas três velocidades, no meio da faixa 8–25. O assentamento (1,68 s) e as oscilações (1,5) não mudam. Com 0,7, a arfagem do buraco fica em ~15–26 px.

### P5. O som não acompanha a pista (Feedback +1,0)
- **Sintoma:** acostamento, trecho áspero (`ROUGH`), poça funda e curva forte soam iguais à reta lisa. Só existem motor, chuva e os SFX pontuais.
- **Prova:** `_sfx("splash")` e `_sfx("bump")` sempre no mesmo volume. Não há player de ruído de pista. `rough` (0,6 / 1,0 / 1,3 / 1,7) só afeta `zr`.
- **Onde:** `scripts/game.gd`, `_init_audio`, `_hit_feat` (poça) e o bloco "audio follows the drive" em `_process`.
- **Mudança sugerida:**
  - Volume da poça: `sfx["splash"].volume_db = linear_to_db(0.4 + 0.6 * sp)`.
  - Um loop de rumble/cascalho com `volume_db = linear_to_db(maxf(0.0001, (rough - 0.6) * 0.08 * sp + (0.1 if off else 0.0)))` e pitch 0,8 + 0,4·sp.
  - Um chiado de pneu molhado proporcional a `absf(curve * sp * sp) + aqua`.
  - Um tremor leve no volante no acostamento: `kick += randf_range(-0.05, 0.05)` quando `off`.

## 3. Problemas da própria métrica (descontados ou corrigidos na nota)

- **`visibility` está muito otimista e é o erro mais grave do banco de testes.** O cálculo usa só a largura do buraco (4 px reais → 29.030 unidades). Ignora a altura do segmento na tela, que é menor que 1 px além de ~5.500 unidades na cabine. Ignora também a sobreposição de desenho do P1 e a névoa. Medindo pixels na captura, o buraco aparece só a 3.000–4.000 unidades. Sugestão: o teste deve renderizar um buraco a distâncias crescentes e contar pixels contra uma captura de referência, como fiz no teste c, mesmo que só no modo `--shots`. A nota de Pista usa a medição real.
- **`full_drive.hazards_per_min` continua contando só uma volta.** `counted` usa o índice do segmento sem número de volta, então os 18 perigos são o total de uma volta (9,0/min é 18/2). Com volta de 92,6 s a 70 km/h e 72 s a 90 km/h, o real é ~11,7 e ~15/min. Sugestão: chave `si + volta*N`, ou somar sem deduplicar.
- **O bot cuidadoso lê os dados, não a tela.** Ele vê 1,6 s à frente, um horizonte que um humano não tem (P1). Os ~13% de acerto valem como teto de qualidade da geração, não como dificuldade real.
- **`tap.lateral_move_road` é medido 2,5 s depois do toque**, quando o ímã de faixa já devolveu parte do movimento (`peak_vx` de 0,38 / 0,35 é calculado e descartado). O deslocamento real é maior que 0,05. Sugestão: reportar o pico de |px − px0|.
- **`pothole.speed_lost_kmh` e `lateral_kick_road` são lidos no fim dos 6 s**, depois que o cruise e o ímã já corrigiram tudo. Por isso dão 0 e 0,004. Sugestão: registrar o pico.
- **`ride` só roda a 70 km/h.** Rodei 50 e 95 na cópia (24,0 e 23,2 px; body_rms de 18,6 e 33,0). Vale incluir no teste.
- **As capturas `--shots-only` saem pouco representativas.** `place(60, 0.667, 70)` põe o carro atrás do caminhão sem ninguém dirigindo, então `cockpit_drive` e `cockpit_pothole` sempre mostram a batida. E o teste grava `user://hiscore.txt`, poluindo o HI-SCORE das capturas.
- **Corrigido desde a rodada 01:** o `pothole` agora zera `Y`, então `settle_s` = 1,683 é limpo. O contador de oscilações usa histerese e dá 1,5, coerente com a física.

## 4. Comparação com a rodada 01

A nota foi de **4,7 para 6,7**. Todas as cinco sugestões da rodada 01 entraram, e a simulação prevista bateu com o medido.

| Métrica | Rodada 01 | Rodada 02 | Alvo |
|---|---|---|---|
| Resposta da direção | 0,233–0,25 s | 0,167–0,183 s | 0,10–0,20 |
| Overshoot | 0,438–0,46 | 0,055–0,070 | < 0,10 |
| Assentamento | nunca (−1) | 3,1–4,1 s | < 1,5 (ainda fora, P3) |
| Curva força 3: offroad | 1,65 / 1,98 s | 0 / 0 s | 0 |
| Curva força 3: RMS | 0,33 / 0,36 | 0,128 / 0,137 | < 0,15 |
| Toque | 0,105 | 0,049–0,051 | 0,05–0,12 (no limite, mas a métrica subestima) |
| Arfagem na estrada | 45,6 px (saturada) | 23,6 px | 8–25 |
| Perigos/min (corrigido) | ~40–52 | ~11,7–15 | 6–14 |
| Bot: trocas de faixa em 2 min | 31 / 51 | 10 / 17 | — |
| Bot: buracos acertados | 9 / 12 | 2 / 1 | — |
| Piloto automático em 90 s | 1 batida, 12 buracos, 3 poças | 0 batidas, 1 buraco, 3 poças | 0 batidas, poucos buracos |
| Volume do som de buraco | fixo | proporcional à força | — |

**Igual:**
- Os reflexos de lanterna parecem estacas, e a carroceria "flutua" na câmera externa.
- O som de poça e batida segue fixo. Não há som de pista.
- O HI-SCORE ainda é poluído pelos testes.
- O valor de 33 fps contra 39 na rodada 01 é ruído do renderizador por software, não regressão.

**Novos achados (já existiam no código, mas não tinham sido medidos):**
- A visibilidade real dos buracos (P1) é o novo gargalo: com menos buracos, cada um que o jogador não consegue ver pesa mais.
- O laço de batidas no modo manual (P2).
- A desproporção entre o tranco do buraco e o balanço da pista (P4). Ela apareceu porque a arfagem da pista deixou de mascarar tudo.
