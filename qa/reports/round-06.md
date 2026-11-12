# Rodada 06: Chuva na BR

Data: 2026-11-12.

## Fontes

- `qa/run_qa.sh`: métricas em `qa/metrics/latest.json`, 6 capturas em `qa/shots/`, `fps.txt` (33,2 fps no renderizador por software) e `visibility.json`.
- Leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/hud.gd`, `scripts/cockpit.gd` e `tests/test_drive.gd`.

### O que mudou desde a rodada 05

Comparei o código atual com `qa/snapshots/round-05/`. Mudaram `game.gd`, `world.gd` e `tests/test_drive.gd`. As cinco sugestões da rodada 05 entraram como foram escritas:

- **P1:** esbarrão lateral (`swipe`) e freada por trás com `minf(1.0, dt * 10.0)`.
- **P2:** brilho azul-céu e borda escura no buraco.
- **P3:** força do buraco proporcional a `f.w` e às duas rodas.
- **P4:** compensação de 60% da curva na linha mantida.
- **P5:**
  - pneu com faixa clara e altura de 7k;
  - reflexos das lanternas em ±22,5k;
  - placa de longe (`_sign_far`) desenhada sem texto quando tem menos de 24 unidades.

Também mudaram duas coisas fora do top 5:
- a placa "PISTA IRREGULAR" agora fica 95 segmentos antes do trecho, cerca de 2 s a 100 km/h;
- o banco ganhou o cenário `side_merge` e o limiar de luminância de 0,06 na visibilidade, como pedi na seção 3 da rodada 05.

### Testes extras na minha cópia

Usei uma **cópia** em `scratchpad/c6/`, com log de batidas. Nenhum arquivo do jogo foi alterado. Rodei:

- (a) sem mãos na curva mais fechada: 24 combinações de faixa, sentido, velocidade e toque prévio;
- (b) buraco por tamanho (0,07 / 0,12), por roda (uma ou "as duas") e por velocidade (40 / 70 / 100 km/h);
- (c) troca de faixa para a frente de um carro lento (40 km/h):
  - 5 distâncias, de 400 a 3.500, a 70 e 95 km/h;
  - mais três casos: entrar na frente de um carro **que está logo atrás** (−400 e −900), e voltar da direita para o meio;
- (d) caminhão a 35 km/h, saindo de 60 e 100 km/h;
- (e) `full_drive` com log de cada batida, rodado sozinho e depois de outro cenário;
- (f) capturas de buracos a 3.500–24.000 unidades, na cabine e na câmera externa;
- (g) as variantes de código sugeridas abaixo, medidas antes de recomendar. Rodei o banco nas partes afetadas e o `_visibility_rendered` do próprio banco.

## 1. Nota final: **8,3 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **8,4** | Tudo dentro da faixa boa:<br>• resposta de 0,167–0,183 s, troca de faixa em 0,82–0,83 s, overshoot de 0,042–0,050, assentamento de 1,20–1,32 s;<br>• o toque fica onde o jogador deixou (0,074–0,075);<br>• o desvio dentro da faixa acerta 11 de 12;<br>• curva força 3 com RMS de 0,126/0,138 e offroad 0.<br>A curva depois de um toque agora "abre" um pouco (0,032–0,099). Desconto: sem toque, ela abre 0,094 / 0,172. O mesmo volante solto ainda dá duas sensações, numa razão de 2,4× (era 5×) (P4). O esbarrão lateral acabou com o "atravessar carros": o maior salto lateral por quadro ficou em 0,020 em todos os casos. |
| 2 | Suspensão e sensação | 20% | **8,5** | O buraco agora tem tamanho:<br>• 0,07 → 0,12 vai de 7,4 → 9,8 px de corpo a 40 km/h e de 12,3 → 16,4 px a 100 km/h;<br>• arfagem de 10,5–23,4 px, sempre ≤ 25;<br>• puxão de 0,018–0,043.<br>Na estrada, arfagem de 14,0 / 16,0 / 18,8 px, crescendo com a velocidade. Descontos:<br>• o multiplicador "duas rodas" (×1,3) nunca dispara, porque a geometria não deixa (seção 3);<br>• o assentamento é sempre 1,683 s, já que só a amplitude muda. |
| 3 | Pista e desafio | 20% | **8,0** | O bot cuidadoso acerta 1/23 = 4,3% e 1/32 = 3,1% dos perigos. A visibilidade agora é medida com limiar de luminância, mais honesto: cabine com chuva legível até 24.000, margem de 1,83 s a 95 km/h. A placa avisa 2 s antes. Descontos:<br>• **16,0 perigos/min a 90 km/h**, acima do teto de 14 (P3). Antes dava 14,5 só porque a batida-muro freava o bot;<br>• na média distância, o buraco lê como uma chapinha elevada, e não como um buraco (P2). |
| 4 | Feedback | 15% | **8,2** | O esbarrão lateral agora tem tranco no volante (`kick` 0,5), som proporcional e aviso. O som do buraco segue `k`, então fica proporcional ao tamanho. Descontos:<br>• o outro carro não reage (nada de buzina, embora `horn.wav` exista);<br>• quando quem bate é o carro de trás, a multa é repetida a cada 2 s (P1);<br>• o buraco de perto parece tampa de bueiro (P2). |
| 5 | Fluxo relaxante | 10% | **8,4** | Piloto automático com 0 batidas, 1 buraco e 3 poças em 90 s. O caminhão nunca é atingido (0 batidas em 3 casos). Descontos (P1):<br>• depois de uma batida por trás, o cruise derruba a velocidade para **26–29 km/h**, abaixo dos 40 km/h do carro da frente;<br>• para entrar na frente de um carro que está 400 unidades atrás, o jogador leva 3 esbarrões e o multiplicador cai de 3 para 1 em 5 s. |
| 6 | Visual e desempenho | 5% | **8,0** | A placa distante agora é um retângulo verde limpo, sem o texto quebrado. Os pneus têm um brilho em cima, e os reflexos das lanternas ficaram finos e no lugar certo. Continua:<br>• os outdoors (`board*`, tipo 0) ainda quebram o texto a média distância ("PAMONHA…" vira manchas em `chase_lane_change`);<br>• o buraco lê como uma barra clara sobre uma fenda escura;<br>• 33,2 fps (era 36,6), dentro do ruído do renderizador por software. |

Cálculo: 0,30×8,4 + 0,20×8,5 + 0,20×8,0 + 0,15×8,2 + 0,10×8,4 + 0,05×8,0 = 8,29, arredondado para **8,3**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. Depois da batida, o cruise afunda e o carro de trás multa repetidamente (Fluxo +0,3, Feedback +0,2)

**Sintoma (a): o cruise freia demais depois da batida por trás.** O carro fica a 640–960 unidades do carro da frente. A curva de frenagem do cruise, `c.v + signf(dd - 1600) * sqrt(|dd - 1600| * 0.5)`, pede então 40 − 21 = 19 km/h. O jogador cai para 26–29 km/h atrás de um carro a 40 e fica segundos se arrastando. Num jogo relaxante, a batida deveria custar a diferença de velocidade, e não mais.

**Prova (a):**
- `side_merge` do banco: `v_min` de 26,4 (70 km/h, 2.500 unidades) e 23,2 (95 km/h, 3.500 unidades).
- Na minha cópia: 29,2 e 26,5.

**Sintoma (b): o carro de trás multa várias vezes.** Quando o jogador entra na frente de um carro a menos de 500 unidades atrás, o `swipe` o empurra de volta. Enquanto `dxl < 0.5`, esse carro fica preso à velocidade do jogador (`cv = minf(cv, v)`). Com o volante mantido, ele multa a cada 2 s, sem buzinar e sem recuar.

**Prova (b), teste c, jogador a 50 km/h, carro a 60 km/h, 400 unidades atrás:**
- **3 batidas**;
- multiplicador de 3 para **1**;
- o jogador termina em px 0,203, sem conseguir entrar.

**Onde:**
- `scripts/game.gd`, `_process`, bloco do cruise (`if started and not auto`);
- o mesmo arquivo e função, laço do trânsito (`if swipe:`).

**Mudança sugerida (testada em `c6`):**
```gdscript
# cruise: already inside the 1600 gap -> just a little below its speed
if dd < 1600.0:
	tgt = minf(tgt, c.v - (1600.0 - dd) * 0.005)
else:
	tgt = minf(tgt, c.v + sqrt((dd - 1600.0) * 0.5))
...
if swipe:
	...
	if d > TRACK - 500.0:   # it was behind us: it brakes and honks, we keep our lane
		c.z = fposmod(pos - 1300.0, TRACK)
		_sfx("horn")
```

**Resultado na cópia:**
- **v mínima depois da batida de 38,0 / 37,0 km/h** (era 29,2 / 26,5);
- caminhão sem mudança (0 batidas, distância mínima de 1.480–1.600);
- entrar na frente do carro de trás dá **1 batida, multiplicador de 3 para 2**, e o jogador entra na faixa (px final de 0,667);
- piloto automático e `full_drive` sem mudança.

Observação: o `c.z -= …` faz o carro saltar para trás na câmera externa. A versão final deveria fazer o carro frear ao longo de 1 s (por exemplo, um campo `c.hold_t` que limita `cv` a `v - 20`), e não teletransportá-lo.

### P2. O buraco de média distância parece uma chapinha elevada (Pista +0,2, Visual +0,2, Feedback +0,1)

**Sintoma:** o brilho azul (`hw * 2.4` de largura) é mais largo que a parte escura (`hw * 1.6`), e fica em cima dela. O olho lê "barra clara com sombra embaixo", ou seja, algo saliente: um banco, uma grade, uma tampa. Não lê "um buraco". A cor deixou de ser a da tinta da faixa, o que já resolveu o P2 da rodada anterior, mas a forma continua errada.

**Prova:** captura minha da câmera externa, com buracos a 7.000, 12.000 e 18.000 unidades: três "banquinhos" cinza-claros. Em `chase_lane_change`, de perto, a mesma coisa: uma tampa clara sobre uma fenda.

**Onde:** `scripts/world.gd`, `_draw`, ramo do buraco (as duas últimas `draw_rect`).

**Mudança sugerida (testada em `c6`):** a parte escura fica a mais larga, e o brilho fica mais estreito que ela, na borda de cima:
```gdscript
draw_rect(Rect2(f2 - hw * 1.2, hy2, hw * 2.4, 1.5), hole_c.lerp(fog, fa * 0.3))         # the hole is the dark part, and the widest
draw_rect(Rect2(f2 - hw * 0.9, hy2 - 1.0, hw * 1.8, 1.0), glint.lerp(fog, fa * 0.3))   # water glint on its far lip, narrower than the hole
```

Legibilidade medida com o `_visibility_rendered` do banco (limiar de 0,06):

| Câmera | Atual | Variante |
|---|---|---|
| Cabine com chuva | 24.000 | **24.000** (igual) |
| Câmera externa | 27.000 | 27.000 |
| Cabine seca | 27.000 | 25.500 |

Visualmente, a variante vira uma fenda escura com a borda molhada, e não uma tampa. Testei também uma versão só escura, com brilho de 0,5 de altura: ela parece ainda mais buraco, mas a cabine cai para **19.500** (margem de 1,05 s a 95 km/h). Não recomendo.

### P3. Densidade de perigos acima do teto em velocidade de cruzeiro (Pista +0,2)

**Sintoma:** com a batida mais suave, o bot do `full_drive` não perde mais velocidade, e aparece a densidade real: **16,0 perigos/min a 90 km/h**, um a cada 3,75 s. Isso está acima do teto de 14. A 100 km/h, dá cerca de 17,8. Os buracos dos trechos ásperos vêm a cada 12 segmentos, ou seja, a cada 0,28 s a 90 km/h.

**Prova:** `full_drive[1].hazards_per_min` = 16,0 (era 14,5 só por causa da batida-muro).

**Onde:** `scripts/game.gd`, `_build_surface`, `if i - last_hole >= 12 and …`.

**Mudança sugerida (testada em `c6`):** espaçamento mínimo de 16 segmentos:
```gdscript
if i - last_hole >= 16 and randf() < 0.001 + ROUGH[i] * 0.008:
```

**Resultado:**
- **14,0 / 11,0 perigos/min** a 90 / 70 km/h;
- o bot acerta 0/28 e 2/22;
- piloto automático com 0 buracos e 2 poças;
- troca de faixa, toque e curva idênticos.

### P4. Sem mãos na curva: dois comportamentos para o mesmo volante solto (Dirigibilidade +0,2)

**Sintoma:** sem toque prévio, o ímã de centro de faixa deixa o carro abrir 0,094 (70 km/h) / 0,172 (95 km/h). Depois de um toque, a linha mantida compensa 60% da curva, e o carro abre só 0,032–0,054 / 0,042–0,099. O jogador sente a curva "puxar" ou "não puxar" dependendo de ter mexido no volante 1 s antes.

**Prova:** teste (a), 24 combinações, todas com offroad 0.

**Onde:** `scripts/game.gd`, `_process`, ramo `elif free_t > 0.5` do ímã.

**Mudança sugerida (testada em `c6`):** compensar só 30%:
```gdscript
px += (hold_x - px) * minf(1.0, 2.5 * dt) + curve * sp * sp * dt * 0.16 * 0.3
```

**Resultado:**
- com toque, o carro abre **0,034–0,082 / 0,093–0,151**, perto dos 0,094 / 0,172 sem toque, e com offroad 0 nas 24 combinações;
- o `curve_follow`, o toque persistente (0,074) e o desvio dentro da faixa (11/12) ficam idênticos.

Repeti o teste da rodada 05: a mesma compensação no ramo de centro de faixa continua ruim. O bot da curva a 95 km/h sai da pista (0,083 s), e a 70 km/h ele não precisa mais de tecla (RMS de 0,026).

### P5. Outdoors com texto quebrado a média distância (Visual +0,3)

**Sintoma:** o `_sign_far` só vale para placas (`kind == 4`). Os outdoors (`board0–3`, 160×116 px, `ww` 2600) são reduzidos 3–6× com amostragem por ponto, e o texto vira manchas.

**Prova:** recorte de `chase_lane_change` e de `chase_drive`. "PAMONHA QUENTINHA KM 87" aparece como manchas vermelhas e brancas sobre o laranja.

**Onde:**
- `scripts/world.gd`, laço de sprites (`if q.kind == 4 and …`);
- `scripts/game.gd`, `_populate`, nos `_add_spr(… "board%d" …)`.

**Mudança sugerida (não testada):**
1. Dar aos outdoors um tipo próprio (`kind = 5`) em `_populate`.
2. No laço de sprites, quando `kind == 5` e `w < 40` unidades, desenhar a moldura na cor de fundo do outdoor, com duas linhas claras, como `_sign_far` (lida da cor do pixel (8, 8) da textura).

Fora do top 5:
- Os pneus agora têm 7k e uma faixa clara, mas na externa eles ainda leem como blocos pretos com pontos brancos de respingo. Está aceitável.
- A janela de "lado a lado" é assimétrica: 250 unidades à frente e 500 atrás. Já a batida por trás começa a 1.250 à frente. Dá para cortar a frente de um carro com o nariz dele 600–1.200 atrás do jogador sem nenhuma reação.

## 3. Problemas da própria métrica (descontados na nota)

- **"Duas rodas" é impossível.** As rodas ficam em ±0,2, e o alcance do buraco é `f.w + 0.06`, no máximo 0,18. Nenhum buraco (largura de 0,07–0,12) acerta as duas rodas. Um buraco centrado passa **entre** as rodas sem efeito: no teste b, "both" deu 0 px em todos os casos. Isso é coerente com o desenho (o buraco cabe entre os pneus), então não puni o jogo. Mas o `× 1.3` que sugeri na rodada 05 é código morto, e o `pothole_response` do banco só mede uma roda.
- **`side_merge.min_distance_while_overlapping` mede a coisa errada.**
  - Usa a distância absoluta (inclui o carro já para trás).
  - Depois do `swipe`, `px` fica exatamente a 0,46 do carro, então a condição `< 0.46` nunca vale lado a lado.
  - O número (630–960) só mostra a zona de batida por trás.
  - `max_drop_per_frame_kmh` = 0 nos casos de esbarrão lateral não quer dizer "sem batida".
  
  Sugiro registrar o maior salto lateral por quadro, o multiplicador antes e depois, e o px final.
- **O `full_drive` depende da ordem dos cenários.** Rodado sozinho, o caso de 70 km/h dá 0 batidas. Depois de outro cenário, dá 1 (a `t = 106 s`: um esbarrão com um carro 358 unidades atrás, quando o bot volta para a faixa logo depois de ultrapassar). Algum estado aleatório não é ressemeado em `make()`. As duas batidas do banco são do bot, que corta rente; não são do jogo.
- **`hazards_per_min` depende da velocidade real do bot.** A subida de 14,5 para 16,0 vem do bot não perder mais velocidade na batida. A pista não mudou.
- A câmera externa ainda satura a grade de visibilidade: 33 px a 27.000, o último ponto.

## 4. Comparação com a rodada 05

A nota foi de **8,1 para 8,3**. As cinco sugestões entraram, e os números previstos na cópia da rodada 05 se confirmaram:
- maior queda num quadro de 6,0 / 10,2 / 11,1 km/h;
- corpo do buraco de 8,8 / 11,8 / 14,2 px;
- curva com toque abrindo 0,032–0,099.

| Métrica | Rodada 05 | Rodada 06 | Alvo |
|---|---|---|---|
| Troca de faixa: tempo / overshoot / assenta | 0,82–0,83 s / 0,042–0,050 / 1,20–1,32 s | igual | 0,6–1,0 / < 0,10 / < 1,5 |
| Toque: pico / depois de 2,5 s | 0,074–0,075 / 0,074–0,075 | igual | 0,05–0,12 |
| Curva força 3: RMS / offroad | 0,126–0,138 / 0 | igual | < 0,15 / 0 |
| Sem mãos na curva, com toque: desvio máximo | 0,010–0,035 | **0,032–0,099** | perto de "sem toque" (0,094–0,172) |
| Buraco 0,07 → 0,12 a 100 km/h (corpo) | igual para todos | **12,3 → 16,4 px** | proporcional |
| Arfagem do buraco a 95 km/h | 23,4 px | 22,5 px | ≤ 25 |
| Lado a lado com um carro | atravessa (19–44 unidades) | **esbarrão, salto de ≤ 0,020/quadro** | não atravessar |
| Batida por trás: queda num quadro | 21,6–37,1 km/h | **6,0–11,1 km/h** | suave |
| Batida por trás: v mínima | 29–31 km/h | 23–29 km/h | ≈ velocidade do carro da frente |
| Perigos/min (70 / 90 km/h) | 11,5 / 14,5 | 11,5 / **16,0** | 6–14 |
| Bot: perigos acertados | 4,3% / 3,4% | 4,3% / 3,1% | ≤ 15% |
| Cabine com chuva: legível até | 25.500 (qualquer pixel) | 24.000 (luminância > 0,06) | margem ≥ 1,5 s |
| Placa "PISTA IRREGULAR" | 1,47 s antes | **2,0 s antes** | ≥ 2 s |
| Piloto automático em 90 s | 0 / 1 / 3 | igual | — |
| FPS (software) | 36,6 | 33,2 | ~40 |

- **Melhorou:**
  - não dá mais para atravessar carros;
  - a batida por trás deixou de ser um muro;
  - o buraco tem tamanho;
  - a curva com toque pede um pouco de volante;
  - o buraco tem cor de água, e não de tinta;
  - as placas de longe estão limpas;
  - os pneus e os reflexos estão melhores;
  - a placa de aviso vem 2 s antes.
- **Piorou:**
  - a v mínima depois da batida por trás (23–29 km/h; antes, a batida-muro deixava 29–31);
  - a densidade aparente de perigos a 90 km/h, que é efeito colateral de o bot não perder mais velocidade;
  - os esbarrões repetidos com o carro de trás, um caso novo que o `swipe` criou.
- **Ficou igual:** o assentamento sempre de 1,683 s e o texto quebrado nos outdoors.
- **Novos achados:**
  - o buraco "chapinha" (P2);
  - a densidade real (P3);
  - a multa repetida e o carro de trás preso ao jogador (P1);
  - "duas rodas" impossível pela geometria;
  - a dependência de ordem no `full_drive` (seção 3).
