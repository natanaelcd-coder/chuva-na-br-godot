# Geração por IA

Clientes mínimos (só biblioteca padrão do Python). As chaves vêm das variáveis
`RETRODIFFUSION_API_KEY`, `PIXELLAB_API_KEY`, `ELEVENLABS_API_KEY` ou são injetadas
pelos segredos de rede da sessão.

    python3 tools/ai/rd.py out.png rd_core__default 384 216 "prompt" [--ref ref.png] [--seed 7] [--bg]
    python3 tools/ai/pixellab.py out.png 384 216 "descrição" [--seed 7] [--palette pal.png] [--bg]
    python3 tools/ai/eleven.py tts out.mp3 VOICE_ID "texto"
    python3 tools/ai/eleven.py sfx out.mp3 10 "descrição do som" [--loop]

Retro Diffusion: preço grátis com `check_cost`; plus US$0,06 e core US$0,10 em 384x216.
PixelLab: conta por gerações do plano. Primeiro teste em docs/ia/teste1/.

## Cabines (PixelLab)

As três cabines vêm de `/generate-image-v2` (384x216, referência = a cabine antiga com os vidros em magenta,
"... The windshield and side windows are flat solid magenta. No steering wheel, no hands."). Brutos escolhidos em
`docs/ia/cabines/`. `python3 tools/art/cabines_ia.py` recorta o magenta, pinta por cima o que o jogo desenha
(mostradores sem ponteiro, visor do rádio, relógio, equalizador), escreve os adesivos na fonte do jogo, dobra para
768x432 e gera as cores da garagem (`gar_cockpit_*`) recolorindo a lataria/painel. Onde fica cada coisa: `layout`
de cada carro em `scripts/catalog.gd`. Os sprites gerados estão em `tools/art/ia_cabines.txt`.

## Áudio do jogo (ElevenLabs)

    python3 tools/ai/vozes_radio.py [--dry]   # locução do rádio: roteiros, geração do que falta, índice
    python3 tools/ai/sfx_jogo.py              # efeitos sonoros: geração do que falta e tratamento para o Godot

- Vozes: Serra FM = "Locutor Serra FM" (Rômulo Franklin, `HR2TRGmi4QbMsO5omv7l`), Litoral FM = "Locutora Litoral FM"
  (Alice, `xMGbstDe7gGBMg3DqxOc`), Noite AM = "Locutor Noite AM" (Daniel Mercer, `uMk2ijhneJaRm2sKMgdi`).
- 157 falas em `assets/audio/voz/*.ogg` (mono, -16 LUFS); índice em `scripts/radio_vozes.gd` (texto do letreiro
  ligado ao arquivo). O roteiro falado escreve números por extenso e soletra siglas ("á-éme", "bê-érre").
- Efeitos: engine.wav (loop refeito com crossfade), rain.ogg, chuva_teto.ogg, hole/bump/splash/wiper/horn.wav,
  seta.wav (relé da seta), pouso.wav (pouso do pulo), trovao.ogg (trovão longe na chuva forte).
- Os mp3 brutos ficam fora do git (variável BRUTO); os scripts só chamam a API para o que ainda não existe.
