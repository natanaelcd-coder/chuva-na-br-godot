extends Node
# Rádio (ideias 8, 9 e 10 do brainstorm).
# - Programação: cada estação alterna músicas e intervalos com vinheta, fundo musical e falas no letreiro:
#   locutor, recado de ouvinte, previsão do tempo (lê clima, chuva e hora de verdade), propaganda de beira de
#   estrada, boletim da estrada e hora certa (com os bipes). As estações seguem no ar mesmo sem ninguém ouvindo:
#   voltar para uma estação cai no meio da música ou da fala.
# - Recepção: o AM pega melhor à noite e chia com a chuva; a FM falha nos vales e longe da torre e volta no alto
#   do morro. Estática leve variando, letreiro piscando quando o sinal some, aviso discreto quando o sinal volta.
# - Quatro músicas por estação (tools/audio/build_music.js gera as novas) e a fita K7 do Besouro: uma quarta
#   "estação" com lado A e B, rolos girando, chiado de fita e as músicas que você ouviu inteiras no rádio, gravadas.
# - Locução gravada (ElevenLabs, tools/ai/vozes_radio.py): cada estação tem a voz do seu locutor (Seu Arlindo, a DJ
#   Caiçara, o Valdo) e as falas do letreiro que têm gravação vão ao ar faladas, no mesmo bus do rádio (filtro de
#   recepção, chiado, volume do rádio nos ajustes), com o fundo musical abaixando enquanto a voz fala. Recado,
#   previsão, hora certa e chamada de música escolhem entre as falas gravadas; sem o arquivo, volta ao texto de antes.
# game.gd guarda só o que o resto lê: radio_st, static_t, STATIONS (que este arquivo preenche) e a_music.

const TRACKS := [   # file, artist, title, station
	["radio0", "TRIO ASFALTO", "CHUVA NA SERRA", 0],
	["radio_serra_1", "DONA NEBLINA", "CAFÉ DE BEIRA DE ESTRADA", 0],
	["radio_serra_2", "OS PRIMOS DA CURVA", "MODA DO PNEU CARECA", 0],
	["radio_serra_3", "TRIO ASFALTO", "FAROL BAIXO", 0],
	["radio1", "OS VAGALUMES", "JANELA ABERTA", 1],
	["radio_litoral_1", "ZÉ DA BALSA", "SAMBA DO ACOSTAMENTO", 1],
	["radio_litoral_2", "BEL MARESIA", "BOSSA DO PEDÁGIO", 1],
	["radio_litoral_3", "OS VAGALUMES", "MARESIA NO PAINEL", 1],
	["radio2", "BANDA NEON", "KM 43", 2],
	["radio_noite_1", "CONJUNTO MADRUGADA", "BOLERO DO FAROL ALTO", 2],
	["radio_noite_2", "BANDA NEON", "LUZ DE FREIO", 2],
	["radio_noite_3", "SINTONIA FINA", "ÚLTIMO PEDÁGIO", 2],
	["musica/serra_me_leva_pra_casa", "IRMÃOS DO PINHEIRAL", "SERRA ME LEVA PRA CASA", 0],   # ElevenLabs, com vocal
	["musica/vou_de_brisa", "LUA DE MARÉ", "VOU DE BRISA", 1],
	["musica/volta_pra_mim", "ROBSON ESTRELA", "VOLTA PRA MIM", 2],
]
# a música nova de cada estação: toca primeiro na primeira sintonia da viagem (índice em TRACKS)
const NOVAS := [12, 13, 14]
const FITA_LEN := 6   # songs per side
const FITA_START := [0, 4, 8]   # the tape that came in the glovebox

# the three stations. home: signal strength on each road; tower: where on the loop the transmitter is
const RADIOS := [
	{"id": "serra", "name": "SERRA FM 98,7", "short": "SERRA FM", "band": "FM", "label": 0, "jingle": "vinheta_serra", "bed": "fundo_serra",
		"home": {"terra": 1.0, "br": 0.8, "expressa": 0.6}, "tower": 0.15, "dj": "SEU ARLINDO"},
	{"id": "litoral", "name": "LITORAL FM 102,3", "short": "LITORAL FM", "band": "FM", "label": 1, "jingle": "vinheta_litoral", "bed": "fundo_litoral",
		"home": {"terra": 0.55, "br": 0.85, "expressa": 1.0}, "tower": 0.6, "dj": "DJ CAIÇARA"},
	{"id": "noite", "name": "NOITE AM 1040", "short": "NOITE AM", "band": "AM", "label": 2, "jingle": "vinheta_noite", "bed": "fundo_noite",
		"home": {"terra": 0.9, "br": 0.9, "expressa": 0.9}, "tower": 0.0, "dj": "VALDO VOZ DE VELUDO"},
]
const VOZ_DIR := "res://assets/audio/voz/%s.ogg"
const VOZ_GAIN_DB := -7.0     # the voices are mastered hotter than the songs
const VOZ_INDEX := preload("res://scripts/radio_vozes.gd")
const FITA := {"id": "fita", "name": "FITA K7", "short": "FITA", "band": "K7", "label": 5}

const SLOGANS := [
	["SERRA FM 98,7: A RÁDIO QUE SOBE A SERRA COM VOCÊ.", "VOCÊ ESTÁ OUVINDO A SERRA FM, A RÁDIO DO CAFÉ PASSADO NA HORA.",
		"SERRA FM: DE CURVA EM CURVA, DE MODA EM MODA.", "AQUI É O SEU ARLINDO, COM O CAFEZINHO DO LADO E O PÉ NA SERRA. BOM DEMAIS DA CONTA TER VOCÊ AQUI.",
		"SERRA FM 98,7. SE CHIAR NA DESCIDA, ESPERA O MORRO: A GENTE VOLTA LÁ EM CIMA.",
		"DICA DO SEU ARLINDO: NA DESCIDA, MARCHA REDUZIDA E FÉ NO FREIO MOTOR.",
		"CAUSO DO DIA: O COMPADRE TONHO JURA QUE VIU UMA VACA DANDO SETA NA CURVA DO SAPO. A GENTE ACREDITA, TONHO.",
		"CAUSO DO DIA: DIZEM QUE NA SERRA TEM UM ORELHÃO QUE SÓ TOCA EM DIA DE NEBLINA. QUEM ATENDE OUVE A SERRA FM.",
		"O SEU ARLINDO PERGUNTA: QUEM AÍ JÁ PAROU NA BEIRA DA ESTRADA SÓ PRA OLHAR O VALE? PARE MAIS. O VALE AGRADECE.",
		"SERRA FM INFORMA: A QUERMESSE DA CAPELA DE SÃO BENEDITO É SÁBADO. TEM BINGO, QUENTÃO E O LEILÃO DE UM FRANGO ASSADO.",
		"CURIOSIDADE DA SERRA: ARAUCÁRIA LEVA UNS VINTE ANOS PRA DAR PINHÃO. PACIÊNCIA É COM ELA MESMA."],
	["LITORAL FM 102,3: O SOM QUE TEM CHEIRO DE MARESIA!", "LITORAL FM: ABRE A JANELA E AUMENTA O VOLUME!",
		"TÁ NA LITORAL, TÁ DE CHINELO. 102,3!", "ALÔ, GALERA DA ESTRADA! AQUI É A DJ CAIÇARA, DIRETO DO ESTÚDIO PÉ NA AREIA.",
		"BOLETIM DAS ONDAS: MAR DE ALMÔNDEGA NO CANTO ESQUERDO. PERFEITO PRA NINGUÉM.",
		"PROMOÇÃO LITORAL FM: O DÉCIMO OUVINTE QUE BUZINAR AGORA... NÃO GANHA NADA, MAS FICA FELIZ. BIBI!",
		"A DJ CAIÇARA AVISA: PROTETOR SOLAR NO NARIZ E COTOVELO PRA DENTRO, QUE O VIZINHO DE FAIXA AGRADECE.",
		"LITORAL FM 102,3: A ÚNICA RÁDIO COM AREIA DENTRO DO MICROFONE.",
		"CURIOSIDADE DA LITORAL: O CARANGUEJO ANDA DE LADO E NUNCA LEVOU MULTA. FICA A REFLEXÃO.",
		"PERGUNTA DO DIA DA DJ CAIÇARA: BISCOITO OU BOLACHA? MANDE SUA RESPOSTA POR POMBO-CORREIO. A GENTE NÃO VAI LER."],
	["NOITE AM 1040: A COMPANHIA DE QUEM NÃO DORME.", "NOITE AM, DE CORAÇÃO PARA CORAÇÃO, DE FAROL PARA FAROL.",
		"AM 1040: O CHIADO É CHARME.", "BOA NOITE, MOTORISTA. AQUI É O VALDO, VOZ DE VELUDO, SEGURANDO A MADRUGADA COM VOCÊ.",
		"PRA QUEM TÁ NA BOLEIA: MANTÉM O CAFÉ QUENTE E O CORAÇÃO MAIS AINDA.",
		"CORREIO SENTIMENTAL: ELA DISSE QUE VOLTA. ELE DISSE QUE ESPERA. O RÁDIO DIZ: TOCA MAIS UMA.",
		"LIGAÇÃO NO AR: ALÔ, VALDO? É O BIGODE, DA CARRETA AZUL. SÓ QUERIA DIZER QUE A LUA TÁ BONITA AQUI NO KM 200. VALEU, BIGODE.",
		"O VALDO EXPLICA: O AM VIAJA MAIS LONGE DE NOITE, QUICANDO NO CÉU. É POR ISSO QUE A GENTE PEGA MELHOR NO ESCURO.",
		"PENSAMENTO DA MADRUGADA: A ESTRADA É COMPRIDA, MAS A MÚSICA É BOA. E O CAFÉ DO POSTO É FORTE.",
		"NOITE AM 1040. SE O SOL NASCER E A GENTE SUMIR NO CHIADO, NÃO É ABANDONO: É FÍSICA."],
]
const DJ_INTRO := [
	["E AGORA, PRA ACOMPANHAR A SUBIDA: %s, COM \"%s\".", "PEDIDO DO PESSOAL DA VENDA: %s, \"%s\".", "UMA MODA BOA PRA ESTRADA: %s E \"%s\"."],
	["SEGURA ESSA, GALERA: %s, \"%s\"!", "SOBE O SOM: %s COM \"%s\"!", "DIRETO DA AREIA PRO SEU PAINEL: %s, \"%s\"."],
	["PRA QUEM TÁ ACORDADO: %s, \"%s\". DEDICADA A VOCÊ, MOTORISTA.", "APAGA A LUZ DO PAINEL E OUVE: %s, \"%s\".",
		"DO FUNDO DO BAÚ DA MADRUGADA: %s, \"%s\"."],
]
const ADS := [
	"BORRACHARIA DO TIÃO, 24 HORAS: FUROU O PNEU? O TIÃO ACORDA. FUROU DE MADRUGADA? O TIÃO ACORDA RECLAMANDO.",
	"PAMONHA DA DONA ZICA, NO TREVO: DOCE, SALGADA E A DE QUEIJO QUE FAZ CHORAR. TEM CURAU TAMBÉM!",
	"CHURRASCARIA GAÚCHO SOLITÁRIO, KM 88: RODÍZIO ATÉ O CINTO PEDIR ARREGO. ESTACIONAMENTO PARA CARRETA.",
	"AUTOESCOLA DEVAGAR SE VAI AO LONGE: APROVAÇÃO GARANTIDA OU A GENTE TENTA DE NOVO, SEM PRESSA.",
	"COLCHÕES SONO DE PEDRA: VOCÊ DEITA, VOCÊ DORME, VOCÊ PERDE A NOVELA. NA SAÍDA DA CIDADE.",
	"QUEIJARIA SERRA AZUL: QUEIJO FRESCO, MEIA-CURA E O CURADO QUE O VÔ ESCONDE. PROVE SEM COMPROMISSO.",
	"POSTO TRÊS IRMÃOS: CALIBRAGEM GRÁTIS, CAFÉ COADO NA HORA E O BANHEIRO MAIS LIMPO DA REGIÃO. PALAVRA DO IRMÃO DO MEIO.",
	"PASTELARIA KM 12: PASTEL DE CARNE, DE QUEIJO E DE VENTO. O DE VENTO É GRÁTIS.",
	"FUNILARIA MARTELINHO DO NECO: AMASSOU? O NECO DESAMASSA. NÃO AMASSOU? PASSA PRA TOMAR UM CAFÉ.",
	"MERCEARIA DO TREVO: TEM DE TUDO. O QUE NÃO TEM, O SEU LAÉRCIO ARRUMA ATÉ QUINTA.",
	"RESTAURANTE COMIDA DE MÃE, KM 140: PRATO FEITO COM OVO FRITO EM CIMA. REPETECO LIBERADO.",
	"LAVA-RÁPIDO BRILHO DA SERRA: LAVA, ENCERA E AINDA DÁ CONSELHO AMOROSO. CHOVEU DEPOIS? LAVA DE NOVO PELA METADE.",
	"LOJA TERÇO E DADO: TERÇO, DADO DE PELÚCIA E CACHORRINHO QUE BALANÇA A CABEÇA. ENFEITE SEU RETROVISOR!",
	"CALDO DE CANA DO ZÉ GARAPA: COM LIMÃO, COM ABACAXI OU PURO. A GARAPA MAIS GELADA DESDE 1971.",
	"OFICINA DO SEU DITO: CONSERTA CARRO ANTIGO, CARRO NOVO E CORAÇÃO PARTIDO. ESTE ÚLTIMO SÓ NA CONVERSA.",
	"FEIRA DO ROLO, DOMINGO NO PÁTIO DA ESTAÇÃO: TROQUE SEU RÁDIO VELHO POR UMA BICICLETA. OU O CONTRÁRIO.",
	"BARRACA DA TIA NICE: BOLO DE ROLO, DOCE DE LEITE E GOIABADA CASCÃO. ACEITA CARTÃO, FIADO NÃO.",
	"HOTEL FAZENDA RECANTO DAS MARITACAS: PISCINA, TIROLESA E CAFÉ DA MANHÃ COM QUARENTA TIPOS DE BOLO.",
	"PEIXARIA MAR À VISTA, A 300 KM DO MAR: PEIXE FRESCO, PALAVRA DE PESCADOR.",
	"MATERIAL DE CONSTRUÇÃO TIJOLINHO: CIMENTO, AREIA E UM BALCONISTA QUE SABE O NOME DE TODO MUNDO.",
	"SALÃO DA LENI: CORTE, ESCOVA E AS NOTÍCIAS DA CIDADE INTEIRA, TUDO NUM PREÇO SÓ.",
]
const ADS_ST := [
	["LEILÃO DE GADO NO PARQUE DE EXPOSIÇÕES, SÁBADO: VENHA PELA VACA, FIQUE PELA PAMONHA.",
		"CASA DA LÃ: BLUSA DE TRICÔ PRA SUBIR A SERRA SEM BATER QUEIXO.", "MEL DO SEU BENÊ: DIRETO DA ABELHA PRO SEU PÃO. A ABELHA NÃO COBRA, O BENÊ COBRA POUCO."],
	["ALUGA-SE GUARDA-SOL E CADEIRA NA PRAIA DO MEIO. O ISOPOR É POR SUA CONTA.",
		"SORVETERIA PICOLÉ DE COCO: DERRETEU ANTES DE CHEGAR NO CARRO? A GENTE DÁ OUTRO.", "ESCOLA DE SURFE ONDA MANSA: EM TRÊS AULAS VOCÊ FICA DE PÉ. NA AREIA, MAS FICA."],
	["DISQUE-CAFÉ DO POSTO 24 HORAS: CAFÉ PRETO, PÃO NA CHAPA E UMA CONVERSA PRA ESPANTAR O SONO.",
		"PADARIA MADRUGADA: O PÃO SAI ÀS QUATRO, O PADEIRO ACORDA ÀS TRÊS, O GALO SÓ DEPOIS.",
		"CURSO DE CONSERTO DE RÁDIO POR CORRESPONDÊNCIA: DOZE LIÇÕES E VOCÊ NUNCA MAIS FICA SEM A NOITE AM."],
]
const ROAD_NEWS := {
	"terra": ["BOLETIM DA ESTRADA DO SÍTIO: TERRA BATIDA, ALGUNS BURACOS DE RESPEITO E A VACA MIMOSA NO ACOSTAMENTO. VÁ DEVAGAR.",
		"AVISO DA ESTRADA DO SÍTIO: MÃO DUPLA. OLHE BEM ANTES DE PASSAR O TRATOR. ELE NÃO TEM PRESSA, E VOCÊ TAMBÉM NÃO.",
		"QUEM VAI PELA ESTRADA DO SÍTIO: A VENDA TEM CAFÉ FRESQUINHO E QUEIJO DO DIA.",
		"ESTRADA DO SÍTIO: A PORTEIRA DO SEU ZICO TÁ ABERTA DE NOVO. SE VIR UM BEZERRO PASSEANDO, É ELE."],
	"br": ["TRÂNSITO NA BR-116: MOVIMENTO BOM, CAMINHÃO NA FAIXA DA DIREITA, APRESSADO NA ESQUERDA. E VOCÊ NO MEIO, CURTINDO.",
		"AVISO PRA BR-116: TEM TRECHO DE PISTA IRREGULAR. OLHO NA PLACA E MÃO FIRME NO VOLANTE.",
		"O POSTO DA BR-116 AVISA: TANQUE NA RESERVA? PASSA NA FAIXA DA DIREITA QUE O FRENTISTA JÁ SABE.",
		"BR-116: OS CAMINHONEIROS MANDAM AVISAR QUE A FILA DO PASTEL NO POSTO TÁ ANDANDO RÁPIDO."],
	"expressa": ["RODOVIA EXPRESSA: CONCRETO LISO, QUATRO FAIXAS E UM PAINEL DE LED DIZENDO O ÓBVIO. BOA VIAGEM.",
		"NA EXPRESSA O PEDÁGIO TÁ FLUINDO, E O TELEFONE SOS TÁ LÁ PRA QUEM PRECISAR. TOMARA QUE NINGUÉM PRECISE.",
		"PARADA DA EXPRESSA: CAFÉ E PÃO DE QUEIJO. PARE, ESTIQUE AS PERNAS E VOLTE PRO EMBALO.",
		"RODOVIA EXPRESSA INFORMA: O RADAR TÁ LIGADO, MAS O RÁDIO TAMBÉM. FIQUE COM O RÁDIO."],
}
const WHO := ["DONA CIDA", "SEU JOÃO DA PORTEIRA AZUL", "DONA LURDINHA", "SEU TONHO DO CAMINHÃO BAÚ", "A TURMA DA VAN DA EXCURSÃO",
	"DONA FIA", "SEU BENÊ", "O PESSOAL DO POSTO DO TREVO", "DONA NENA DA PAMONHA", "SEU QUINZINHO", "A PROFESSORA ROSÂNGELA",
	"O CAMINHONEIRO BIGODE", "TIA DIRCE", "VÔ ARLINDINHO", "O MOTORISTA DO ÔNIBUS DAS SEIS", "DONA ZEFA", "SEU DITO DO SÍTIO"]
const WHERE := ["DO KM 43", "DE SANTA RITA DO MORRO", "DA VILA DOS IPÊS", "LÁ DO BAIRRO DA PONTE", "DO TREVO DE BAIXO",
	"DE SÃO BENEDITO DAS ÁGUAS", "DO SÍTIO TRÊS PORTEIRAS", "DA CURVA DO SAPO", "DE PEDRA BRANCA DO SUL", "DO POSTO DO KM 112"]
const MSG := ["SEU FILHO CHEGOU BEM E MANDOU UM BEIJO", "A GALINHA PINTADINHA VOLTOU SOZINHA PRO GALINHEIRO",
	"O BOLO DE FUBÁ TÁ NO FORNO, NÃO DEMORA", "A CHAVE TÁ DEBAIXO DO VASO DE SAMAMBAIA", "TRAZ PÃO NA VOLTA, E QUE SEJA DO QUENTINHO",
	"O CACHORRO COMEU O CHINELO DE NOVO", "A REUNIÃO DA CAPELA FICOU PRA QUINTA", "PARABÉNS PELOS 80 ANOS, E QUE VENHAM MAIS 80",
	"O CARBURADOR FICOU PRONTO, PODE BUSCAR", "A NETINHA NASCEU! TRÊS QUILOS E UM CHORO DE RESPEITO", "A VACA MIMOSA DEU CRIA, É MACHO",
	"TIRA A ROUPA DO VARAL QUE VEM CHUVA", "O TIME DA VILA GANHOU DE 3 A 2, COM GOL DO GOLEIRO", "O BOLÃO DA FIRMA DEU ZEBRA DE NOVO",
	"A JABUTICABEIRA CARREGOU, VEM BUSCAR UM BALDE", "O GATO SUBIU NO TELHADO E NÃO QUER DESCER, MAS TÁ TUDO BEM"]
const FROM := ["SUA COMADRE", "O GENRO", "A VIZINHA DA FRENTE", "O COMPADRE ZÉ", "A FILHA MAIS VELHA", "O PESSOAL DA OFICINA", "A TURMA DO TRUCO"]

var g
var rng := RandomNumberGenerator.new()
var streams: Array = []        # per track
var sounds := {}               # jingles, beds, pips, click
var prog: Array = []           # per radio station: what is on the air right now
var novas_ouvidas := {}        # estações já sintonizadas nesta viagem (a música nova tem prioridade na 1ª vez)
var heard: Array = []          # tracks heard to the end
var fita_a: Array = []
var fita_b: Array = []
var tape := {"side": 0, "i": 0, "t": 0.0, "kind": "song", "dur": 1.0, "flipped": true}
var bags := {}                 # shuffled pools so nothing repeats too soon
var cur_id := "serra"          # station id behind radio_st, so a car change keeps the station
var q := 1.0                   # reception of the tuned station, 0..1
var q_raw := 1.0
var weak_t := 0.0
var was_weak := false
var notice_cd := 0.0
var crackle := 0.0
var tuned_from_start := false
var shown_text := ""
var bus_lp: AudioEffectLowPassFilter
var a_bed: AudioStreamPlayer
var a_jingle: AudioStreamPlayer
var a_static: AudioStreamPlayer
var a_hiss: AudioStreamPlayer
var a_click: AudioStreamPlayer
var bed_on := false
var audio_ready := false
var a_voice: AudioStreamPlayer
var voz_text := {}             # "station|text on the strip" -> recorded line (slogans, ads, road news)
var voz_kind := {}             # "station|kind" -> recorded lines to pick from (recado, tempo, hora, intro)
var voz_streams := {}          # file -> AudioStream, loaded the first time it airs
var voice_file := ""           # what a_voice is playing
var duck := 0.0                # 0..1: the bed and jingle dip under the voice
var _picked: Dictionary = {}   # the recorded line _line() chose, if any


func _ready() -> void:
	g = get_parent()
	if Engine.has_meta("test_seed"):
		rng.seed = int(Engine.get_meta("test_seed")) * 7919 + 13
	else:
		rng.randomize()
	for tr in TRACKS:
		var s: AudioStreamOggVorbis = load("res://assets/audio/%s.ogg" % tr[0])
		s.loop = false
		streams.append(s)
	for n in ["vinheta_serra", "vinheta_litoral", "vinheta_noite", "fundo_serra", "fundo_litoral", "fundo_noite", "hora_certa", "k7_clique"]:
		var s: AudioStreamOggVorbis = load("res://assets/audio/%s.ogg" % n)
		s.loop = n.begins_with("fundo")
		sounds[n] = s
	_index_voices()
	for i in [5, 6]:
		g.tex["label%d" % i] = load("res://assets/sprites/label%d.png" % i)
	heard = Array(g.store_get("radio", "ouvidas", []))
	fita_a = Array(g.store_get("radio", "fita_a", FITA_START.duplicate()))
	fita_b = Array(g.store_get("radio", "fita_b", []))
	for i in RADIOS.size():
		var p := {"kind": "song", "song": -1, "t": 0.0, "dur": 1.0, "items": [], "ti": 0, "tt": 0.0, "tdur": 0.0, "text": "", "next": -1, "breaks": 0, "voice": {}, "vdelay": 0.0}
		_start_song(p, i, _pick_song(p, i))
		p.t = rng.randf_range(0.0, p.dur * 0.6)   # the stations were on the air before we got here
		prog.append(p)
	_stations()
	g.setup_done.connect(_on_setup)
	g.trip_started.connect(_on_trip)
	g.menu.add_main_item("RÁDIO", _open_screen)
	g.menu.add_pause_item("RÁDIO E FITA", _open_screen)

func _ensure_audio() -> bool:
	if audio_ready:
		return true
	if g.a_music == null:
		return false
	audio_ready = true
	var bi := AudioServer.get_bus_index("Radio")
	if bi < 0:
		AudioServer.add_bus()
		bi = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bi, "Radio")
		AudioServer.set_bus_send(bi, "Master")
	bus_lp = AudioEffectLowPassFilter.new()
	bus_lp.cutoff_hz = 12000.0
	AudioServer.add_bus_effect(bi, bus_lp)
	g.a_music.bus = "Radio"
	a_bed = _player("Radio")
	a_jingle = _player("Radio")
	a_voice = _player("Radio")
	a_click = _player("Master")
	a_click.stream = sounds["k7_clique"]
	a_static = _player("Master")
	a_static.stream = _noise(true)
	a_static.volume_db = -80.0
	a_static.play()
	a_hiss = _player("Master")
	a_hiss.stream = _noise(false)
	a_hiss.volume_db = -80.0
	a_hiss.play()
	return true

func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p

# 2 s loops made at start-up: radio static (crackly, band-limited) or tape hiss (soft, high)
func _noise(crackly: bool) -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 2
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var hp := 0.0
	for i in n:
		var w := rng.randf() * 2.0 - 1.0
		var x: float
		if crackly:
			lp += (w - lp) * 0.35
			x = lp * 1.4
			if rng.randf() < 0.0015:
				x += rng.randf_range(-1.0, 1.0) * 2.5   # pops
		else:
			x = (w - hp) * 0.25
			hp = w
		var fade := minf(1.0, minf(i, n - i) / 300.0)
		data.encode_s16(i * 2, int(clampf(x * fade, -1.0, 1.0) * 26000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.data = data
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_end = n
	return st


# ---------------------------------------------------------------- the announcers' voices

# only lines whose file is really there count: without them the station is text on the strip, as before
func _index_voices() -> void:
	for e in VOZ_INDEX.VOZES:
		if not ResourceLoader.exists(VOZ_DIR % e.file):
			continue
		if e.kind in ["slogan", "ad", "estrada"]:
			voz_text["%d|%s" % [e.st, e.tela]] = e
		else:
			var k := "%d|%s" % [e.st, e.kind]
			if not voz_kind.has(k):
				voz_kind[k] = []
			voz_kind[k].append(e)

func has_voice(si: int, kind: String) -> bool:
	return voz_kind.has("%d|%s" % [si, kind])

func _voices(si: int, kind: String, key: String, value) -> Array:   # recorded lines of a kind, filtered by one field
	var out: Array = []
	for e in voz_kind.get("%d|%s" % [si, kind], []):
		if key == "" or e.get(key) == value:
			out.append(e)
	return out

func voice_stream(file: String) -> AudioStream:
	if not voz_streams.has(file):
		var st: AudioStream = load(VOZ_DIR % file)
		if st is AudioStreamOggVorbis:
			st.loop = false
		voz_streams[file] = st
	return voz_streams[file]

# keep a_voice on what the tuned station is saying right now (joining mid-line starts mid-line, like the songs)
func _voice_step(si: int) -> void:
	var want := ""
	var at := 0.0
	if si >= 0:
		var p: Dictionary = prog[si]
		var e: Dictionary = p.get("voice", {})
		if p.kind == "talk" and not e.is_empty():
			at = p.tt - float(p.vdelay)
			if at >= 0.0 and at < float(e.dur) - 0.25:
				want = e.file
	if want == "":
		if voice_file != "" and not a_voice.playing:
			voice_file = ""
		elif voice_file != "" and (si < 0 or prog[si].kind != "talk" or prog[si].get("voice", {}).get("file", "") != voice_file):
			a_voice.stop()
			voice_file = ""
		return
	if want != voice_file or not a_voice.playing:
		if want == voice_file and at > 0.3:   # it just finished on its own: don't start it again
			return
		a_voice.stream = voice_stream(want)
		a_voice.play(at)
		voice_file = want


# ---------------------------------------------------------------- stations

func has_tape() -> bool:
	return g.cfg.car == "besouro"

# what the R key cycles through: the three radios, the tape (Besouro), then off
func _stations() -> void:
	var l: Array = RADIOS.duplicate()
	if has_tape():
		var f: Dictionary = FITA.duplicate()
		f.label = 5 + tape.side
		l.append(f)
	g.STATIONS = l
	var idx := -1
	for i in l.size():
		if l[i].id == cur_id:
			idx = i
	if idx < 0:   # off stays off; the tape in a car without a deck falls back to the first radio
		idx = l.size() if cur_id == "off" else 0
		if cur_id != "off":
			cur_id = l[0].id
	g.radio_st = idx

func cur() -> Dictionary:
	return g.STATIONS[g.radio_st] if g.radio_st < g.STATIONS.size() else {}

func _on_setup() -> void:
	var before: int = g.radio_st
	_stations()
	if g.radio_st != before or (cur_id == "fita" and not has_tape()):
		radio_tune()

func _on_trip() -> void:   # cada viagem recomeça a regra: a música nova de cada estação toca na primeira sintonia
	novas_ouvidas = {}
	var c := cur()
	if not c.is_empty() and c.id != "fita":
		radio_tune()

func radio_next() -> void:
	g.radio_st = (g.radio_st + 1) % (g.STATIONS.size() + 1)
	cur_id = cur().get("id", "off")
	g.static_t = 0.45
	g._sfx("static")
	radio_tune()

func flip_tape() -> void:
	tape.side = 1 - tape.side
	tape.i = 0
	tape.t = 0.0
	tape.kind = "flip"
	tape.dur = 2.2
	tape.flipped = true
	_stations()
	a_click.play()
	_tape_play()

# start whatever the tuned station is playing, from where it is
func radio_tune() -> void:
	if not _ensure_audio():
		radio_now_playing()
		return
	g.a_music.stop()
	g.a_music.pitch_scale = 1.0
	a_bed.stop()
	a_voice.stop()
	voice_file = ""
	bed_on = false
	tuned_from_start = false
	var c := cur()
	if c.is_empty():
		pass
	elif c.id == "fita":
		a_click.play()
		_tape_play()
	else:
		_priorizar_nova(g.radio_st)
		_apply_item(g.radio_st, true)
	radio_now_playing()

# primeira vez que a estação é sintonizada na viagem: a música nova entra já (agora ou logo depois da locução),
# e a rotação segue normal depois dela
func _priorizar_nova(si: int) -> void:
	if novas_ouvidas.has(si) or not g.started:
		return
	novas_ouvidas[si] = true
	var nova: int = NOVAS[si]
	var p: Dictionary = prog[si]
	if p.kind == "talk":
		if not p.items.slice(0, p.ti + 1).has("intro"):   # a chamada já no ar anunciou a outra música
			p.next = nova
	elif p.song != nova:
		_start_song(p, si, nova)

func _apply_item(si: int, joined: bool) -> void:
	var p: Dictionary = prog[si]
	var st: Dictionary = RADIOS[si]
	if p.kind == "song":
		a_bed.stop()
		bed_on = false
		g.a_music.stream = streams[p.song]
		g.a_music.play(clampf(p.t, 0.0, p.dur - 0.1))
		tuned_from_start = p.t < 3.0
		g.radio_song = p.song
	else:
		g.a_music.stop()
		a_bed.stream = sounds[st.bed]
		a_bed.play(fmod(p.t, sounds[st.bed].get_length()))
		bed_on = true
		if not joined:
			a_jingle.stream = sounds[st.jingle]
			a_jingle.play()

func radio_now_playing() -> void:
	var c := cur()
	var txt := ""
	if c.is_empty():
		txt = "TOCANDO: SÓ A CHUVA" if g.cfg.weather == "chuva" else "TOCANDO: SÓ O VENTO NA JANELA"
	elif c.id == "fita":
		txt = _tape_text()
	else:
		var p: Dictionary = prog[g.radio_st]
		if p.kind == "song":
			var tr: Array = TRACKS[p.song]
			txt = "TOCANDO: %s - %s - %s" % [tr[1], tr[2], c.name]
		else:
			txt = "%s  ·  %s" % [c.short, p.text]
	if txt != shown_text:
		shown_text = txt
		g.hud.set_now(txt)


# ---------------------------------------------------------------- the program (idea 8)

func _bag(key: String, n: int) -> int:   # shuffled index into a pool of n, no repeats until it runs out
	var b: Array = bags.get(key, [])
	if b.is_empty():
		for i in n:
			b.append(i)
		for i in range(n - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = b[i]
			b[i] = b[j]
			b[j] = tmp
		bags[key] = b
	return b.pop_back()

func _pick_song(p: Dictionary, si: int) -> int:
	var mine: Array = []
	for i in TRACKS.size():
		if TRACKS[i][3] == si:
			mine.append(i)
	var k: int = mine[_bag("song%d" % si, mine.size())]
	if k == p.song:
		k = mine[_bag("song%d" % si, mine.size())]
	return k

func _start_song(p: Dictionary, si: int, song: int) -> void:
	p.kind = "song"
	p.song = song
	p.t = 0.0
	p.dur = streams[song].get_length()

func _start_break(p: Dictionary, si: int) -> void:
	p.kind = "talk"
	p.t = 0.0
	p.breaks += 1
	p.next = _pick_song(p, si)
	var items: Array = []
	var r := rng.randf()
	var main := "ad"
	if p.breaks % 3 == 1:
		main = "tempo"
	elif r < 0.22:
		main = "recado"
	elif r < 0.38:
		main = "hora"
	elif r < 0.54:
		main = "estrada"
	elif r < 0.66:
		main = "slogan"
	items.append(main)
	# keep the break short: an id before a short line, sometimes a second short one, and the next song
	if main in ["hora", "estrada", "ad"] and rng.randf() < 0.35:
		items.push_front("slogan")
	elif main in ["slogan", "hora"] and rng.randf() < 0.4:
		items.append("ad")
	if rng.randf() < 0.6:
		items.append("intro")
	p.items = items
	p.ti = 0
	_set_text(p, si)

func _set_text(p: Dictionary, si: int) -> void:
	_picked = {}
	var kind: String = p.items[p.ti]
	p.text = _line(kind, si, p)
	p.tt = 0.0
	# long lines scroll through the 428 px strip at 30 px/s after a 2 s pause: give each one pass plus a beat
	var w: float = (RADIOS[si].short.length() + 4 + p.text.length()) * 8.0
	p.tdur = maxf(6.0, 2.0 + maxf(0.0, w - 420.0) / 30.0 + 2.5)
	# a recorded line: it starts after the jingle (first of the break) or a bit into the pips, and the strip waits for it
	p.voice = _picked
	p.vdelay = 0.4
	if p.ti == 0:
		p.vdelay = sounds[RADIOS[si].jingle].get_length() - 1.0   # over the tail of the jingle, which ducks
	elif kind == "hora":
		p.vdelay = 1.6
	if not _picked.is_empty():
		p.tdur = maxf(p.tdur, p.vdelay + float(_picked.dur) + 0.7)

func _line(kind: String, si: int, p: Dictionary) -> String:
	match kind:
		"slogan":
			return _said(si, SLOGANS[si][_bag("slogan%d" % si, SLOGANS[si].size())])
		"ad":
			if rng.randf() < 0.3:
				return "PROPAGANDA: " + _said(si, ADS_ST[si][_bag("adst%d" % si, ADS_ST[si].size())])
			if not voz_text.is_empty():   # with the voices, each station has its own sponsors, read by its announcer
				var mine := range(si, ADS.size(), 3)
				return "PROPAGANDA: " + _said(si, ADS[mine[_bag("ad%d" % si, mine.size())]])
			return "PROPAGANDA: " + ADS[_bag("ad", ADS.size())]
		"recado":
			if has_voice(si, "recado"):   # one of the messages the announcer recorded
				var rl := _voices(si, "recado", "", null)
				_picked = rl[_bag("recado%d" % si, rl.size())]
				return _picked.tela
			return "RECADO DE OUVINTE: ALÔ, %s %s! %s. QUEM MANDA É %s." % [WHO[_bag("who", WHO.size())], WHERE[_bag("where", WHERE.size())],
				MSG[_bag("msg", MSG.size())], FROM[_bag("from", FROM.size())]]
		"hora":
			return hora_certa(si)
		"tempo":
			return previsao(si)
		"estrada":
			var l: Array = ROAD_NEWS[g.cfg.road]
			return _said(si, l[_bag("road_" + g.cfg.road, l.size())])
		"intro":
			var il := _voices(si, "intro", "song", p.next)
			if not il.is_empty():
				_picked = il[rng.randi_range(0, il.size() - 1)]
				return _picked.tela
			var tr: Array = TRACKS[p.next]
			var l2: Array = DJ_INTRO[si]
			return l2[rng.randi_range(0, l2.size() - 1)] % [tr[1], tr[2]]
	return ""

func _said(si: int, text: String) -> String:   # a fixed line: note its recording, if there is one
	_picked = voz_text.get("%d|%s" % [si, text], {})
	return text

func clock() -> Vector2i:   # the in-game hour, the same the GT's dash clock shows
	var hours := fposmod(14.0 + g.tday * 6.0, 24.0)
	return Vector2i(int(hours), int((hours - int(hours)) * 60.0))

func hora_certa(si: int) -> String:
	var c := clock()
	var per := "madrugada" if c.x < 5 else ("manha" if c.x < 12 else ("tarde" if c.x < 18 else "noite"))
	var hl := _voices(si, "hora", "period", per)
	if not hl.is_empty():   # the recorded time signal says the station and a greeting; the strip shows the clock
		_picked = hl[0]
		return _picked.tela % ("%02dH%02d" % [c.x, c.y])
	var hh := "%d HORAS" % c.x if c.x != 1 else "1 HORA"
	if c.x == 0:
		hh = "MEIA-NOITE"
	elif c.x == 12:
		hh = "MEIO-DIA"
	var mm := (" E %d MINUTOS" % c.y) if c.y > 1 else (" E 1 MINUTO" if c.y == 1 else " EM PONTO")
	var tail := ""
	if c.x < 5:
		tail = ["QUEM TÁ ACORDADO A ESSA HORA, UM ABRAÇO.", "A CIDADE DORME, A ESTRADA NÃO.", "SÓ NÓS, OS CAMINHÕES E A LUA."][si]
	elif c.x < 12:
		tail = ["BOM DIA, QUE O CAFÉ JÁ PASSOU.", "BOM DIA, GALERA! O MAR JÁ ACORDOU.", "O SOL TÁ CHEGANDO E O AM TÁ INDO DORMIR."][si]
	elif c.x < 18:
		tail = ["BOA TARDE, QUE O PÃO DE QUEIJO TÁ SAINDO.", "BOA TARDE! HORA DO PICOLÉ.", "A NOITE AM TÁ AQUI, MESMO DE DIA, CHIANDO COM CARINHO."][si]
	else:
		tail = ["BOA NOITE, FAROL BAIXO E CORAÇÃO TRANQUILO.", "BOA NOITE! O LUAU TÁ COMEÇANDO.", "BOA NOITE, MOTORISTA. AGORA O AM PEGA BONITO."][si]
	return "HORA CERTA %s: %s%s. %s" % [RADIOS[si].short, hh, mm, tail]

func previsao(si: int) -> String:
	var rain: float = g.rain
	var goal: float = g.rain_goal if g.rain_goal >= 0.0 else rain
	var period := int(fposmod(g.tday, 4.0) + 0.5) % 4   # 0 day, 1 dusk, 2 night, 3 dawn
	var where: String = {"terra": "NOS SÍTIOS E NA SERRA", "br": "AO LONGO DA BR-116", "expressa": "NA RODOVIA EXPRESSA"}[g.cfg.road]
	var cond := ""
	var tip := ""
	if g.cfg.weather == "chuva" or rain > 0.2:
		cond = "CHUVA FORTE" if rain > 0.85 else ("CHUVA MODERADA" if rain > 0.6 else ("CHUVA FRACA" if rain > 0.3 else "GAROA"))
		if goal > rain + 0.08:
			cond += ", APERTANDO NAS PRÓXIMAS HORAS"
		elif goal < rain - 0.08:
			cond += ", DANDO UMA TRÉGUA DAQUI A POUCO"
		tip = ["CAPRICHE NO LIMPADOR", "FAROL BAIXO E DISTÂNCIA DO CARRO DA FRENTE", "CUIDADO COM AS POÇAS, QUE O CARRO BOIA"][rng.randi_range(0, 2)]
	else:
		cond = ["SOL ABERTO, CÉU AZUL DE BRIGADEIRO", "SOL SE PONDO, CÉU ALARANJADO", "CÉU LIMPO E ESTRELADO", "MANHÃ FRESCA, COM NEBLINA NOS VALES"][period]
		tip = ["ÓCULOS ESCUROS E COTOVELO PRA DENTRO", "SOL BAIXO NO OLHO: QUEBRA-SOL ABAIXADO", "FAROL LIGADO E OLHO NO ACOSTAMENTO", "DEVAGAR NA NEBLINA, QUE ELA PASSA"][period]
		if g.cfg.road == "terra":
			tip += ". E A POEIRA VERMELHA? FAZ PARTE"
	var vc := ""   # the recorded forecasts: sunny day, clear night, rain, changeable
	var clima = g.get_node_or_null("mundo_clima")
	var turning: bool = clima != null and clima.get("phase") in ["nublando", "abrindo"]
	if g.cfg.weather == "chuva" or rain > 0.2:
		vc = "variavel" if goal < rain - 0.08 else "chuva"
	elif turning or goal > rain + 0.08 or (g.cfg.weather == "variavel" and rng.randf() < 0.5):
		vc = "variavel"
	else:
		vc = "sol" if period == 0 else "noite"
	var tl := _voices(si, "tempo", "cond", vc)
	if not tl.is_empty():
		_picked = tl[0]
		return _picked.tela
	var temp: int = [27, 22, 16, 14][period] - (5 if rain > 0.3 else 0) - (3 if g.cfg.road == "terra" else 0) + rng.randi_range(-1, 2)
	match si:
		0:
			return "PREVISÃO DO TEMPO COM O SEU ARLINDO: %s %s. %s. TERMÔMETRO MARCANDO %d GRAUS, %s." % [cond, where, tip, temp,
				"TEMPO DE CAFÉ COM BOLO" if temp < 20 else "TEMPO DE CALDO DE CANA"]
		1:
			return "PREVISÃO LITORAL FM: %s %s, %d GRAUS. %s. %s" % [cond, where, temp, tip,
				"NA PRAIA? GUARDA-CHUVA VIRA GUARDA-SOL." if rain > 0.3 else "DIA DE PRAIA ATÉ PRA QUEM TÁ NA ESTRADA!"]
	return "PREVISÃO PRA QUEM VIAJA NA NOITE AM: %s %s, %d GRAUS. %s. %s" % [cond, where, temp, tip,
		"E COM CHUVA O AM CHIA MAIS, MAS NÃO DESISTE." if rain > 0.3 else "CÉU ASSIM O AM VAI LONGE."]

# one station moves on in time; returns true when a new song or a new break starts
func _advance(si: int, dt: float, tuned: bool) -> bool:
	var p: Dictionary = prog[si]
	p.t += dt
	if p.kind == "song":
		if p.t >= p.dur:
			if tuned:
				_song_done(p.song)
			_start_break(p, si)
			return true
		return false
	p.tt += dt
	if p.tt >= p.tdur:
		p.ti += 1
		if p.ti >= p.items.size():
			_start_song(p, si, p.next)
			return true
		_set_text(p, si)
		if tuned and p.items[p.ti] == "hora":   # the time signal: pips over the bed
			a_jingle.stream = sounds["hora_certa"]
			a_jingle.play()
	return false

# a song heard to the end: count it, and record it on the Besouro's tape if there is room
func _song_done(song: int) -> void:
	if not (tuned_from_start and g.started):
		return
	if not heard.has(song):
		heard.append(song)
		g.store_set("radio", "ouvidas", heard)
	if has_tape() and not fita_a.has(song) and not fita_b.has(song):
		var side := ""
		if fita_a.size() < FITA_LEN:
			fita_a.append(song)
			side = "A"
		elif fita_b.size() < FITA_LEN:
			fita_b.append(song)
			side = "B"
		if side != "":
			g.store_set("radio", "fita_a", fita_a)
			g.store_set("radio", "fita_b", fita_b)
			g.hud.notice("GRAVADO NA FITA, LADO %s: %s" % [side, TRACKS[song][2]], 4.0)
	g.store_save()


# ---------------------------------------------------------------- the tape (idea 10)

func _side() -> Array:
	return fita_a if tape.side == 0 else fita_b

# play what the tape is on: a song from where it stopped, or the deck turning the tape over
func _tape_play() -> void:
	var side := _side()
	if tape.kind == "song" and tape.i >= side.size():
		_tape_next()
		return
	if tape.kind == "flip":
		g.a_music.stop()
		return
	var song: int = side[tape.i]
	tape.dur = streams[song].get_length()
	g.a_music.stream = streams[song]
	g.a_music.play(clampf(tape.t, 0.0, tape.dur - 0.1))
	g.radio_song = song

func _tape_next() -> void:
	tape.t = 0.0
	if tape.kind == "flip":
		tape.kind = "song"
		tape.i = 0
		if _side().is_empty():   # flipped to an empty side: back to the other one
			tape.side = 1 - tape.side
			tape.flipped = false
			_stations()
	else:
		tape.i += 1
		if tape.i >= _side().size():   # end of the side: the deck turns it over (if the other side has songs)
			tape.kind = "flip"
			tape.dur = 2.2
			tape.flipped = not (fita_b if tape.side == 0 else fita_a).is_empty()
			if tape.flipped:
				tape.side = 1 - tape.side
			_stations()
			a_click.play()
	_tape_play()

func _tape_text() -> String:
	var lado := "A" if tape.side == 0 else "B"
	var side := _side()
	if tape.kind == "flip" or tape.i >= side.size():
		if not tape.flipped:
			return "FITA K7: REBOBINANDO O LADO %s. O OUTRO LADO TÁ VAZIO: OUÇA UMA MÚSICA INTEIRA NO RÁDIO PARA GRAVAR." % lado
		return "FITA K7: VIRANDO PARA O LADO %s..." % lado
	var tr: Array = TRACKS[side[tape.i]]
	return "FITA K7 LADO %s (%d/%d): %s - %s, GRAVADA DA %s" % [lado, tape.i + 1, side.size(), tr[1], tr[2], RADIOS[tr[3]].short]

# progress of the side, for the spools on the dash: 0 at the start, 1 at the end
func tape_progress() -> float:
	var side := _side()
	if side.is_empty():
		return 0.0
	var done := 0.0
	var all := 0.0
	for k in side.size():
		var l: float = streams[side[k]].get_length()
		all += l
		if k < tape.i:
			done += l
		elif k == tape.i and tape.kind == "song":
			done += minf(tape.t, l)
	return done / maxf(all, 1.0)


# ---------------------------------------------------------------- reception (idea 9)

func _reception(c: Dictionary) -> float:
	if c.is_empty() or c.id == "fita" or g.N == 0:
		return 1.0
	var t: float = g.t
	var road: String = g.cfg.road
	var i: int = int(g.pos / g.SEG) % g.N
	# height against the land around: valleys shadow the signal, hilltops see the tower
	var mean := 0.0
	for k in [-60, -30, 30, 60]:
		mean += g.Y[posmod(i + k, g.N)]
	var lift := clampf((g.Y[i] - mean / 4.0) / 900.0, -1.0, 1.0)
	var night := 1.0 - clampf(absf(fposmod(g.tday, 4.0) - 2.0) / 1.2, 0.0, 1.0)
	var wob := 0.06 * sin(t * 0.37) + 0.04 * sin(t * 1.13 + 1.7)
	if c.band == "AM":   # AM bounces off the sky at night; by day it fades, and storms crackle on it
		return clampf(0.3 + 0.62 * night + 0.08 * lift - 0.15 * g.rain + wob, 0.05, 1.0)
	var d := absf(fposmod(float(i) / g.N - float(c.tower) + 0.5, 1.0) - 0.5)   # 0..0.5 of a lap from the tower
	var far := smoothstep(0.18, 0.5, d)
	var home: float = c.home.get(road, 0.8)
	return clampf(home - 0.32 * far + 0.3 * lift + 0.08 - 0.05 * g.rain + wob, 0.05, 1.0)


# ---------------------------------------------------------------- every frame

func _process(dt: float) -> void:
	if not g.is_processing():   # tests freeze the game to compare frames
		return
	dt = minf(dt, 0.05)
	if not _ensure_audio():
		return
	var c := cur()
	var on_radio: bool = not c.is_empty() and c.id != "fita"
	for si in RADIOS.size():
		var tuned: bool = on_radio and si == g.radio_st
		if _advance(si, dt, tuned) and tuned:
			_apply_item(si, false)
	if not c.is_empty() and c.id == "fita":
		tape.t += dt
		if tape.t >= tape.dur:
			_tape_next()
		var wow := 0.004 * sin(g.t * TAU * 0.55) + 0.0015 * sin(g.t * TAU * 6.3)
		g.a_music.pitch_scale = 1.0 + wow
	radio_now_playing()
	_voice_step(g.radio_st if on_radio else -1)
	duck = move_toward(duck, 1.0 if a_voice.playing else 0.0, dt * (5.0 if a_voice.playing else 1.5))

	# reception: music never cuts out, static comes and goes
	q_raw = _reception(c)
	q = lerpf(q, q_raw, minf(1.0, dt * 1.5))
	var tuning: bool = g.static_t > 0.0
	g.static_t = maxf(0.0, g.static_t - dt)
	if on_radio and q < 0.45 and rng.randf() < dt * (0.45 - q) * 6.0:
		crackle = rng.randf_range(0.08, 0.25)
		if q < 0.3:
			g.static_t = maxf(g.static_t, crackle * 0.6)   # the display loses the station for a moment
	crackle = maxf(0.0, crackle - dt)
	var hiss := 0.0
	if tuning:
		hiss = 0.5
	elif on_radio:
		hiss = pow(1.0 - q, 1.6) * 0.32 + crackle * 0.8
	a_static.volume_db = linear_to_db(maxf(hiss, 0.0001))
	var tape_on: bool = not c.is_empty() and c.id == "fita"
	a_hiss.volume_db = linear_to_db(0.035) if tape_on else -80.0
	var music := 0.0001 if tuning else (0.55 + 0.45 * q if on_radio else 1.0)
	g.a_music.volume_db = linear_to_db(maxf(0.0001, music * (1.0 - 0.6 * duck)))
	a_bed.volume_db = linear_to_db(maxf(0.0001, music * 0.8 * (1.0 - 0.6 * duck)))   # ducking: the bed dips under the voice
	a_jingle.volume_db = linear_to_db(maxf(0.0001, music * (1.0 - 0.5 * duck)))
	a_voice.volume_db = linear_to_db(maxf(0.0001, music)) + VOZ_GAIN_DB
	if on_radio:
		bus_lp.cutoff_hz = lerpf(1700.0, 3400.0, q) if c.band == "AM" else lerpf(2600.0, 12000.0, q * q)
	else:
		bus_lp.cutoff_hz = 7000.0 if tape_on else 16000.0

	# a quiet word when the signal goes and when it comes back
	notice_cd = maxf(0.0, notice_cd - dt)
	if on_radio and g.started and g.state == "drive":
		weak_t = weak_t + dt if q < 0.35 else 0.0
		if weak_t > 3.0 and not was_weak:
			was_weak = true
			if notice_cd <= 0.0:
				notice_cd = 25.0
				g.hud.notice(("%s CHIANDO: DE DIA O AM NÃO VAI LONGE" if c.band == "AM" else "%s CHIANDO: O SINAL CAI NO VALE") % c.short, 3.5)
		elif was_weak and q > 0.65:
			was_weak = false
			if notice_cd <= 0.0:
				notice_cd = 25.0
				g.hud.notice("SINAL DA %s VOLTANDO" % c.short, 3.0)
	elif not on_radio:
		was_weak = false
		weak_t = 0.0

func drive_key(k: int) -> bool:
	if k == KEY_T and cur().get("id", "") == "fita":   # turn the tape over
		flip_tape()
		return true
	return false


# ---------------------------------------------------------------- dash and screen

# the tape's spools on the Besouro's deck: the left one empties as the side plays
func draw_cabin_mid(ck) -> void:
	if g.cam != 0 or cur().get("id", "") != "fita":
		return
	var reels: Array = g.car.layout.reels
	if reels.size() < 2:
		return
	var p := tape_progress()
	var full := [1.0 - p, p] if tape.side == 0 else [p, 1.0 - p]
	for k in 2:
		var r: Array = reels[k]
		ck.draw_circle(Vector2(r[0], r[1]), 1.3 + 0.9 * full[k], Color("6e4526"))
		ck.draw_circle(Vector2(r[0], r[1]), 1.1, Color("e6e8ee"))
	ck.draw_rect(Rect2(reels[0][0] + 2.5, reels[0][1] + 1.2, reels[1][0] - reels[0][0] - 5.0, 0.6), Color("2b1a12"))
	if int(g.t * 1.5) % 2 == 0 or tape.kind == "song":
		ck.draw_rect(Rect2(reels[0][0] - 14.5, reels[0][1] - 0.5, 1.0, 1.0), Color("f0484a"))   # play light (blinks while turning over)

func _open_screen() -> void:
	g.menu.open_screen("RÁDIO E FITA K7", _build_screen)

func _build_screen(body: Control) -> void:
	var m = g.menu
	var amber := Color("f2a62a")
	var ink := Color("e6e8ee")
	var dim := Color("6f86a8")
	m.label("MÚSICAS OUVIDAS ATÉ O FIM: %d/%d" % [heard.size(), TRACKS.size()], 8, ink, Vector2(0, 0), body)
	for si in RADIOS.size():
		var x := 0.0
		var y := 20.0 + si * 74.0
		var st: Dictionary = RADIOS[si]
		var tag := "PEGA MELHOR À NOITE" if st.band == "AM" else "FM: CHIA NOS VALES"
		m.label("%s  ·  %s  ·  %s" % [st.name, st.dj, tag], 8, amber, Vector2(x, y), body)
		var k := 0
		for i in TRACKS.size():
			if TRACKS[i][3] != si:
				continue
			var ok := heard.has(i)
			m.label(("* " if ok else "  ") + "%s - %s" % [TRACKS[i][1], TRACKS[i][2]], 8, ink if ok else dim, Vector2(x + 8, y + 14 + k * 12), body)
			k += 1
	var y2 := 250.0
	m.label("FITA K7 DO BESOURO (R ATÉ \"FITA\", T VIRA O LADO)", 8, amber, Vector2(0, y2), body)
	for s in 2:
		var side: Array = fita_a if s == 0 else fita_b
		var names: Array = []
		for i in side:
			names.append(TRACKS[i][2])
		var txt := ", ".join(names) if not names.is_empty() else "VAZIO"
		var l = m.label("LADO %s (%d/%d): %s" % ["AB"[s], side.size(), FITA_LEN, txt], 8, ink, Vector2(0, y2 + 14 + s * 26), body)
		l.size = Vector2(680, 24)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
	m.label("OUÇA UMA MÚSICA INTEIRA NO RÁDIO DO BESOURO E ELA É GRAVADA NA FITA.", 8, dim, Vector2(0, y2 + 66), body)
