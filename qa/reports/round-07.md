# Rodada 07: Chuva na BR

Data: 2026-11-12.

## Fontes

- `qa/run_qa.sh`: métricas em `qa/metrics/latest.json`, 6 capturas em `qa/shots/`, `fps.txt` (28,9 fps; ver seção 3) e `visibility.json`.
- Leitura de `scripts/game.gd`, `scripts/world.gd`, `scripts/cockpit.gd`, `scripts/hud.gd` e `tests/test_drive.gd`.

### O que mudou desde a rodada 06

Comparei com `qa/snapshots/round-06/`. Mudaram `game.gd`, `world.gd` e `tests/test_drive.gd`. As cinco sugestões da rodada 06 entraram:

- **P1:**
  - cruise dentro da distância de 1.600: `c.v - (1600 - dd) * 0.005`, sem afundar abaixo do carro da frente;
  - carro mais rápido logo atrás (até 1.200): buzina (`horn`), freia para `v - 20` por 1,2 s (`hold_t`) e só buzina de novo depois de 5 s (`honk_t`);
  - o `swipe` agora vale só para carros à frente; o caso "atrás e encostado" virou `behind_overlap`, que multa sem empurrar.
- **P2:** no buraco, a fenda escura (2,4·hw × 1,5) ficou mais larga que o brilho (1,8·hw × 1).
- **P3:** espaçamento mínimo de 16 segmentos entre buracos.
- **P4:** compensação de 30% da curva na linha mantida.
- **P5:** outdoors com `kind = 5` e `_board_far` (painel liso na cor do outdoor, com duas linhas) abaixo de 40 unidades.

No banco:
- `make()` ressemeia depois da montagem;
- `side_merge` ganhou salto lateral, multiplicador e px final;
- entrou o cenário `cut_in_front`.

### Testes extras na minha cópia

Fiz tudo em duas **cópias** no meu diretório temporário (`scratchpad/c7`, `c7g`) e em uma cópia da rodada 06 (`c6r`). Nenhum arquivo do jogo foi alterado. Instrumentei a cópia com contadores de buzina e um log de batidas (tipo, distância, dx, velocidades). Rodei:

- (a) cruise lento com trânsito mais rápido atrás: 50/30/45 km/h, 60 s cada, nas três faixas;
- (b) preso atrás de um carro a 40 km/h, com um carro a 58 km/h vindo por trás (60 s);
- (c) entrar na faixa de um carro a 65 km/h que está 300–2.500 atrás;
- (d) curva mais fechada sem mãos: 18 combinações de faixa, velocidade e toque;
- (e) poça sob o carro, sem mãos, a 70 e 95 km/h;
- (f) volante segurado contra o canteiro central a 50 e 95 km/h;
- (g) **piloto automático em 8 sementes × 120 s**;
- (h) `full_drive` a 70/90/**100** km/h;
- (i) capturas do outdoor a 60/45/38/32 segmentos;
- (j) FPS da rodada 06 contra o atual, duas vezes cada, sem outro processo rodando;
- (k) as variantes de código abaixo, cada uma medida antes de ser recomendada.

## 1. Nota final: **8,4 / 10**

| # | Categoria | Peso | Nota | Justificativa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | **8,5** | Tudo dentro da faixa boa:<br>• resposta de 0,167–0,183 s, troca de faixa em 0,82–0,83 s, overshoot de 0,042–0,050, assentamento de 1,20–1,32 s;<br>• toque de 0,074–0,075, que fica onde o jogador deixou;<br>• curva força 3 com RMS de 0,126/0,138 e offroad 0.<br>O P4 da rodada 06 está resolvido. Sem mãos na curva, o desvio depois de um toque fica em 0,068–0,114 (70 km/h) e 0,141–0,207 (95 km/h), contra 0,094 e 0,172 sem toque: a mesma sensação, para os dois lados. Descontos (P4):<br>• na curva mais fechada a 95 km/h, o erro máximo é de **0,322**, quase metade da faixa (0,333), e o bot fica com a tecla apertada 67% do tempo, com 1,2 toques/s;<br>• o desvio dentro da faixa com 0,4 s de antecedência falha a 95 km/h (11 de 12). |
| 2 | Suspensão e sensação | 20% | **8,5** | Sem mudança, e continua boa:<br>• corpo de 8,8 / 11,8 / 14,2 px a 40/70/95 km/h;<br>• arfagem de 13,0–22,5 px no buraco e de 14,0 / 16,0 / 18,8 px na estrada, sempre ≤ 25;<br>• 1,5 oscilação;<br>• puxão de 0,022–0,037.<br>A poça puxa 0,049 / 0,069 e o carro volta para a faixa sozinho (teste e). Descontos, os mesmos da rodada 06:<br>• o assentamento é sempre 1,683 s, seja qual for o buraco;<br>• o "duas rodas" (×1,3) continua código morto (seção 3). |
| 3 | Pista e desafio | 20% | **8,3** | **11,0 / 14,0 perigos/min** a 70/90 km/h (era 16,0). O bot cuidadoso acerta 2/22 = 9,1% e 2/28 = 7,1% (buracos + poças). A cabine com chuva lê o buraco até 24.000, com margem de 1,83 s a 95 km/h. A placa avisa 2 s antes. Descontos:<br>• **17,0 perigos/min a 100 km/h**, a velocidade máxima do cruise (P2), e 14,0 a 90 já está no teto;<br>• a média distância, o brilho azul ainda é o traço mais forte do buraco (P5). |
| 4 | Feedback | 15% | **8,4** | A buzina finalmente toca: o carro de trás buzina uma vez e freia por 1,2 s quando o jogador entra na frente dele (c: 1 buzina com 700–1.600 de distância, sem repetir). Os outdoors e as placas de longe estão limpos. Descontos:<br>• o motor sobe de tom em linha reta, de 0,76× a 1,88×, enquanto o painel mostra 1ª → 4ª. Não há troca de marcha no som (P3);<br>• no canteiro central, o carro para em px −1,06 sem som de raspão nem aviso, mas perde o multiplicador inteiro e cai para 30 km/h (seção 2, fora do top 5);<br>• a batida do piloto automático multa o jogador (P1). |
| 5 | Fluxo relaxante | 10% | **8,2** | A batida por trás ficou justa:<br>• v mínima de **36,9 / 35,3 km/h** atrás de um carro a 40 (era 26,4 / 23,2);<br>• `cut_in_front`: 1 batida, multiplicador de 3 para 2, e o jogador entra na faixa;<br>• o carro que alcança um jogador lento fica a 1.307–1.345 atrás, sem buzinar (a).<br>Descontos (P1): **o piloto automático bate**. Em 8 sementes × 120 s, metade tem 1 batida por trás. Todas foram a 63–65 km/h contra carros de 34–47 km/h, a 1.210–1.235 de distância, no meio de uma troca de faixa. A semente do banco (3) é das que não batem. Cada batida dá "OPA! SEM PRESSA" e tira um nível do multiplicador, logo depois de "SÓ CURTA A VIAGEM". |
| 6 | Visual e desempenho | 5% | **8,3** | Os outdoors não quebram mais. Ao longe, aparece um painel liso na cor certa com duas linhas; a partir de cerca de 45 segmentos, o texto é legível ("PAMONHA QUENTINHA KM 87"). O buraco perto agora é uma fenda escura com a borda molhada, e não mais uma tampa. Descontos:<br>• no `board3` (laranja com texto escuro), as linhas de longe saem creme. O pixel de amostra cai no fundo, e o código usa a cor creme de reserva;<br>• o brilho do buraco ainda domina a média distância;<br>• os pneus na câmera externa ainda são blocos;<br>• FPS: ver seção 3. Não houve regressão. |

Cálculo: 0,30×8,5 + 0,20×8,5 + 0,20×8,3 + 0,15×8,4 + 0,10×8,2 + 0,05×8,3 = 8,405, arredondado para **8,4**.

## 2. Os 5 problemas mais importantes (do maior para o menor ganho de nota)

### P1. O piloto automático bate por trás em metade das sementes (Fluxo +0,4, Feedback +0,1)

**Sintoma:** com `auto` ligado, o bloco do cruise (`if started and not auto`) não roda. A única defesa é o freio de `_car_ahead`: `v -= 30·dt·(1 − ahead/2500)`. Esse freio briga com a aceleração de +13 km/h/s do próprio cruise e só vence abaixo de 1.417 unidades. Quando o piloto troca de faixa (desvio de buraco, posto ou faixa ocupada) para uma faixa com um carro 20–30 km/h mais lento, não dá tempo de perder a diferença antes da zona de batida (1.250). Resultado: o jogador que pediu "só curta a viagem" recebe "OPA! SEM PRESSA" e perde um nível do multiplicador.

**Prova (teste g, 8 sementes × 120 s, código atual):**

| Semente | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Batidas | 0 | 1 | 0 | 0 | 1 | 0 | 1 | 1 |

O log das 4 batidas: `rear`, d = 1.210–1.233, v = 63,1–65,2 contra 34,4–47,1, px no meio da troca (dx de 0,24–0,41). Com outra pista (espaçamento 18), deram **8 batidas, em 5 das 8 sementes**. O banco usa só a semente 3, por isso mostra 0.

**Onde:** `scripts/game.gd`, `_process`, bloco do cruise e ramo `if is_auto:`.

**Mudança sugerida (testada em `c7`):** o piloto usa a mesma curva de frenagem do cruise e olha também a faixa para onde está indo:
```gdscript
if started:   # cruise control (and the autopilot) yields to the car ahead instead of ramming it
	for c in cars:
		if c.dir > 0 and (absf(c.x - px) < 0.46 or (auto and absf(c.x - LANES[lane]) < 0.3)):
```
**Resultado:** **0 batidas em 16 de 16 corridas** (8 sementes × 2 pistas). Os buracos ficaram iguais: 11 em 16 min na pista atual e 12 na outra, antes e depois. O banco e o jogador não mudam, porque o termo novo só vale com `auto`.

Também sugiro não multar quando `auto` está ligado (`if bump_t <= 0.0 and started and not auto:` só para o multiplicador; o som e o tranco ficam).

### P2. 17 perigos/min na velocidade máxima do cruise (Pista +0,2)

**Sintoma:** o espaçamento é em segmentos, então a densidade cresce com a velocidade:
- 11,0 /min a 70 km/h;
- 14,0 /min a 90 km/h (no teto);
- **17,0 /min a 100 km/h**, um perigo a cada 3,5 s.

O cruise vai até 100 km/h, e 100 é a velocidade natural de quem quer "dirigir bem".

**Prova:** `full_drive` a 100 km/h na cópia: 34 perigos em 120 s. O banco só mede 70 e 90 km/h.

**Onde:** `scripts/game.gd`, `_build_surface`, `if i - last_hole >= 16 and …`.

**Mudança sugerida (testada em `c7`):** espaçamento de 20 segmentos.

| Espaçamento | 70 km/h | 90 km/h | 100 km/h | Bot acerta | Piloto automático |
|---|---|---|---|---|---|
| 16 (atual) | 11,0 | 14,0 | 17,0 | 2/22, 2/28, 3/34 | 0 / 0 / 2 |
| 18 | 12,0 | 15,0 | 19,5 | — | 1 batida |
| **20** | **9,0** | **10,5** | **13,0** | 0/18, 0/21, 4/26 (15%) | 0 / 1 / 1 |

O espaçamento 18 piorou porque muda a sequência aleatória e, com ela, a pista e o trânsito. A comparação só vale entre pistas inteiras. Com 20, as três velocidades ficam dentro de 6–14; a 100 km/h o bot fica no limite de 15%, o que é aceitável na velocidade máxima. Junto com o P1, o piloto automático não bate em nenhuma das duas pistas.

### P3. O motor não troca de marcha (Feedback +0,2)

**Sintoma:** o painel mostra N → 1ª → 2ª → 3ª → 4ª (em 16, 32 e 52 km/h), mas o som segue `pitch_scale = (38 + 0,75·v) / 60` em linha reta:
- 0,76× a 10 km/h;
- 1,28× a 52 km/h;
- 1,51× a 70 km/h;
- **1,88× a 100 km/h**: o mesmo loop quase uma oitava acima, chiando em cruzeiro.

Para um "carro antigo de molas macias", a queda de giro na troca e o ronco grave em 4ª são metade do charme. Hoje o som e o painel se contradizem.

**Prova:** leitura de `scripts/game.gd`, bloco "audio follows the drive". Não há nenhum estado de marcha no áudio. A marcha só existe na string do HUD.

**Onde:** `scripts/game.gd`, `_process`, `a_engine.pitch_scale`.

**Mudança sugerida (não testada de ouvido; valores calculados):** escalonamento de cerca de 0,67× entre as marchas, como numa caixa de 4 marchas antiga:
```gdscript
var g_lo: float = 0.0 if v < 16.0 else (16.0 if v < 32.0 else (32.0 if v < 52.0 else 52.0))
var g_hi: float = 16.0 if v < 16.0 else (32.0 if v < 32.0 else (52.0 if v < 52.0 else 110.0))
var rpm := clampf((v - g_lo) / (g_hi - g_lo), 0.0, 1.0)
a_engine.pitch_scale = lerpf(a_engine.pitch_scale, 0.9 + 0.45 * rpm, minf(1.0, dt * 8.0))   # the shift sags over ~0.15 s
```
Dá 1,04× a 70 km/h e 1,27× a 100 km/h (hoje, 1,51× e 1,88×), com uma queda de 1,35× para 0,9× em cada troca. Opcional: `pitch_v -= 0.15` no quadro da troca, um pequeno tranco do corpo.

### P4. Curva fechada a 95 km/h: muito "serrote" no teclado (Dirigibilidade +0,2)

**Sintoma:** na curva mais fechada a 95 km/h, mesmo o bot com reação de 0,15 s chega a 0,322 de erro, quase na faixa vizinha. Ele segura a tecla 67% do tempo, com 1,2 toques/s. Com 0,25 s de reação (um humano comum), sai da pista por 0,5 s (erro máximo de 0,468). O desvio dentro da faixa com 0,4 s de antecedência também falha a 95 km/h. Os dois sintomas vêm da mesma causa: o volante leva 0,2 s para chegar ao fim (`rate` 5/s), e o empurrão da curva vale `0,16·sp²`.

**Prova:** `curve_follow[1]`: max_error de 0,322 e held de 0,672; `nudge_dodge[1]`, lead 0,4: `dodged: false`. Na cópia, `curve_follow(95, 0.25)` deu offroad de 0,50 s.

**Onde:** `scripts/game.gd`, `_process`:
- `var rate := 5.0 if absf(dir) > absf(steer) else 12.0`;
- `px += vx * dt - (… curve * sp * sp * dt * 0.16)`.

**Mudança sugerida (testada em `c7`):** `rate` de 5 para **6** e o empurrão de 0,16 para **0,14**.

| Métrica | Atual | Variante | Alvo |
|---|---|---|---|
| Troca de faixa: resposta / tempo / overshoot / assenta | 0,167–0,183 / 0,817–0,833 / 0,042–0,050 / 1,20–1,32 | 0,167 / 0,80–0,817 / 0,042–0,050 / 1,18–1,30 | dentro |
| Toque de 0,15 s | 0,074–0,075 | 0,094–0,095 | 0,05–0,12 |
| Curva 95 km/h: RMS / máx | 0,138 / 0,322 | 0,133 / **0,289** | < 0,15 |
| Curva 95 km/h, reação de 0,25 s: offroad | 0,50 s | 0,43 s | — |
| Desvio dentro da faixa a 95 km/h | 5/6 | **6/6** | — |
| Sem mãos na curva (18 combinações) | 0,068–0,207, offroad 0 | 0,070–0,187, offroad 0 | — |

Testei também `rate` 7: o toque sobe para 0,111–0,112, perto do teto de 0,12. Não recomendo.

### P5. A média distância, o buraco ainda é um traço claro (Visual +0,2, Pista +0,1)

**Sintoma:** as duas `draw_rect` do buraco têm altura fixa: a fenda escura tem 1,5 de altura e o brilho, 1,0. A largura acompanha `hw`. Na média distância (`hw` de cerca de 9 unidades), isso vira uma barra azul-clara de 16 × 1 sobre uma fenda de 22 × 1,5. A barra clara é o traço que o olho pega primeiro. Perto, a fenda escura agora domina, e isso ficou bom.

**Prova:** recorte ampliado de `chase_drive`, buraco à esquerda em cerca de (400, 207): barra azul com uma sombra fina embaixo. Em `chase_lane_change`, o buraco perto já lê como fenda.

**Onde:** `scripts/world.gd`, `_draw`, ramo do buraco (as duas últimas `draw_rect`).

**Variantes testadas em `c7g`** (legibilidade com o `_visibility_rendered` do banco):

| Variante | Cabine com chuva | Cabine seca | Externa | Aparência |
|---|---|---|---|---|
| Atual | 24.000 (1,83 s de margem) | 25.500 | 27.000 | barra clara sobre fenda |
| Fenda 2,0 de altura + brilho de 0,9·hw × 0,5, fora do centro | **21.000 (1,50 s)** | 21.000 | 27.000 | buraco escuro com reflexo pequeno: o melhor visual |
| Fenda 2,0 + brilho de 1,2·hw × 1,0, fora do centro | 21.000 (22.500 dá 29 px, 1 abaixo do limiar) | 24.000 | 27.000 | meio-termo |
| Brilho que esmaece quando `hw` < 4,5 | 24.000 | 25.500 | 27.000 | igual ao atual (`hw` já passa de 4,5 na média distância) |

**Recomendação:** a terceira linha (fenda de 2,0 + brilho de 1,2·hw × 1,0 deslocado para a esquerda), compensando a visibilidade com mais contraste no `hole_c` (`road0.lerp(Color.BLACK, 0.8)`, não testado). Isso daria a forma certa sem descer abaixo de 1,5 s de margem.

```gdscript
draw_rect(Rect2(f2 - hw * 1.2, hy2 - 0.5, hw * 2.4, 2.0), hole_c.lerp(fog, fa * 0.3))
draw_rect(Rect2(f2 - hw * 0.9, hy2 - 1.0, hw * 1.2, 1.0), glint.lerp(fog, fa * 0.3))
```

Fora do top 5:
- **Canteiro central silencioso.** Com o volante para a esquerda, o carro chega a px −1,06 em 0,6 s e para ali (`px = -1.06; vx = maxf(vx, 0)`). Não há som de raspão nem aviso, mas `off` zera o multiplicador e limita a velocidade a 30 km/h. Sugestão: na hora do contato com `vx < -0.2`, tocar `bump` com volume ∝ |vx|, `kick = -0.4`, `roll_v += 0.3` e o aviso "EPA, GUARD-RAIL!" (com o mesmo `bump_t`).
- **`_board_far` do `board3`.** O pixel de amostra (80, 34) cai no fundo laranja, e o código usa o creme de reserva. As linhas deveriam ser escuras, como o texto. Sugestão: amostrar a primeira cor diferente do fundo numa linha horizontal em 0,3·h.
- **Batida ao trocar de faixa logo atrás de um carro.** No `full_drive` aparece uma batida `rear` a d = 1.248, com 4 km/h de diferença, quando o bot entra na faixa. O cruise só olha carros com `dx < 0.46`, que é o mesmo limiar da zona de batida, então não há tempo de reagir. É culpa do bot, que troca sem olhar, mas um jogador sente a mesma coisa.
- **O piloto automático acerta buracos de forma desigual.** Na semente 5, foram 5 buracos em 120 s; na 6, 3. A média é baixa (0,7/min).

## 3. Problemas da própria métrica (descontados na nota)

- **FPS de 28,9 no `fps.txt` oficial é falso.** Rodei uma sonda minha em paralelo com o `run_qa.sh`, e o renderizador por software dividiu a CPU. Medindo de novo sem nada em paralelo:
  - rodada 06: 35,6 / 34,2;
  - atual: 33,9 / 36,5.

  Não houve regressão. Considerei cerca de 35 fps.
- **O `autopilot` do banco usa uma única semente (3), e ela não bate.** As sementes 2, 5, 7 e 8 batem. Sugiro rodar 4 sementes × 90 s e registrar a soma.
- **O `full_drive` ainda varia entre sem janela e com janela.** Sem janela, o resultado agora é estável entre ordens (corrigido com o `seed()` em `make()`): 1 batida / 2 buracos a 70 km/h, igual ao oficial. Com janela (xvfb), dá 0 batidas / 1 buraco a 70 km/h, e a batida a 90 km/h muda de distância (1.007 contra 1.146). Algum estado ligado ao desenho entra na simulação. O banco oficial roda as métricas sem janela, então o número publicado é consistente.
- **O `curve_follow` não mede o pior caso humano.** Um bot de 0,25 s sai da pista a 95 km/h. Por outro lado, ele é puramente reativo, e um humano antecipa a entrada da curva. Por isso descontei pouco e usei o dado só para escolher a variante do P4.
- **As 4 batidas do `side_merge` são do próprio bot,** que muda de faixa às cegas para cima de um carro 30 km/h mais lento, ou para o lado dele. Agora o banco mostra o multiplicador (3 → 2) e o px final (0,667), como pedi. O salto lateral máximo por quadro é de 0,017–0,019.
- **Herdado da rodada 06:** o "duas rodas" (×1,3) é impossível pela geometria (rodas em ±0,2, alcance ≤ 0,18), e o `pothole_response` mede só uma roda. A visibilidade da câmera externa satura no último ponto da grade (27.000).
- **As linhas da cabine seca e da cabine com chuva são quase idênticas** até 21.000. As gotas ficam acima da faixa do horizonte (y ≥ 40, mas o buraco distante está em cerca de y 64–70), e quase não se sobrepõem a ele. A métrica "com chuva" quase não mede chuva.

## 4. Comparação com a rodada 06

A nota foi de **8,3 para 8,4**. As cinco sugestões entraram, e os números previstos na cópia da rodada 06 se confirmaram:
- v mínima depois da batida de 36,9 / 35,3 (previsto: 38,0 / 37,0);
- `cut_in_front` com 1 batida, multiplicador de 3 para 2, e o jogador entra na faixa;
- 11 / 14 perigos/min;
- sem mãos na curva, 0,068–0,207.

A subida é pequena porque achei um problema que as rodadas anteriores não viam: o piloto automático bate (P1).

| Métrica | Rodada 06 | Rodada 07 | Alvo |
|---|---|---|---|
| Troca de faixa: tempo / overshoot / assenta | 0,82–0,83 s / 0,042–0,050 / 1,20–1,32 s | igual | 0,6–1,0 / < 0,10 / < 1,5 |
| Toque: pico / depois de 2,5 s | 0,074–0,075 | igual | 0,05–0,12 |
| Curva força 3: RMS / máx / offroad | 0,126–0,138 / 0,266–0,322 / 0 | igual | < 0,15 / — / 0 |
| Sem mãos na curva: com toque × sem toque (95 km/h) | 0,042–0,099 × 0,172 | **0,141–0,207 × 0,172** | parecidos |
| Batida por trás: v mínima | 23,2–26,4 km/h | **35,3–36,9 km/h** | ≈ 40 |
| Entrar na frente do carro de trás | 3 batidas, multiplicador 3 → 1, não entra | **1 batida, 3 → 2, entra, buzina** | — |
| Perigos/min (70 / 90 / 100 km/h) | 11,5 / 16,0 / — | **11,0 / 14,0 / 17,0** | 6–14 |
| Bot: perigos acertados | 4,3% / 3,1% | 9,1% / 7,1% | ≤ 15% |
| Buraco: corpo / arfagem a 95 km/h | 14,2 / 22,5 px | igual | ≤ 25 |
| Cabine com chuva: legível até | 24.000 (margem de 1,83 s) | igual | ≥ 1,5 s |
| Piloto automático, semente do banco (90 s) | 0 / 1 / 3 | 0 / 0 / 2 | — |
| Piloto automático, 8 sementes × 120 s | não medido | **4 batidas** | 0 |
| Outdoor de longe | texto em manchas | painel limpo; legível a partir de cerca de 45 segmentos | — |
| FPS (software, sem carga paralela) | 33,2 (34,2–35,6) | 33,9–36,5 | ~40 |

- **Melhorou:**
  - a batida por trás custa a diferença de velocidade, não mais que isso;
  - entrar na frente de alguém dá buzina e uma freada do outro, não três multas;
  - a densidade a 70 e 90 km/h está dentro da faixa;
  - a curva sem mãos tem uma sensação só;
  - os outdoors estão limpos;
  - o buraco de perto lê como buraco.
- **Piorou:** nada medido piorou. O `fps.txt` oficial mostra 28,9, mas é artefato da minha sonda em paralelo (seção 3).
- **Ficou igual:**
  - o assentamento é sempre 1,683 s;
  - o "duas rodas" continua morto;
  - os pneus em blocos na câmera externa;
  - o brilho do buraco a média distância.
- **Novos achados:**
  - o piloto automático bate em metade das sementes e multa o jogador (P1);
  - 17 perigos/min a 100 km/h (P2);
  - o motor sem marchas (P3);
  - o "serrote" na curva fechada a 95 km/h e a saída de pista com 0,25 s de reação (P4);
  - o canteiro central silencioso;
  - a cor errada do `board3` de longe;
  - a métrica "com chuva" que quase não mede chuva.
