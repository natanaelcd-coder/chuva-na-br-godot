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
