# Critérios de avaliação — Chuva na BR

O avaliador joga pelo banco de testes (`qa/run_qa.sh`), olha as capturas em `qa/shots/`, lê o código e dá notas de 0 a 10.
O jogo é **relaxante**: sem game over, carro antigo de molas macias, chuva, rádio. A dificuldade deve vir de dirigir bem,
não de punição. Notas 9–10 exigem que um jogador exigente de jogos de corrida arcade elogie a sensação de dirigir.

| # | Categoria | Peso | O que olhar (métricas em `qa/metrics/latest.json`) | Faixa boa |
|---|---|---|---|---|
| 1 | Dirigibilidade | 30% | `lane_change`: atraso de resposta, tempo até a faixa, ultrapassagem (overshoot) e assentamento; `tap`: controle fino; `curve_follow`: erro e saída de pista na curva mais fechada | resposta 0,10–0,20 s; troca de faixa 0,6–1,0 s; overshoot < 0,10; assenta < 1,5 s; toque de 0,15 s move 0,05–0,12; curva sem sair da pista (offroad 0 s) e erro RMS < 0,15 |
| 2 | Suspensão e sensação | 20% | `pothole`: pico, oscilações, assentamento, rolagem; `ride`: arfagem em px na tela | molas macias: 1–2 oscilações visíveis, assenta em 1,2–2,5 s; arfagem máxima na tela 8–25 px (mais que isso enjoa, menos é duro) |
| 3 | Pista e desafio | 20% | `full_drive`: perigos por minuto, buracos acertados por um bot cuidadoso, trocas de faixa; `visibility`: margem para desviar | 6–14 perigos/min; bot cuidadoso acerta ≤ 15% dos perigos; margem ≥ 1,5 s a 95 km/h |
| 4 | Feedback | 15% | código de som, avisos (toast), tremor do volante, respingos; capturas `cockpit_pothole`, `chase_puddle` | todo evento tem resposta visual + sonora proporcional à força |
| 5 | Fluxo relaxante | 10% | `autopilot`, `full_drive.car_bumps`, frequência de avisos, punições | piloto automático sem batidas e com poucos buracos; avisos não poluem |
| 6 | Visual e desempenho | 5% | capturas; FPS (o renderizador do teste é por software, ~40 fps é normal) | legível, pixel art coerente, nada cortado |

Nota final = média ponderada, com uma casa decimal.

Formato do relatório (`qa/reports/round-NN.md`):
1. Nota final e tabela com as 6 notas e uma frase de justificativa cada.
2. Os 5 problemas mais importantes, do maior para o menor ganho de nota, cada um com: sintoma, métrica ou captura que prova, arquivo e função provável, mudança sugerida.
3. O que melhorou ou piorou em relação à rodada anterior (se houver).
