# Rodada 09: Chuva na BR

Data: 2026-11-13.

## Fontes

- `qa/run_qa.sh`, rodado sozinho, sem nenhum outro processo em paralelo: métricas em `qa/metrics/latest.json`, 6 capturas em `qa/shots/` (todas olhadas), `fps.txt` (**30,6 fps**) e `visibility.json`.
- Leitura de `scripts/game.gd` (`_process`, `_hit_feat`, `_build_surface`, `road_y`, piloto automático, trânsito, câmbio, áudio), `scripts/hud.gd`, e por cima `world.gd`/`cockpit.gd` (sem mudança desde a rodada 08), e `tests/test_drive.gd`.

### O que mudou desde a rodada 08

Comparei com `qa/snapshots/round-08/`. Mudaram `game.gd`, `hud.gd` e a fonte (`PressStart2P.ttf` → `Estrada2P.ttf`). `world.gd`, `cockpit.gd`, shaders, `main.tscn` e `tests/test_drive.gd` estão iguais.

- **P1 (freio fantasma):** o `px_soon` saiu. O cruise só olha `absf(c.x - px) < 0.46` e, com `auto`, a faixa-alvo.
- **P2 (guard-rail):** `off := px > 1.02` (o lado do canteiro não é mais "fora da pista"); o ímã de faixa funciona com `px < 1.02`; o raspão custa **um degrau** do multiplicador; e há um arrasto `v -= 12·dt` com `px <= -1.04`.
- **P3 (tolerância):** `off_t` acumula o tempo fora; o limite de 30 km/h e o `clean = 0` só valem com `off_t > 0.4`.
- **P4 (marchas):** câmbio com estado (`gear_i`), sobe 8 km/h antes em velocidade constante (`|Δv/dt| < 2`), troca só depois de 0,5 s de candidato estável (ou na hora, se sair da faixa da marcha). O HUD usa a mesma marcha do motor.
- **P5 (acentos):** fonte nova `Estrada2P.ttf` (656 glifos), com as maiúsculas acentuadas na altura cheia e o acento acima da célula (até 1375/1000).
- **Fora do top 5 (sugestão da rodada 08):** buraco no centro, `absf(d) < 0.06`, agora conta como "duas rodas" (×1,3). Ver P3: essa sugestão da rodada 08 estava errada.

### Testes extras na minha cópia

Tudo em cópias no meu diretório temporário (`scratchpad/c9` = jogo atual, `c9B` = sem a regra do centro, `c9G` = correções de câmbio e guard-rail). Nenhum arquivo do jogo foi alterado. Sonda `c9/tests/q9.gd` (herda o banco):
- (a) Câmbio: seguir um carro a 45/50/56 km/h por 30 s; buraco a 48 km/h; 0→100 km/h; piloto automático (sementes 2 e 3, 120 s); faixa do meio com trânsito, manual, 120 s. Conta trocas, subidas e "caça" (desce e sobe em < 1,5 s).
- (b) Guard-rail: volante segurado para a esquerda por 4 s a 50 e 95 km/h, depois solto 3 s.
- (c) `curve_follow` com reação de 0,15/0,25/0,30 s a 70 e 95 km/h, começando em x4.
- (d) `full_drive` a 70/90/100 km/h e piloto automático 8 sementes × 120 s, no atual e no `c9B`.
- (e) Buraco de largura 0,07/0,09/0,12 exatamente sob o centro do carro, jogador no meio da faixa.
- (f) Renderização ampliada de "TOCANDO: ZÉ DA BALSA - ÚLTIMO PEDÁGIO - SÓ" (8 px) e "DIREÇÃO SUAVE ÁÉÍÓÚ ÇÃÕ" (16 px).

## 1. Nota final: **8,6 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **8,6** | Números do banco idênticos aos da rodada 08 e todos na faixa: resposta 0,167 s; troca de faixa 0,80–0,82 s, overshoot 0,042–0,050, assenta 1,18–1,30 s; toque 0,094–0,095; curva força 3 com RMS 0,122/0,133 e offroad 0; desvio dentro da faixa 6/6 a 70 e 95 km/h. O freio fantasma saiu (o `px_soon` foi removido). Com 0,25 s de reação a 70 km/h o x4 agora sobrevive (0,23 s fora). Desconto: a 95 km/h com 0,25 s de reação, 0,48 s fora ainda leva x4 → x1 (P4), e o meio da faixa deixou de ser um lugar seguro para passar sobre buraco pequeno (P3). |
| 2 | Suspensão e sensação | 20% | **8,5** | Sem mudança no corpo: 8,8 / 11,8 / 14,2 px; arfagem 13,0 / 18,2 / 22,5 px no buraco e 14,0 / 16,0 / 18,8 px na estrada; 1,5 oscilação. Descontos: assentamento ainda sempre 1,683 s; o câmbio novo dá um **tranco de subida de marcha extra** a cada desaceleração para 44–52 km/h e a cada buraco nessa faixa (P1). |
| 3 | Pista e desafio | 20% | **8,5** | 9,0 / 10,5 / 13,0 perigos/min a 70/90/100 km/h (na faixa). Bot cuidadoso: 0/18, **1/21** (era 0) e 3/26 (11,5%). Margem com chuva 1,67 s a 95 km/h (≥ 1,5). Desconto: o buraco que acerta o bot a 90 km/h só existe pela regra nova do centro; passar o buraco entre as rodas, o gesto de quem dirige bem em estrada ruim, ficou impossível (P3). |
| 4 | Feedback | 15% | **8,7** | Melhorou: a marcha do HUD bate com o som; em velocidade constante a 45–52 km/h o motor vai para 4ª (0,90×, antes 1,19–1,35×); o rail custa só um degrau e devolve o carro à faixa. Descontos: caça de marcha com tranco ao frear atrás de carro ou cair num buraco a 44–52 km/h (P1); seguir no rail é **silencioso** depois do primeiro raspão e o arrasto não freia (P2); motor travado em 0,90× entre 44 e 52 km/h (P5). |
| 5 | Fluxo relaxante | 10% | **8,8** | Piloto automático sem batidas (banco: 0 em 4 × 90 s; minha sonda: 0 em 8 × 120 s, 14 buracos e 8 poças). O freio fantasma sumiu, o rail não zera mais o multiplicador e um instante fora da borda direita não custa o x4. Descontos: o tudo-ou-nada a 95 km/h na curva (P4) e o arrasto inútil no rail (P2). |
| 6 | Visual e desempenho | 5% | **8,6** | Os acentos estão resolvidos: "CÂMERA EXTERNA" (`chase_drive`), "VOCÊ NO VOLANTE" (`chase_lane_change`), "PILOTO AUTOMÁTICO: SÓ…" (`cockpit_drive`) com maiúsculas de altura cheia; no rodapé de 8 px os acentos de "ZÉ", "ÚLTIMO", "PEDÁGIO", "SÓ" não são cortados (teste f). Descontos: o til de Ã/Õ é um zigue-zague assimétrico (`.##.#` / `...#.#`) que a 16 px com sombra lê quase como trema; pneus em blocos na câmera externa; 30,6 fps (32,7 na rodada 08; variação do renderizador por software). |

Cálculo: 0,30×8,6 + 0,20×8,5 + 0,20×8,5 + 0,15×8,7 + 0,10×8,8 + 0,05×8,6 = 2,58 + 1,70 + 1,70 + 1,305 + 0,88 + 0,43 = 8,595, arredondado para **8,6**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. Câmbio "caça" marcha e dá tranco toda vez que o carro desacelera para 44–52 km/h (Feedback +0,15, Suspensão +0,05)

**Sintoma:** em `outside`, o limite de baixo da marcha usa o `early` do quadro atual. Em 4ª, a 45–51 km/h, basta um quadro sem velocidade constante (freando atrás de um carro, ou os −3 km/h de um buraco) para `early` virar 0, `v < 52 − 0,5` ficar verdadeiro e a caixa **descer para 3ª na hora**. Assim que a velocidade estabiliza, `early` volta a 8 e, 0,5 s depois, ela **sobe de novo para 4ª**, com o `pitch_v -= 0.15` do tranco. A faixa do meio anda a 45–58 km/h, então isso acontece toda vez que o jogador encosta atrás de alguém nela.

**Prova (teste a, jogo atual):**

| Cenário | Trocas | Caças (desce-sobe < 1,5 s) | Log |
|---|---|---|---|
| Seguir carro a 45 km/h | 3 | **1** | 4→3 a 51,4 km/h; 3→4 0,77 s depois |
| Seguir carro a 50 km/h | 3 | **1** | 4→3 a 51,2; 3→4 0,57 s depois |
| Buraco a 48 km/h | 2 | **1** | 4→3 no impacto; 3→4 0,73 s depois |
| Faixa do meio, manual, 120 s | 3 | **1** | 4→3 a 51,1; 3→4 0,53 s depois |
| Piloto automático semente 2, 120 s | 5 | **1** | 4→3 a 51,2; 3→4 0,48 s depois |
| 0→100 km/h | 3 | 0 | 16,7 / 32,7 / 52,7 km/h, ok |

**Onde:** `scripts/game.gd`, `_process`, bloco "four-speed box": `var outside: bool = v < GEAR_LO[gear_i] - early - 0.5 or …`.

**Mudança sugerida (testada em `c9G`):** histerese fixa na descida, independente de `early`:
```gdscript
var outside: bool = v < GEAR_LO[gear_i] - 8.5 or v > GEAR_HI[gear_i] + 0.5
```
**Resultado:** 0 caças em todos os cenários acima (seguir 45/50/56: 1 troca só; buraco a 48: 0 trocas; piloto automático: 3 trocas, só as da largada); 0→100 inalterado (16,7 / 32,7 / 52,7). A descida em aceleração forte abaixo de 43,5 km/h continua imediata.

### P2. Guard-rail: o arrasto não freia, e o raspão contínuo é mudo (Feedback +0,1, Fluxo +0,05)

**Sintoma:** o `v -= 12·dt` vem **depois** do cruise, que repõe a velocidade no quadro seguinte (`+13·dt` disponível). O equilíbrio fica em `alvo − 0,2 km/h`: segurar o volante contra o rail não custa velocidade. Além disso, depois do primeiro raspão o `vx` é zerado a cada quadro (`vx = maxf(vx, 0.0)`) e nunca passa de −0,2 de novo, e o `a_rumble` só usa `off` (lado direito). O carro corre colado no rail a 95 km/h em silêncio.

**Prova (teste b, jogo atual):** volante para a esquerda por 4 s: 50 → **49,8** km/h, 95 → **94,8** km/h; multiplicador 3 → 2 (certo); ao soltar volta a px −0,867 (certo); nenhum som depois do primeiro "bump".

**Onde:** `scripts/game.gd`, `_process`: `if px <= -1.04: v = maxf(0.0, v - 12.0 * dt)` e a linha do `a_rumble.volume_db`.

**Mudança sugerida (arrasto testado em `c9G`, piso e som não testados):** levar o arrasto para o alvo do cruise, antes do `var close`, com piso de 30 km/h, e ligar o ronco no rail:
```gdscript
if px <= -1.04:   # held against the rail: scrub speed (the cruise must not refill it)
	tgt = minf(tgt, maxf(30.0, v - 12.0 * dt))
...
var on_rail := px <= -1.04
a_rumble.volume_db = linear_to_db(maxf(0.0001, ... + (0.1 if off or on_rail else 0.0)))
```
**Resultado (sem o piso):** 4 s contra o rail: 95 → **54,0** km/h, 50 → 8,8 km/h (por isso o piso de 30). O alvo do cruise não muda: ao soltar, o carro volta à velocidade escolhida.

### P3. A regra do "centro" tornou impossível passar o buraco entre as rodas (Pista +0,1, Dirigibilidade +0,05)

**Sintoma:** a mudança da rodada 08 (sugestão minha, que estava errada) faz qualquer buraco com o centro a menos de 0,06 do centro do carro contar como **as duas rodas**, com ×1,3 de força. Mas os buracos têm `w` de 0,07–0,12 e as rodas ficam em ±0,2: fisicamente, um buraco desse tamanho bem no meio passa **entre** as rodas. A faixa |d| < 0,14 − w era justamente o "desvio por cima" que um motorista experiente faz em estrada ruim. Agora ela pune mais forte que pegar com uma roda só.

**Prova (testes d, e):**
- Buraco de 0,07 / 0,09 / 0,12 exatamente sob o centro, jogador parado no meio da faixa: **1/1/1 acertos** (com `zb_v` −11/−13/−15) no atual; **0/0/0** no `c9B` (sem a regra).
- `full_drive` a 90 km/h: o bot cuidadoso, que anda no centro da faixa, acerta **1** buraco no atual e **0** no `c9B` (pontos: 54.662 vs 58.979). A 70 e 100 km/h e no piloto automático (8 × 120 s: 14 buracos nos dois) não muda nada.

**Onde:** `scripts/game.gd`, `_hit_feat` (as duas linhas `var l/r … or absf(d) < 0.06`) e `_build_surface` (largura dos buracos).

**Mudança sugerida:** tirar o `or absf(d) < 0.06` das duas linhas, e fazer o "duas rodas" acontecer de verdade com crateras raras e largas, que naturalmente alcançam as duas rodas (com `w ≥ 0.15`, `l and r` é verdade para |d| < w − 0,14):
```gdscript
var w := randf_range(0.07, 0.12) if randf() > ROUGH[i] * 0.25 else randf_range(0.2, 0.26)   # a rare crater in the rough stretches
segs[i].feat.append({"t": 0, "x": ..., "w": w})
```
Desenhar a cratera com o mesmo código do buraco já escala pela largura. Não testei a cratera; a reversão está testada (`c9B`).

### P4. Na curva mais fechada a 95 km/h, meio segundo fora ainda zera o x4 (Fluxo +0,05, Dirigibilidade +0,05)

**Sintoma:** a tolerância de 0,4 s resolveu os 70 km/h, mas é tudo ou nada: com 0,41 s fora, o `clean` vai a 0 e o x4 vira x1, enquanto uma batida ou um raspão no rail custam um degrau.

**Prova (teste c, começando em x4):**

| Reação | 70 km/h: fora / x final | 95 km/h: fora / x final |
|---|---|---|
| 0,15 s (banco) | 0 s / x4 | 0 s / x4 |
| 0,25 s | 0,23 s / **x4** | 0,48 s / **x1** |
| 0,30 s | 0,80 s (em trechos curtos) / x4 | 0,60 s / x1 |

(O bot é de liga-desliga e oscila; um humano antecipa. Descontei pouco.)

**Onde:** `scripts/game.gd`, `_process`: `elif off_t > 0.4: clean = 0.0`.

**Mudança sugerida (não testada):** cobrar um degrau a cada 0,4 s fora, como no resto do jogo:
```gdscript
elif off_t > 0.4:
	off_t = 0.0   # one step per 0.4 s on the grass
	mult = maxi(1, mult - 1)
	clean = minf(clean, (mult - 1) * 25.0)
```
Resultado calculado: 95 km/h/0,25 s → x3; sair de verdade por 2 s → x1, como hoje.

### P5. Em 4ª entre 44 e 52 km/h o motor fica travado em 0,90× (Feedback +0,05)

**Sintoma:** a subida antecipada põe a 4ª abaixo do seu `GEAR_LO` (52), e o `rpm := clampf((v - g_lo) / (g_hi - g_lo), 0, 1)` fica em 0. A 44, 48 ou 52 km/h o som é idêntico (0,90×), e é a velocidade mais comum na faixa do meio.

**Prova (teste a):** `pitch_last10s` = **0,900** seguindo carros a 45 e 50 km/h e na faixa do meio manual; 0,931 a 56 km/h.

**Onde:** `scripts/game.gd`, `_process`, bloco "four-speed box": `var g_lo: float = GEAR_LO[gear_i]`.

**Mudança sugerida (calculada):** usar como base da rotação o ponto onde a marcha pode realmente entrar:
```gdscript
var g_lo: float = GEAR_LO[gear_i] - (8.0 if gear_i > 0 else 0.0)
```
Resultado calculado em 4ª: 44 km/h → 0,90×, 52 → 0,96×, 70 → 1,08×, 100 → 1,28× (hoje 1,27×); nas outras marchas a variação fica um pouco menor na aceleração. Atenção: `last_gear_lo` compara `g_lo`; o tranco continua só na subida.

**Fora do top 5:**
- **Assentamento sempre 1,683 s** em qualquer buraco/velocidade (herdado).
- **Til de Ã/Õ** desenhado como `.##.#` / `...#.#`: assimétrico, a 16 px com sombra lê quase como trema ("DIREÇÄO"). Um til simétrico `.##..#` / `#..##.` resolve. Só visual.
- **Pneus em blocos** na câmera externa (herdado).
- **Rail com o volante:** o primeiro raspão tem som, aviso e tranco; os seguintes (sem soltar o volante) não têm nada (ver P2).

## 3. Problemas da própria métrica (descontados na nota)

- **A batida do `full_drive` a 90 km/h continua sendo da largada do teste** (carro lento na faixa da direita logo à frente do `place(60, 0.667, v)`). No `c9B`, até a 70 km/h aparece 1 batida pela mesma razão: depende da ordem dos cenários. Sugiro filtrar os carros a menos de 4.000 dessa faixa, como o `_shots_only` faz. Não descontei.
- **O `full_drive` mede "bot cuidadoso" andando sempre no centro exato da faixa**, por isso a regra do P3 apareceu ali. Um bot que mira entre as rodas mediria a habilidade melhor.
- **O `curve_follow` é liga-desliga com zona morta de ±0,05** e só usa 0,15 s de reação; não mede o multiplicador. Usei a minha sonda (teste c) para isso.
- **Nenhum cenário mede o câmbio nem o rail.** Sugiro dois: "seguir carro a 48 km/h por 30 s" contando trocas de `gear_i`, e "segurar contra o rail 4 s" medindo `v`.
- **FPS:** 30,6, sem nada em paralelo. Rodada 08: 32,7. Como nada de render mudou além da fonte, considero variação do renderizador por software.

## 4. Comparação com a rodada 08

A nota foi de **8,5 para 8,6**. As cinco sugestões da rodada 08 entraram e funcionam como previsto (freio fantasma eliminado; rail custa um degrau e devolve à faixa; x4 mantido a 70 km/h com 0,25 s de reação; motor em 4ª a velocidade constante na faixa do meio; acentos de altura cheia). A subida é contida porque a implementação do câmbio trouxe uma caça de marcha nova (P1), o arrasto do rail não funciona (P2) e a regra do centro, sugerida por mim, piorou a pista (P3).

| Métrica | Rodada 08 | Rodada 09 | Alvo |
|---|---|---|---|
| Troca de faixa: tempo / overshoot / assenta | 0,80–0,82 / 0,042–0,050 / 1,18–1,30 | igual | 0,6–1,0 / < 0,10 / < 1,5 |
| Toque de 0,15 s | 0,094–0,095 | igual | 0,05–0,12 |
| Curva força 3: RMS / máx. (95 km/h) | 0,133 / 0,289 | igual | < 0,15 |
| Curva 70 km/h, reação 0,25 s: x final | x1 | **x4** | x4 |
| Curva 95 km/h, reação 0,25 s: x final | x1 | x1 | x3 |
| Toque perto de carro lento na faixa vizinha: v mín. (90 km/h) | 60,8 | **90** (sem `px_soon`; medido como variante A na rodada 08, não refeito) | 90 |
| Perigos/min (70 / 90 / 100) | 9,0 / 10,5 / 13,0 | igual | 6–14 |
| Bot: buracos acertados (70 / 90 / 100) | 0 / 0 / 4 | 0 / **1** / 3 | ≤ 15% |
| Cabine com chuva: margem a 95 km/h | 1,67 s | 1,67 s | ≥ 1,5 s |
| Buraco: corpo / arfagem a 95 km/h | 14,2 / 22,5 px | igual | ≤ 25 |
| Piloto automático (banco 4 × 90 s) | 0 batidas, 6 buracos | igual | 0 |
| Motor seguindo carro a 50 km/h | 1,31× em 3ª | **0,90× em 4ª**, com 1 caça + tranco ao chegar | — |
| Guard-rail segurado 4 s a 95 km/h | x→1, preso no rail, 30 km/h | x−1, volta à faixa, **94,8 km/h**, mudo | x−1, perde velocidade, ronco |
| Acentos maiúsculos | encolhidos | **altura cheia** | — |
| FPS (software) | 32,7 | 30,6 | ~40 |

- **Melhorou:** freio fantasma eliminado; guard-rail justo (um degrau, volta sozinho); tolerância de 0,4 s fora da borda; motor em 4ª no cruzeiro e HUD coerente com o som; fonte com acentos corretos.
- **Piorou:** caça de marcha com tranco ao desacelerar para 44–52 km/h (P1, nova); passar o buraco entre as rodas ficou impossível e o bot passou a acertar 1 buraco a 90 km/h (P3, nova).
- **Ficou igual:** assentamento sempre 1,683 s; pneus em blocos; margem com chuva 1,67 s; o tudo-ou-nada a 95 km/h na curva.
- **Novos achados:** P1, o arrasto do rail anulado pelo cruise (P2), o raspão contínuo mudo, o motor travado em 0,90× (P5) e o til assimétrico.
