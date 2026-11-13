# Rodada 10: Chuva na BR

Data: 2026-11-13. Rodada de teste **e** afinação: nota antes, mudanças, nota depois.

## Fontes

- `qa/run_qa.sh` antes e depois das mudanças (métricas em `qa/metrics/latest.json`, 8 capturas em `qa/shots/`, todas olhadas; 32,1 fps, eram 28,5 no "antes" desta rodada).
- Teste novo `tests/feat_mola.gd` (71 verificações, `FAILS: 0`): lado da rolagem e da arfagem nas duas câmeras, mola por carro, pulo nas três estradas. Com um diretório de saída ele grava 26 capturas; estão em `docs/capturas/r10/`.
- Cenário novo `jump` e campos novos `roll_turn_in_rad`, `roll_straighten_rad`, `roll_swings_after_release` em `tests/test_drive.gd`; capturas novas `chase_jump` e `cockpit_jump`.
- Leitura de `scripts/game.gd` (suspensão, `_hit_feat`, câmbio, guard-rail), `scripts/world.gd` (`_process`, `_draw_player`), `scripts/cockpit.gd`, `scripts/features/estrada.gd`.

## 1. Nota final: **8,8 / 10** (antes das mudanças: **8,4** pela rubrica nova)

A rubrica mudou a pedido do dono: mola "boa" agora é ~1 oscilação visível e 0,8–1,6 s para assentar (era 1–2 oscilações e 1,2–2,5 s). Pela rubrica antiga o "antes" valia 8,6, igual à rodada 09.

| # | Categoria | Peso | Antes | Depois | Justificativa (depois) |
|---|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | 8,6 | **8,7** | Números do banco iguais (a direção não foi tocada): resposta 0,167 s; troca de faixa 0,80–0,82 s, overshoot 0,042–0,050, assenta 1,18–1,30 s; toque 0,094–0,095; curva força 3 com RMS 0,122/0,133 e 0 s fora. Sobe pouco porque sair da pista agora custa um degrau do multiplicador a cada 0,4 s em vez de zerar tudo (P4 da rodada 09). No ar a direção fica leve e o carro mantém a linha (desvio lateral 0,000–0,003). |
| 2 | Suspensão e sensação | 20% | 7,6 | **9,0** | Antes: 1,5 oscilação e 1,68 s para assentar (mole para o gosto novo); na troca de faixa a volta da rolagem era maior que a ida (0,062 contra 0,043 rad) com 4 balanços depois de soltar; o mergulho de freada estava invertido; não havia pulo. Depois: 1,0 oscilação, 1,07 s (besouro), 0,88 s (picape), 0,52 s (GT); buraco a 70 km/h 9,0 px de corpo e 12,8 px de arfagem; rolagem 0,040 na ida e 0,042 na volta, 1 balanço; freada mergulha; pulo de 0,20–0,47 s acima do limiar. Desconto: ver P1 e P2. |
| 3 | Pista e desafio | 20% | 8,5 | **8,7** | 10,0 / 13,0 perigos/min a 70/90 km/h; bot cuidadoso 0 buracos; margem com chuva 1,67 s a 95 km/h. As cristas dão um motivo novo para escolher a velocidade, mudam de lugar a cada volta e têm placa amarela ~70 segmentos antes. Desconto: a crista em si ainda se lê pouco de dentro da cabine (P1). |
| 4 | Feedback | 15% | 8,6 | **8,9** | Pouso com baque mais grave que o do buraco e volume proporcional, pneus mudos e giro subindo 8% no ar, poeira na terra, fiapo cinza no asfalto seco, respingo no molhado, sombra que encolhe, passageiro que se assusta em pouso forte. Entraram também as correções de câmbio e guard-rail sugeridas na rodada 09 (ver seção 3). |
| 5 | Fluxo relaxante | 10% | 8,8 | **8,9** | Piloto automático 0 batidas (banco 4 × 90 s; `combos.gd` 27/27). O pulo não tira nada: sem perda de velocidade nem de multiplicador, +100 × multiplicador × força de bônus, um aviso discreto só no primeiro pulo e nos de 0,3 s ou mais. |
| 6 | Visual e desempenho | 5% | 8,6 | **8,6** | 32,1 fps. Na câmera externa a carroceria agora inclina e balança para o lado certo de forma visível. Pneus em blocos continuam. |

Cálculo (depois): 0,30×8,7 + 0,20×9,0 + 0,20×8,7 + 0,15×8,9 + 0,10×8,9 + 0,05×8,6 = 2,61 + 1,80 + 1,74 + 1,335 + 0,89 + 0,43 = 8,805 → **8,8**.
Cálculo (antes): 2,58 + 1,52 + 1,70 + 1,29 + 0,88 + 0,43 = 8,40 → **8,4**.

## 2. O que foi feito nos três pedidos do dono

### 2.1 Mola mais firme (`scripts/catalog.gd`)

Frequência = √k rad/s, amortecimento = c / (2√k).

| Carro | Parâmetro | Antes | Depois |
|---|---|---|---|
| Besouro | `spring_k` / `spring_c` | 46 / 3,0 (ζ 0,22) | **64 / 4,6** (ζ 0,29) |
| | `pitch_k` / `pitch_c` | 58 / 6,0 | **80 / 9,0** |
| | `roll_k` / `roll_c` | 36 / 2,5 (ζ 0,21) | **52 / 7,5** (ζ 0,52) |
| | `roll_gain` / `hole_gain` | 1,0 / 1,0 | 1,0 / 1,0 |
| Picape | `spring_k` / `spring_c` | 72 / 3,4 (ζ 0,20) | **96 / 4,9** (ζ 0,25) |
| | `pitch_k` / `pitch_c` | 70 / 5,0 | **95 / 8,0** |
| | `roll_k` / `roll_c` | 30 / 2,2 (ζ 0,20) | **44 / 5,6** (ζ 0,42) |
| | `roll_gain` / `hole_gain` | 1,45 / 1,3 | 1,45 / **1,4** |
| GT | `spring_k` / `spring_c` | 85 / 7,0 (ζ 0,38) | **110 / 10,5** (ζ 0,50) |
| | `pitch_k` / `pitch_c` | 80 / 8,0 | **120 / 13,0** |
| | `roll_k` / `roll_c` | 55 / 5,0 (ζ 0,34) | **80 / 11,5** (ζ 0,64) |
| | `roll_gain` / `hole_gain` | 0,6 / 0,8 | **0,7** / 0,8 |

Resultado no mesmo buraco a 70 km/h (`feat_mola.gd`):

| Carro | Pico do corpo | Assenta | Oscilações |
|---|---|---|---|
| Besouro | 43 un. (era 56) | 1,07 s (era 1,68) | 1,0 (era 1,5) |
| Picape | 51 un. | 0,88 s | 1,0 |
| GT | 19 un. | 0,52 s | 0,5 |

A personalidade ficou: o besouro é o que flutua mais tempo, a picape é a que sobe mais e quica rápido, o GT quase não se mexe.

### 2.2 Cristas que tiram o carro do chão (`game.gd`, `estrada.gd`, `world.gd`)

- **Onde:** uma lombada natural (meio cosseno) por trecho de `crest_gap` segmentos, só em reta. A posição depende só da semente da viagem e do segmento absoluto, então muda a cada volta; `estrada.gd` reveste a pista atrás do carro com a mesma função e põe a placa amarela de saliência ~70 segmentos antes.
- **Quando decola:** quando a pista cai mais rápido do que a gravidade puxa (curvatura × velocidade² < −7000 un./s²). Abaixo do limiar o carro só ondula.
- **No ar:** rodas e carroceria em voo balístico, rodas penduradas um pouco mais baixo, direção leve (aderência ×0,2, o carro mantém a linha), buracos e poças passam por baixo.
- **Pouso:** a mola engole parte da queda (mais quanto mais longo o voo), nariz mergulha, baque e poeira proporcionais. Não perde velocidade nem controle.
- **Câmeras:** na interna a visão sobe e desce com a carroceria (respeita os ajustes de conforto); na externa rodas e carroceria saem do chão e a sombra fica na pista e encolhe.

Tempo no ar / altura das rodas (besouro até 100 km/h, GT acima), só com as cristas na pista:

| Estrada | Crista | Limiar | 70 km/h | 80 | 90 | 100 | 120 | 140 |
|---|---|---|---|---|---|---|---|---|
| Terra | 135 un. × 16 seg., a cada ~330 | ~55 km/h | 0,30 s / 51 | 0,35 / 101 | 0,37 / 135 | 0,38 / 162 | 0,45 / 221 | 0,47 / 242 |
| BR | 150 un. × 20 seg., a cada ~640 | ~67 km/h | 0,20 s / 7 | 0,28 / 34 | 0,33 / 85 | 0,35 / 115 | 0,40 / 182 | 0,45 / 229 |
| Expressa | 95 un. × 26 seg., a cada ~1700 | ~107 km/h | 0 | 0 | 0 | 0 | 0,20 / 10 | 0,25 / 38 |

Capturas: `docs/capturas/r10/pulo_terra_externa_picape.png`, `pouso_terra_externa_picape.png`, `pulo_br_externa_besouro.png`, `pulo_expressa_externa_gt.png`, `qa/shots/chase_jump.png`, `qa/shots/cockpit_jump.png`.

### 2.3 Lado da rolagem

**O sinal de `rt` já estava certo.** Nas duas câmeras, antes e depois, a primeira inclinação é para o lado oposto ao movimento e a curva inclina para fora; a cabine gira o mundo no sentido contrário (horizonte desce do lado de dentro da curva). O que fazia parecer errado:

1. **A volta era maior que a ida.** O volante centraliza duas vezes mais rápido do que vira, então a desaceleração lateral ao endireitar era mais forte: 0,062 rad para **dentro** contra 0,043 para fora, e com amortecimento 0,21 sobravam 4 balanços. O que o olho guardava de uma troca para a direita era o carro deitado para a direita. Agora a aceleração lateral satura (`4·tanh(al/4)`) e a rolagem é bem amortecida: 0,040 na ida, 0,042 na volta, 1 balanço.
2. **Na câmera externa a carroceria era deslocada para o lado do movimento** (`vx · 2,5`), o contrário do que a rotação fazia com o teto, e os dois se cancelavam. Agora ela balança sobre as rodas para o lado em que inclina (`roll · 26`) e a rotação passou de 1,9× para 2,4×.
3. **O mergulho de freada estava invertido** (achado ao conferir os sinais): frear levantava o nariz e acelerar o abaixava, nas duas câmeras. Corrigido, junto com o buraco (nariz cai primeiro) e a lombada de cidade (nariz sobe primeiro).

Capturas: `rolagem_faixa_esq_externa_besouro.png` e `rolagem_faixa_dir_externa_besouro.png` (troca para cada lado), `rolagem_curva_esq_externa_besouro.png` e `rolagem_curva_dir_cabine_besouro.png` (curva em cada direção), mais as outras seis de cabine e as duas `freada_*.png`, todas em `docs/capturas/r10/`.

## 3. Outras melhorias desta rodada

Entraram as quatro sugestões pendentes da rodada 09. **Não rodei uma sonda própria para cada uma**; elas passaram só pela bateria de regressão, então trate os efeitos como os previstos na rodada 09, não como medidos agora.

- **Câmbio sem caça** (P1 da rodada 09): histerese fixa de 8,5 km/h na redução.
- **Guard-rail** (P2): o arrasto passa pelo alvo do cruise, com piso de 30 km/h, e o ronco toca enquanto o carro encosta.
- **Fora da pista** (P4): um degrau do multiplicador a cada 0,4 s, em vez de zerar.
- **Giro do motor** (P5): conta a partir de onde a marcha realmente entra, sem ficar travado em 0,90× entre 44 e 52 km/h.

## 4. Os problemas mais importantes que ficam

### P1. A crista se lê pouco de dentro da cabine (Pista +0,1, Suspensão +0,05)
**Sintoma:** a 40 segmentos de distância a lombada é só uma faixa um pouco mais clara e outra mais escura; quem avisa de verdade é a placa. **Prova:** capturas de aproximação a 60 km/h na BR e na terra (não guardadas no repositório). **Onde:** `world.gd`, laço da pista (`crest_d`). **Sugestão:** sombrear mais a face de trás e escurecer o horizonte da pista logo depois do topo; ou pintar "ondulação" no asfalto da BR.

### P2. Pulinho de 70 km/h na BR pousa mais forte que o pulo de 95 km/h (Suspensão +0,05)
**Sintoma:** a 70 km/h as rodas sobem só 7 un. em 0,20 s, mas a mola comprime 75 un. (15,6 px); a 95 km/h sobe 98 un. e comprime 52 un. (10,8 px). **Causa provável:** a 70 o carro pousa ainda na rampa de descida, onde a mola já vinha comprimindo por conta própria. **Onde:** `game.gd`, `_land`. **Sugestão:** limitar a compressão pela altura do voo, não só pelo tempo.

### P3. O piloto automático também pula (Fluxo, a decidir)
**Sintoma:** a 70 km/h na BR ele dá o pulinho de 0,2 s. Deixei assim porque não custa nada e não acorda o passageiro (só pousos com força > 0,5 acordam). Se o dono preferir, ele pode aliviar para logo abaixo do limiar, como já faz antes da lombada de cidade (`_bump_limit`).

### P4. Nenhum cenário mede câmbio nem guard-rail (métrica)
Pendente desde a rodada 09; por isso a seção 3 não tem números novos.

### P5. Pneus em blocos na câmera externa (Visual, herdado)

## 5. Comparação com a rodada 09

| Métrica | Rodada 09 | Rodada 10 | Alvo novo |
|---|---|---|---|
| Buraco a 70 km/h: corpo / arfagem | 11,8 / 18,2 px | 9,0 / 12,8 px | 6–22 px |
| Oscilações / assentamento (besouro) | 1,5 / 1,68 s | 1,0 / 1,07 s | ~1 / 0,8–1,6 s |
| Arfagem máxima na estrada (50/70/95) | 14,0 / 16,0 / 18,8 px | 14,6 / 15,4 / 16,7 px | 6–22 px |
| Troca de faixa: rolagem ida / volta / balanços | 0,043 / 0,062 / 4 | 0,040 / 0,042 / 1 | volta ≤ ida, ≤ 1 vai e volta |
| Freada: nariz | sobe (invertido) | mergulha | mergulha |
| Pulo na BR a 50 / 70 / 95 km/h | não existia | 0 / 0,20 / 0,35 s | 0 abaixo do limiar; 0,2–0,5 s acima |
| Troca de faixa: tempo / overshoot / assenta | 0,80–0,82 / 0,042–0,050 / 1,18–1,30 | igual | 0,6–1,0 / < 0,10 / < 1,5 |
| Curva força 3: RMS (70 / 95) | 0,122 / 0,133 | igual | < 0,15 |
| Perigos/min (70 / 90) | 9,0 / 10,5 | 10,0 / 13,0 | 6–14 |
| Piloto automático (4 × 90 s) | 0 batidas, 6 buracos | 0 batidas, 4 buracos | 0 |
| FPS (software) | 30,6 | 32,1 | ~40 |

- **Melhorou:** mola, rolagem, arfagem de freada, pulo, e as quatro pendências da rodada 09.
- **Ficou igual:** direção, margem com chuva (1,67 s a 95 km/h), pneus em blocos.
- **Piorou:** nada medido. A batida do `full_drive` a 90 km/h continua sendo a da largada do teste (ver rodada 09).

## 6. Testes no fim da rodada

| Teste | Resultado |
|---|---|
| `tests/feat_mola.gd` (novo) | FAILS: 0 |
| `tests/combos.gd` | 27/27 com piloto automático em 0 batidas, nenhum NaN |
| `tests/test_drive.gd` (via `run_qa.sh`) | sem erro de script, métricas gravadas |
| `tests/feat_estrada.gd` | FAILS: 0 |
| `tests/feat_radio.gd` | FAILS: 0 |
| `tests/feat_paradas.gd` (xvfb) | FAILS: 0 |
| `tests/feat_conforto.gd` (xvfb) | FAILS: 0 |
| `tests/feat_garagem.gd` (xvfb) | 0 failures |
| `tests/feat_mundo.gd` (xvfb) | terminou sem erro, 0 batidas em todos os eventos (não imprime FAILS) |
| `tests/feat_colecao.gd` (xvfb) | terminou sem erro (não imprime FAILS) |
