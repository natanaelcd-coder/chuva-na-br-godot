# Critérios de avaliação — Chuva na BR

O avaliador joga pelo banco de testes (`qa/run_qa.sh`), olha as capturas em `qa/shots/`, lê o código e dá notas de 0 a 10.
O jogo é **relaxante**: sem game over, carro antigo que ainda flutua um pouco (mas assenta logo), chuva, rádio. A dificuldade deve vir de dirigir bem,
não de punição. Notas 9–10 exigem que um jogador exigente de jogos de corrida arcade elogie a sensação de dirigir.

| # | Categoria | Peso | O que olhar (métricas em `qa/metrics/latest.json`) | Faixa boa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | `lane_change`: atraso de resposta, tempo até a faixa, ultrapassagem (overshoot) e assentamento; `tap`: controle fino; `curve_follow`: erro e saída de pista na curva mais fechada | resposta 0,10–0,20 s; troca de faixa 0,6–1,0 s; overshoot < 0,10; assenta < 1,5 s; toque de 0,15 s move 0,05–0,12; curva sem sair da pista (offroad 0 s) e erro RMS < 0,15 |
| 2 | Suspensão e sensação | 20% | `pothole`: pico, oscilações, assentamento, rolagem; `ride`: arfagem em px na tela; `lane_change.roll_*`: lado e volta da rolagem; `jump`: tempo no ar, pouso; `tests/feat_mola.gd` (lado da rolagem e da arfagem nas duas câmeras, mola por carro, pulo nas 3 estradas) | mola firme de carro antigo (gosto do dono a partir da rodada 10): **~1 oscilação visível** (0,5 a 1,5), assenta em **0,8–1,6 s** (o GT pode assentar em ~0,5 s; acima de 1,6 s é mole demais), arfagem máxima na tela 6–22 px (mais que isso enjoa, menos é duro); os três carros continuam diferentes (besouro flutua, picape quica, GT firme); a carroceria rola para **fora** da curva e contra cada metade da troca de faixa, a volta não passa da ida e sobra no máximo um vai e volta; freando o nariz mergulha; nas cristas o carro só sai do chão acima do limiar da estrada (terra ~55, BR ~65, expressa ~105 km/h), fica 0,2–0,5 s no ar e pousa sem perder direção nem velocidade |
| 3 | Pista e desafio | 20% | `full_drive`: perigos por minuto, buracos acertados por um bot cuidadoso, trocas de faixa; `visibility`: margem para desviar | 6–14 perigos/min; bot cuidadoso acerta ≤ 15% dos perigos; margem ≥ 1,5 s a 95 km/h |
| 4 | Feedback | 15% | código de som, avisos (toast), tremor do volante, respingos; capturas `cockpit_pothole`, `chase_puddle` | todo evento tem resposta visual + sonora proporcional à força |
| 5 | Fluxo relaxante | 10% | `autopilot`, `full_drive.car_bumps`, frequência de avisos, punições | piloto automático sem batidas e com poucos buracos; avisos não poluem |
| 6 | Visual e desempenho | 5% | capturas; FPS (o renderizador do teste é por software, ~40 fps é normal) | legível, pixel art coerente, nada cortado |

Nota final = média ponderada, com uma casa decimal.

Formato do relatório (`qa/reports/round-NN.md`):
1. Nota final e tabela com as 6 notas e uma frase de justificativa cada.
2. Os 5 problemas mais importantes, do maior para o menor ganho de nota, cada um com: sintoma, métrica ou captura que prova, arquivo e função provável, mudança sugerida.
3. O que melhorou ou piorou em relação à rodada anterior (se houver).
