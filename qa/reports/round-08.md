# Rodada 08: Chuva na BR

Data: 2026-11-12.

## Fontes

- `qa/run_qa.sh`, rodado sozinho, sem nenhum outro processo em paralelo: métricas em `qa/metrics/latest.json`, 6 capturas em `qa/shots/`, `fps.txt` (**32,7 fps**) e `visibility.json`.
- Leitura de `scripts/game.gd` (`_process`, `_hit_feat`, `_build_surface`, `road_y`, piloto automático, trânsito, áudio), `scripts/world.gd`, `scripts/cockpit.gd`, `scripts/hud.gd` e `tests/test_drive.gd`.

### O que mudou desde a rodada 07

Comparei com `qa/snapshots/round-07/`. Mudaram `game.gd`, `world.gd` e `tests/test_drive.gd`. As cinco sugestões da rodada 07 entraram, e também duas sugestões que estavam fora do top 5:

- **P1 (piloto automático):** o bloco do cruise roda também com `auto`, olhando a faixa-alvo (`auto and absf(c.x - LANES[lane]) < 0.3`). A batida com `auto` não tira mais o multiplicador.
- **P2:** espaçamento entre buracos passou de 16 para **20** segmentos.
- **P3:** o motor tem **4 marchas**, com `pitch_scale = 0.9 + 0.45·rpm` dentro de cada marcha, queda em ~0,15 s na troca e um pequeno tranco (`pitch_v -= 0.15`) na subida de marcha.
- **P4:** o `rate` do volante passou de 5 para **6**, e o empurrão da curva, de 0,16 para **0,14**.
- **P5:** a fenda do buraco tem **2,0** de altura, o brilho ficou em 1,2·hw (fora do centro) e o `hole_c` ficou mais escuro (`lerp(BLACK, 0.8)`).
- **Fora do top 5:**
  - o guard-rail ganhou som (`bump` ∝ |vx|), tranco, rolagem e o aviso "EPA, GUARD-RAIL!";
  - o `_board_far` agora procura a cor das letras ao longo da linha.
- **Novidade não pedida:** `px_soon := px + vx * 0.4`. O cruise do **jogador** agora freia também por carros na faixa para onde o carro "está indo" (ver P1).
- **No banco:** o `autopilot` soma 4 sementes (2, 3, 5, 7) × 90 s.

### Testes extras na minha cópia

Fiz tudo em cópias no meu diretório temporário (`scratchpad/c8`, `c8A`, `c8B`, `c8C`, `c8R`, `c8O` e `c7s` = rodada 07). Nenhum arquivo do jogo foi alterado. As sondas leem o jogo de fora (texto do aviso, `last_gear_lo`, `a_engine.pitch_scale`, `n_bumps`), sem instrumentar o código.

- (a) Piloto automático: 8 sementes × 120 s, com log de batidas e de avisos.
- (b) Marchas:
  - aceleração de 0 a 100 km/h;
  - seguir um carro a 32, 45, 50 e 52 km/h (para ver se a caixa fica trocando de marcha);
  - cruise fixo em 52 e 70 km/h.
- (c) Guard-rail:
  - volante segurado contra o canteiro a 50 e 95 km/h;
  - um raspão curto a 70 e 95 km/h.
- (d) `full_drive` a 70/90/**100** km/h, com log de cada batida (distância, faixa e velocidade dos carros).
- (e) `curve_follow` com 0,25 s de reação, a 70 e 95 km/h, medindo o multiplicador e a velocidade.
- (f) **Toque dentro da faixa** (0,25 s, o mesmo do `nudge_dodge`) na direção de uma faixa com um carro a 40 km/h a 2.500–5.000 à frente, e ultrapassagem desse carro. Rodei no código atual e na rodada 07.
- (g) As variantes A/B/C (P1), R (P2) e O (P3), medidas com o mesmo pacote: toques, `side_merge`, `cut_in_front`, `full_drive` e piloto automático em 8 sementes.

## 1. Nota final: **8,5 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **8,4** | Os números do banco melhoraram e estão todos dentro da faixa:<br>• resposta de 0,167 s;<br>• troca de faixa em 0,80–0,82 s, overshoot de 0,042–0,050, assentamento de 1,18–1,30 s;<br>• toque de **0,094–0,095**, que fica onde o jogador deixou;<br>• curva força 3 com RMS de 0,122/0,133, máximo de 0,258/**0,289** e offroad 0;<br>• desvio dentro da faixa a 95 km/h em **6/6** (era 5/6).<br>Mas há uma regressão nova no gesto mais comum do jogo (P1): o `px_soon` faz o cruise **frear até −29 km/h** quando o jogador dá um toque dentro da própria faixa e há um carro lento na faixa vizinha. Com 0,25 s de reação, o bot ainda sai pela borda direita na curva mais fechada: 0,23 s a 70 km/h e 0,43 s a 95 km/h (P3). |
| 2 | Suspensão e sensação | 20% | **8,5** | Sem mudança, e continua boa:<br>• corpo de 8,8 / 11,8 / 14,2 px;<br>• arfagem de 13,0 / 18,2 / 22,5 px no buraco e de 14,0 / 16,0 / 18,8 px na estrada, sempre ≤ 25;<br>• 1,5 oscilação;<br>• puxão lateral de 0,022–0,037.<br>O tranco na troca de marcha é discreto. Descontos herdados: o assentamento é sempre 1,683 s, seja qual for o buraco, e o "duas rodas" (×1,3) continua código morto. |
| 3 | Pista e desafio | 20% | **8,6** | **9,0 / 10,5 / 13,0 perigos/min** a 70/90/100 km/h: as três velocidades estão dentro de 6–14. O bot cuidadoso acerta 0/18, 0/21 e 4/26 (15%, no limite, mas na velocidade máxima). A cabine com chuva lê o buraco até 22.500, com **1,67 s** de margem a 95 km/h (era 1,83 s); a câmera externa e a cabine seca vão até 27.000 (2,17 s). Descontos:<br>• a 70 e 90 km/h o bot não acerta nada: o desafio ficou leve para quem olha à frente;<br>• a margem com chuva caiu 0,16 s com o buraco novo. Continua acima de 1,5 s. |
| 4 | Feedback | 15% | **8,7** | Duas lacunas antigas foram fechadas:<br>• **o motor troca de marcha**: 0,97 → 1,23 dentro de cada marcha, com queda para ~1,0 na troca e 1,27× a 100 km/h (era 1,88×);<br>• **o guard-rail tem som, tranco e aviso** ("EPA, GUARD-RAIL!" em 0,6 s, testes c).<br>A batida do piloto automático não multa mais. Descontos:<br>• seguindo um carro a 45–52 km/h (a faixa do meio anda a 45–58), o motor fica parado em 3ª a 1,19–1,35×, o topo da marcha (P4);<br>• encostar no guard-rail zera o multiplicador, e o carro fica parado ali (P2). |
| 5 | Fluxo relaxante | 10% | **8,6** | **O piloto automático não bate: 0 batidas em 8 de 8 sementes × 120 s**, com 1–3 buracos e 0–2 poças por corrida, terminando com multiplicador x4. O banco confirma: 0 batidas em 4 sementes × 90 s. Descontos:<br>• o freio fantasma do P1;<br>• encostar no guard-rail zera o multiplicador e deixa o carro raspando a 30 km/h até o jogador virar (P2);<br>• uma escapada de 0,23 s pela borda direita também zera o x4 (P3). |
| 6 | Visual e desempenho | 5% | **8,4** | O buraco a média distância agora lê como fenda escura com um reflexo pequeno à esquerda (recorte de `chase_drive`); de perto, é uma fenda escura com a borda molhada (`chase_lane_change`). A pixel art está coerente e nada aparece cortado. Descontos:<br>• **as maiúsculas acentuadas saem como minúsculas** na fonte: "CâMERA", "VOCê", "Só" (P5);<br>• os pneus na câmera externa ainda são blocos;<br>• 32,7 fps no software (34–36 na rodada 07). Pode ser variação. |

Cálculo: 0,30×8,4 + 0,20×8,5 + 0,20×8,6 + 0,15×8,7 + 0,10×8,6 + 0,05×8,4 = 2,52 + 1,70 + 1,72 + 1,305 + 0,86 + 0,42 = 8,525, arredondado para **8,5**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. Freio fantasma: um toque dentro da faixa freia o carro por causa de um carro na faixa vizinha (Dirigibilidade +0,2, Fluxo +0,1)

**Sintoma:** a linha nova `var px_soon := px + vx * 0.4` projeta a posição 0,4 s à frente. Um toque de 0,25 s (o gesto padrão para desviar de um buraco sem trocar de faixa) leva o `vx` a ~0,6, e o `px_soon` cai dentro dos 0,46 do carro na faixa vizinha. Como esse carro está até 4.000 à frente e 15 km/h mais lento, `close` vira verdadeiro e o cruise freia a **−70 km/h/s**. O jogador desvia do buraco, continua na própria faixa e mesmo assim perde até 29 km/h.

**Prova (teste f):** toque de 0,25 s, carro a 40 km/h na faixa vizinha.

| Distância do carro | Atual, 90 km/h (esq. → meio) | Atual, 70 km/h (dir. → meio) | Rodada 07 |
|---|---|---|---|
| 2.500 | v mín. **78,3** | **48,0** | 90 / 70 |
| 3.500 | **60,8** | **51,4** | 90 / 70 |
| 5.000 | **60,8** | **65,5** | 90 / 70 |

Em todos os casos, o carro termina na própria faixa (px final de −0,478).

**Onde:** `scripts/game.gd`, `_process`, bloco `if started:   # cruise control (and the autopilot) …`.

**Mudança sugerida (testada):** tirar o `px_soon`. O termo do piloto automático (`auto and absf(c.x - LANES[lane]) < 0.3`) já resolve o que a rodada 07 pediu.

```gdscript
if started:   # cruise control (and the autopilot) yields to the car ahead instead of ramming it
	for c in cars:
		if c.dir > 0 and (absf(c.x - px) < 0.46 or (auto and absf(c.x - LANES[lane]) < 0.3)):
```

| Variante | Toques: v mín. (6 casos) | `side_merge`: batidas | Piloto automático (8 × 120 s) | `full_drive` 70/90/100: batidas |
|---|---|---|---|---|
| Atual (`vx·0,4`) | 48,0–78,3 | 1/1/1/1 | 0 batidas | 0/1/1 |
| **A: sem `px_soon`** | **90 / 70 (sem perda)** | 1/1/1/1 | 0 batidas | 0/1/1 |
| B: `vx·0,2` | 52,6–84,2 | 1/1/1/1 | 0 batidas | 0/1/1 |
| C: `vx·0,4` só com \|vx\| > 0,7 | 66,5–86,5 | 1/1/1/1 | 0 batidas | 0/1/1 |

O `px_soon` não evita nenhuma batida em nenhum cenário medido. Ele só causa o freio fantasma. A variante A é a recomendada.

### P2. Guard-rail: zera o multiplicador e deixa o carro raspando (Fluxo +0,1, Feedback +0,1)

**Sintoma:** o som e o aviso novos estão bons, mas:
- o canteiro conta como `off` (`absf(px) > 1.02`), então encostar no rail **zera o multiplicador** (x3 → x1) e limita a velocidade a 30 km/h. Uma batida num carro custa só um degrau;
- o ímã de faixa só age com `absf(px) < 1.02`. Ao soltar o volante, o carro **fica parado em px −1,06**, raspando no rail a 30 km/h, até o jogador virar. Não há nenhum aviso depois do primeiro.

**Prova (teste c):** volante para a esquerda a 50 e 95 km/h. O carro chega ao rail em 0,57–0,58 s e o aviso aparece em 0,6 s. Depois de soltar o volante por 4 s: `px_end` de −1,06, `v_end` de 30, `mult_end` de 1. O raspão curto (px mínimo de −0,99) não tem nenhuma punição, e isso está certo.

**Onde:** `scripts/game.gd`, `_process`: `var off := …`, o `if dir == 0.0 and not is_auto and aqua <= 0.0 and absf(px) < 1.02:` e o bloco `if px < -1.06:`.

**Mudança sugerida (testada em `c8R`):**
```gdscript
var off := px > 1.02   # the median side is the guard rail's job
...
if dir == 0.0 and not is_auto and aqua <= 0.0 and px < 1.02:
...
			roll_v += 0.3
			mult = maxi(1, mult - 1)   # a scrape costs a step, like a nudge
			clean = minf(clean, (mult - 1) * 25.0)
			hud.toast("EPA, GUARD-RAIL!", 1.5)
```
**Resultado:** o multiplicador vai de 3 para 2 e o carro volta sozinho para px −0,867, a 50/95 km/h. O raspão curto continua sem custo. Sugiro também um arrasto enquanto `px <= -1.04` (`v -= 12·dt`): sem ele, quem segura o volante contra o rail mantém 95 km/h (não testado).

### P3. Um momento com a roda fora da borda direita zera o x4 (Fluxo +0,1, Dirigibilidade +0,1)

**Sintoma:** qualquer quadro com `absf(px) > 1.02` zera o `clean` e corta o cruise para 30 km/h, a −34 km/h/s. Na curva mais fechada, um jogador com 0,25 s de reação passa a borda direita por um instante e perde o x4 inteiro. Num jogo relaxante, uma roda na faixa de acostamento por 0,2 s não é "sair da pista".

**Prova (teste e):** `curve_follow` com 0,25 s de reação e multiplicador inicial x4.
- 70 km/h: offroad de 0,23 s, x4 → **x1**, v mínima de 62,1;
- 95 km/h: offroad de 0,43 s, x4 → x1, v mínima de 80,3;
- com 0,15 s de reação (o banco): offroad 0 e x4 mantido.

**Onde:** `scripts/game.gd`, `_process`: `if off: tgt = minf(tgt, 30.0)` e `elif off: clean = 0.0`.

**Mudança sugerida (testada em `c8O`):** uma tolerância de 0,4 s.
```gdscript
var off := absf(px) > 1.02
off_t = off_t + dt if off else 0.0
if off_t > 0.4:   # a wheel over the line for a moment is not leaving the road
	tgt = minf(tgt, 30.0)
...
		elif off_t > 0.4:
			clean = 0.0
```
**Resultado:**
- 70 km/h com reação de 0,25 s: **x4 mantido**, v mínima de 70,0;
- 95 km/h com reação de 0,25 s (0,48 s fora): x1, v mínima de 92,2. A saída de verdade continua punida;
- a reação de 0,15 s não muda.

O ronco (`a_rumble`) e o `kick` continuam usando `off`, então o aviso pelo som continua imediato. Junto com o P2, use `px > 1.02` em vez de `absf(px)`.

### P4. Seguindo a faixa do meio, o motor fica no topo da 3ª (Feedback +0,1)

**Sintoma:** as trocas são fixas em 16/32/52 km/h, sem levar em conta a carga. A faixa do meio anda a 45–58 km/h e o cruise acompanha o carro da frente exatamente, então o motor fica parado em 3ª:
- 1,19× a 45 km/h;
- 1,31× a 50 km/h;
- **1,35×** (o máximo da marcha) a 52 km/h.

Com 52,1 km/h, cai para 0,90×. A 100 km/h em 4ª, o motor gira menos (1,27×) do que seguindo um caminhão a 50. Um carro antigo em velocidade constante sobe de marcha cedo. A caixa não fica trocando sem parar (0 trocas em 30 s nos quatro casos), o que é bom.

**Prova (teste b):**
- `follow(52)`: pitch de 1,35 constante;
- `follow(50)`: 1,305;
- `follow(45)`: 1,192;
- aceleração de 0 a 100: 0,97 → 1,23 em cada marcha, 3 trocas.

**Onde:** `scripts/game.gd`, `_process`, bloco "four-speed box".

**Mudança sugerida (calculada, não testada de ouvido):** em velocidade constante (|Δv/dt| < 2 km/h/s), subir de marcha 8 km/h antes:
```gdscript
var cruising := absf(v - v0) / maxf(dt, 0.001) < 2.0
var e := 8.0 if cruising else 0.0
var g_lo: float = 0.0 if v < 16.0 - e else (16.0 if v < 32.0 - e else (32.0 if v < 52.0 - e else 52.0))
```
Resultado calculado: 0,90–1,01× a 44–52 km/h em cruzeiro, e o mesmo escalonamento de hoje na aceleração. Para não trocar de marcha sem parar quando o cruise oscila, troque `g_lo` só se a nova marcha ficar estável por 0,5 s. O HUD deve usar o mesmo `g_lo`; hoje ele calcula a marcha por conta própria.

### P5. As maiúsculas acentuadas saem como minúsculas (Visual +0,1, Feedback +0,05)

**Sintoma:** na Press Start 2P, as maiúsculas acentuadas são desenhadas encolhidas para caber o acento na célula de 8 px. Os avisos em português saem misturados: "CâMERA EXTERNA", "VOCê NO VOLANTE", "PILOTO AUTOMÁTICO: Só CURTA A VIAGEM", "DIREçãO SUAVE", "ÚLTIMO PEDÁGIO". Num jogo cujo charme é ser brasileiro, isso aparece em quase todo aviso.

**Prova:** recortes ampliados de `chase_puddle.png` (aviso da câmera), `chase_lane_change.png` ("VOCê") e `cockpit_drive.png` ("Só"). As outras letras têm a altura cheia, e as acentuadas têm a altura da minúscula.

**Onde:** `scripts/hud.gd`, `_label`/`_centered` (fonte `PressStart2P.ttf`). Os textos estão em `scripts/game.gd`.

**Mudança sugerida:** desenhar os avisos com 1 px a mais de espaço entre linhas e usar uma fonte pixel com acentos fora da célula (por exemplo, uma versão da fonte com acentos acima da cabeça da letra). Outra opção, mais barata: gerar um `FontVariation` com `glyph` próprio para ÁÂÃÇÉÊÍÓÔÕÚ desenhados em 8×10. Não testei; é só visual.

**Fora do top 5:**
- **O assentamento é sempre 1,683 s, e o "duas rodas" é impossível.** As rodas ficam em ±0,2, e o alcance é `w + 0,06` ≤ 0,18, então `l and r` nunca é verdade. Sugestão: tratar como "duas rodas" quando `absf(d) < 0.06`. Herdado.
- **O desafio a 70/90 km/h ficou leve.** O bot cuidadoso acerta 0 de 18 e 0 de 21 perigos. Não é problema por si só (o jogo é relaxante), mas a pista não pede quase nada de quem olha à frente. Se quiser mais "dirigir bem", junte 2 buracos em faixas diferentes de vez em quando, em vez de diminuir o espaçamento.
- **O tranco da subida de marcha também acontece depois de um buraco.** Exemplo: a 52 km/h, o buraco tira 3 km/h, a caixa desce e sobe de marcha, e o tranco vem junto. É raro e leve.

## 3. Problemas da própria métrica (descontados na nota)

- **As batidas do `full_drive` são da largada do teste, não do jogo.** Com log (teste d), as três batidas (70/90/100 km/h) acontecem entre 0,2 e 0,7 s da largada. O `place(60, 0.667, v)` põe o jogador na faixa da direita com um carro a 35,6 km/h a 1.271–1.283 à frente: é batida certa antes de qualquer reação. Sugiro filtrar os carros dessa faixa a menos de 4.000 no `full_drive`, como o `_shots_only` já faz. Não descontei do jogo.
- **O `full_drive` ainda depende da ordem.** Rodando só o `full_drive` (minha cópia), a 70 km/h deu 1 batida (da largada). No banco oficial, depois dos outros cenários, deu 0. Algum estado global sobra entre cenários além do `seed()`.
- **O `curve_follow` é um bot de liga-desliga** com zona morta de ±0,05. Com 0,25 s de atraso, ele entra num ciclo de oscilação e sai pelo lado de **fora da correção**, pela direita. Um humano antecipa. Usei o dado só para dimensionar o P3, e descontei pouco da nota.
- **O `side_merge` mede o bot jogando o carro em cima de outro.** A 95 km/h com 2.500 de distância, a diferença de 55 km/h fecha o espaço em 0,48 s, antes de a troca de faixa (0,8 s) terminar. A distância mínima de 25–156 é física, não erro do cruise.
- **FPS:** 32,7, medido sem nada em paralelo (na rodada 07, 33,9–36,5 em medições minhas). Considero variação do renderizador por software. Não medi de novo para não poluir.
- **O `nudge_dodge` não pega o P1:** o cenário não tem trânsito. Sugiro uma versão com um carro a 40 km/h na faixa vizinha a 3.500, medindo `v_min`.

## 4. Comparação com a rodada 07

A nota foi de **8,4 para 8,5**. As cinco sugestões entraram, e as previsões da rodada 07 se confirmaram:
- toque de 0,094–0,095 (previsto: 0,094–0,095);
- curva a 95 km/h com máximo de 0,289 (previsto: 0,289);
- desvio dentro da faixa em 6/6;
- 9,0 / 10,5 / 13,0 perigos/min (previsto: 9,0 / 10,5 / 13,0);
- 0 batidas no piloto automático em 8 sementes.

A subida é contida porque a mudança não pedida (`px_soon`) criou um freio fantasma no gesto mais comum do jogo (P1).

| Métrica | Rodada 07 | Rodada 08 | Alvo |
|---|---|---|---|
| Troca de faixa: tempo / overshoot / assenta | 0,82–0,83 / 0,042–0,050 / 1,20–1,32 | 0,80–0,82 / 0,042–0,050 / 1,18–1,30 | 0,6–1,0 / < 0,10 / < 1,5 |
| Toque de 0,15 s | 0,074–0,075 | **0,094–0,095** | 0,05–0,12 |
| Curva força 3: RMS / máx. (95 km/h) | 0,138 / 0,322 | **0,133 / 0,289** | < 0,15 |
| Desvio dentro da faixa a 95 km/h | 5/6 | **6/6** | — |
| Toque perto de um carro lento na faixa vizinha: v mín. (90 km/h) | 90 | **60,8** | 90 |
| Perigos/min (70 / 90 / 100 km/h) | 11,0 / 14,0 / 17,0 | **9,0 / 10,5 / 13,0** | 6–14 |
| Bot: perigos acertados | 9,1% / 7,1% / — | 0% / 0% / 15% | ≤ 15% |
| Cabine com chuva: legível até / margem a 95 km/h | 24.000 / 1,83 s | 22.500 / **1,67 s** | ≥ 1,5 s |
| Buraco: corpo / arfagem a 95 km/h | 14,2 / 22,5 px | igual | ≤ 25 |
| Piloto automático, 8 sementes × 120 s | 4 batidas | **0 batidas** | 0 |
| Motor a 70 / 100 km/h | 1,51× / 1,88×, sem marchas | **1,04× / 1,27×, 4 marchas** | — |
| Guard-rail | silencioso, x → 1 | som + aviso, x → 1, carro fica parado no rail | um degrau |
| FPS (software) | 33,9–36,5 | 32,7 | ~40 |

- **Melhorou:**
  - o piloto automático é finalmente "só curta a viagem": 0 batidas e nenhuma multa;
  - a densidade está na faixa em todas as velocidades;
  - o motor tem marchas;
  - o guard-rail tem som e aviso;
  - toque, curva e desvio estão melhores;
  - o buraco lê como buraco também a média distância.
- **Piorou:**
  - o freio fantasma por causa do `px_soon` (P1), uma regressão nova;
  - a margem de visibilidade com chuva caiu de 1,83 para 1,67 s (ainda na faixa).
- **Ficou igual:**
  - o assentamento é sempre 1,683 s;
  - o "duas rodas" continua morto;
  - os pneus em blocos;
  - o `offroad` instantâneo que zera o multiplicador.
- **Novos achados:**
  - freio fantasma (P1);
  - o carro fica parado no rail (P2);
  - um instante fora da pista custa o x4 (P3);
  - o motor no topo da 3ª atrás de carros da faixa do meio (P4);
  - as maiúsculas acentuadas encolhidas (P5);
  - as batidas do `full_drive` são da largada do teste.
