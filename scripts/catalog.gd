extends RefCounted
# Everything the player can choose: cars, roads, weather and time of day.
# Numbers here are the whole difference between the choices; the game code only reads them.

const CAR_IDS := ["besouro", "picape", "gt"]
const ROAD_IDS := ["terra", "br", "expressa"]
const WEATHER_IDS := ["sol", "chuva", "variavel"]
const TIME_IDS := ["dia", "entardecer", "noite", "ciclo"]

const WEATHER := {
	"sol": {"name": "SOL", "desc": "Céu aberto, asfalto seco e poeira na terra."},
	"chuva": {"name": "CHUVA", "desc": "Limpador ligado, poças e asfalto molhado."},
	"variavel": {"name": "VARIÁVEL", "desc": "Sol, nuvem, pancada de verão e, se der sorte, arco-íris."},
}
const TIMES := {
	"dia": {"name": "DIA", "desc": "Luz cheia, dá para ver longe.", "tday": 0.0},
	"entardecer": {"name": "ENTARDECER", "desc": "Sol baixo e as primeiras luzes acendendo.", "tday": 1.0},
	"noite": {"name": "NOITE", "desc": "Farol, lanterna e o rádio fazendo companhia.", "tday": 2.0},
	"ciclo": {"name": "DIA INTEIRO", "desc": "O tempo passa: dia, tarde, noite e madrugada.", "tday": 0.0},
}

# Sky keyframes per weather: day, dusk, night, dawn (the cycle runs in this order).
const SKIES := {
	"chuva": [
		{"top": "4a6a94", "hor": "a9c0d8", "hf": "4d6a88", "hn": "27405a", "gr": "1d4030", "amb": 1.0},
		{"top": "1e2c52", "hor": "6f7fb0", "hf": "2b3a63", "hn": "152238", "gr": "10261f", "amb": 0.7},
		{"top": "070b18", "hor": "1a2547", "hf": "0f1730", "hn": "090e1c", "gr": "0a1614", "amb": 0.38},
		{"top": "2a3560", "hor": "e0957a", "hf": "4a3f66", "hn": "1c2238", "gr": "14291f", "amb": 0.75}],
	"sol": [
		{"top": "3d6fb8", "hor": "cfe0f2", "hf": "6f97c4", "hn": "2f5a3a", "gr": "2f7a40", "amb": 1.2},
		{"top": "3a2a55", "hor": "f2a62a", "hf": "6a4a7a", "hn": "2b1a2a", "gr": "1d3020", "amb": 0.8},
		{"top": "05070c", "hor": "1a2547", "hf": "0f1730", "hn": "070b12", "gr": "0a1614", "amb": 0.42},
		{"top": "2a3560", "hor": "e89a7a", "hf": "6a4a7a", "hn": "1c2238", "gr": "14291f", "amb": 0.8}],
}

const CARS := {
	"besouro": {
		"name": "BESOURO 1973", "desc": "Motor atrás, molas macias, volante lento. Balança em tudo.",
		"stats": [2, 4, 2],
		"top": 100.0, "acc": 13.0, "brake": 34.0, "steer_rate": 6.0, "grip": 9.0, "curve_push": 0.14,
		"spring_k": 46.0, "spring_c": 3.0, "pitch_k": 58.0, "pitch_c": 6.0, "roll_k": 36.0, "roll_c": 2.5, "roll_gain": 1.0, "hole_gain": 1.0,
		"gear_lo": [0.0, 16.0, 32.0, 52.0], "gear_hi": [16.0, 32.0, 52.0, 110.0], "eng_base": 0.9, "eng_span": 0.45,
		"camh": 820.0, "cockpit": "cockpit", "player": "player",
		"wheel_x": [-28.0, 19.0], "brake_x": 22.5, "brake_y": -17.0,
		"layout": {
			"wheel": [112, 164, 52], "wheel_style": "besouro",
			"speedo": [120.5, 138.5, 9.0, 120.0], "tach": [], "fuel": [148.5, 150.5, 6.0], "clock": [],
			"label": [198, 144], "reels": [[210, 162], [226, 162]], "eq": [], "radio_hit": [182, 136, 72, 36],
			"mirror": [170, 25, 44, 5], "anchor": [192, 33], "hang": ["rosary", "dice"],
			"dog": [233, 95], "fan": [160.5, 104.5],
			"wipers": [[118, 124], [232, 124]], "wlen": 80.0, "glass": [34, 40, 350, 119], "side": [3, 90, 19, 4],
		},
	},
	"picape": {
		"name": "PICAPE RURAL 1979", "desc": "Cabine alta, feixe de molas duro, direção pesada. Feita pra terra.",
		"stats": [2, 2, 1],
		"top": 95.0, "acc": 10.0, "brake": 30.0, "steer_rate": 4.5, "grip": 7.5, "curve_push": 0.15,
		"spring_k": 72.0, "spring_c": 3.4, "pitch_k": 70.0, "pitch_c": 5.0, "roll_k": 30.0, "roll_c": 2.2, "roll_gain": 1.45, "hole_gain": 1.3,
		"gear_lo": [0.0, 20.0, 45.0], "gear_hi": [20.0, 45.0, 105.0], "eng_base": 0.72, "eng_span": 0.42,
		"camh": 1050.0, "cockpit": "cockpit_picape", "player": "player_picape",
		"wheel_x": [-30.0, 21.0], "brake_x": 26.5, "brake_y": -16.0,
		"layout": {
			"wheel": [108, 170, 58], "wheel_style": "picape",
			"speedo": [106.5, 142.5, 7.0, 120.0], "tach": [], "fuel": [136.5, 142.5, 5.0], "clock": [],
			"label": [196, 142.5], "reels": [], "eq": [], "radio_hit": [182, 136, 64, 26],
			"mirror": [167, 13, 50, 10], "anchor": [192, 26], "hang": ["ribbons"],
			"dog": [], "fan": [],
			"wipers": [[110, 120], [240, 120]], "wlen": 86.0, "glass": [36, 30, 348, 118], "side": [2, 80, 18, 6],
		},
	},
	"gt": {
		"name": "SEDÃ GT 1989", "desc": "Baixo, firme e rápido. Volante preciso e motor que gosta de giro.",
		"stats": [5, 2, 5],
		"top": 140.0, "acc": 18.0, "brake": 42.0, "steer_rate": 7.5, "grip": 11.0, "curve_push": 0.12,
		"spring_k": 85.0, "spring_c": 7.0, "pitch_k": 80.0, "pitch_c": 8.0, "roll_k": 55.0, "roll_c": 5.0, "roll_gain": 0.6, "hole_gain": 0.8,
		"gear_lo": [0.0, 20.0, 40.0, 65.0, 95.0], "gear_hi": [20.0, 40.0, 65.0, 95.0, 150.0], "eng_base": 1.0, "eng_span": 0.55,
		"camh": 700.0, "cockpit": "cockpit_gt", "player": "player_gt",
		"wheel_x": [-29.0, 20.0], "brake_x": 20.0, "brake_y": -15.0,
		"layout": {
			"wheel": [118, 172, 46], "wheel_style": "gt",
			"speedo": [96.5, 142.5, 11.0, 200.0], "tach": [152.5, 142.5, 11.0], "fuel": [], "clock": [117, 127.5],
			"label": [205, 134.5], "reels": [], "eq": [203, 149, 62, 9], "radio_hit": [196, 128, 76, 44],
			"mirror": [169, 25, 46, 8], "anchor": [192, 36], "hang": ["pine"],
			"dog": [], "fan": [],
			"wipers": [[122, 104], [238, 104]], "wlen": 74.0, "glass": [44, 40, 342, 104], "side": [2, 77, 16, 6],
		},
	},
}

# lanes: positions across the road (-1..1). "ours": lanes the player's direction uses, left to right.
# A two-way road has oncoming traffic on the road itself, so overtaking means using their lane.
const ROADS := {
	"terra": {
		"name": "ESTRADA DO SÍTIO", "desc": "Terra batida entre cafezais e porteiras. Mão dupla: ultrapasse olhando.",
		"lanes": [-0.5, 0.5], "ours": [1], "roadw": 1500.0, "two_way": true, "median": "none", "surface": "terra",
		"track": [[60, 0, 0], [90, 2.4, 10], [60, -3.2, -8], [80, 0, 16], [100, 3.6, -12], [60, -2.0, 0], [120, 0, 20], [80, -3.8, -24],
			[60, 2.8, 10], [100, 0, -14], [90, 3.4, 18], [70, -3.0, -10], [120, 0, 0], [80, 2.2, 26], [60, -3.6, -20], [100, 0, 8],
			[90, -2.6, -12], [80, 3.2, 6], [120, 0, 0]],
		"undulation": 1.4, "rough_base": 0.55, "noise": 1.6, "hole_gap": 10, "hole_p": 0.006, "hole_k": 0.02, "patch_p": 0.25, "puddle_p": 0.35,
		"stop": "venda", "stop_sign": "placa_venda", "stop_ww": 4400.0,
	},
	"br": {
		"name": "BR-116", "desc": "Federal duplicada: três faixas, caminhões, posto e guard-rail.",
		"lanes": [-0.667, 0.0, 0.667], "ours": [0, 1, 2], "roadw": 2000.0, "two_way": false, "median": "rail", "surface": "asfalto",
		"track": [[80, 0, 0], [160, 1.6, 12], [120, 0, -10], [140, -2.2, 0], [100, 0, 22], [180, 2.6, -14], [220, 0, 0], [120, -1.4, 18], [120, 1.4, -18],
			[160, 0, 10], [200, -2.8, -20], [140, 0, 0], [160, 2, 26], [120, 0, -16], [200, -1.8, 0], [240, 0, 8], [160, 3, -10], [140, -3, 10], [200, 0, 0]],
		"undulation": 1.0, "rough_base": 0.0, "noise": 1.0, "hole_gap": 20, "hole_p": 0.001, "hole_k": 0.008, "patch_p": 0.3, "puddle_p": 0.2,
		"stop": "posto", "stop_sign": "sign_posto", "stop_ww": 5600.0,
	},
	"expressa": {
		"name": "RODOVIA EXPRESSA", "desc": "Concreto liso, quatro faixas, luz contínua. Para quem gosta de embalo.",
		"lanes": [-0.75, -0.25, 0.25, 0.75], "ours": [0, 1, 2, 3], "roadw": 2600.0, "two_way": false, "median": "jersey", "surface": "concreto",
		"track": [[120, 0, 0], [240, 1.2, 6], [200, 0, -4], [260, -1.6, 0], [300, 0, 8], [220, 1.8, -6], [260, 0, 0], [240, -1.2, 10],
			[300, 0, -10], [220, 1.4, 0], [280, 0, 6], [240, -1.8, -8], [300, 0, 0]],
		"undulation": 0.35, "rough_base": 0.0, "noise": 0.4, "hole_gap": 60, "hole_p": 0.0004, "hole_k": 0.002, "patch_p": 0.05, "puddle_p": 0.12,
		"stop": "parada", "stop_sign": "placa_parada", "stop_ww": 6000.0,
	},
}

# Towns on the distance signs of each road (made up, but they sound real). The road runs through them in a
# shuffled order; every name fits a sign (13 letters at most). "exits": side exits on the expressway gantries.
const TOWNS := {
	"terra": ["CÓRREGO FUNDO", "VARGEM BONITA", "SÃO BENTO", "POUSO DO ROSA", "SANTA LUZIA", "BARRA DO TATU",
		"BOA ESPERANÇA", "ÁGUA LIMPA", "MORRO DO CAFÉ", "SANTA RITA", "BREJO ALEGRE", "PEDRA BRANCA"],
	"br": ["PINHAL ALTO", "RIO DAS ANTAS", "CAMPINA VERDE", "LAGOA DOURADA", "PONTE ALTA", "SÃO MATEUS",
		"CERRO AZUL", "BALSA NOVA", "TABOÃO", "SERRA DO MAR", "PINHEIROS", "REGISTRO"],
	"expressa": ["NOVA ARCÁDIA", "VALE DO SOL", "SÃO CAETANO", "CIDADE NOVA", "PORTAL DO SOL", "MONTE MOR",
		"ITAPECERICA", "BOA VISTA", "RIO CLARINHO", "SANTA BÁRBARA"],
	"exits": ["JARDIM IPÊ", "VILA NOVA", "PARQUE SUL", "DISTRITO", "CENTRO", "AEROPORTO", "JARDIM ROSA", "ESPERANÇA"],
# ---------------------------------------------------------------- mundo vivo (scripts/features/mundo_*.gd)

# Painted on the back of trucks (and buses and tractors), readable once you get close.
const FRASES := [
	"DEUS É FIEL", "NÃO TENHO TUDO QUE AMO, MAS AMO TUDO QUE TENHO", "FILHO DE PEIXE, PEIXINHO É",
	"QUEM VÊ CARA NÃO VÊ CORAÇÃO", "O QUE É MEU TÁ GUARDADO", "MÃE, TE AMO",
	"SORRIA, O PATRÃO ESTÁ PAGANDO", "DEVAGAR TAMBÉM CHEGO", "VIDA DE CAMINHONEIRO: SAUDADE E ESTRADA",
	"QUEM PLANTA COLHE", "A PRESSA É INIMIGA DA PERFEIÇÃO", "NÃO ME SIGA, TAMBÉM ESTOU PERDIDO",
	"SAÍ DE CASA, MAS A CASA NÃO SAIU DE MIM", "FOI DEUS QUEM ME DEU", "SÓ JESUS SALVA",
	"MAIS VALE UM BURRO QUE ME CARREGUE DO QUE UM CAVALO QUE ME DERRUBE", "EM CASA DE FERREIRO, ESPETO DE PAU",
	"QUEM ME VÊ SORRINDO NÃO SABE O QUANTO JÁ CHOREI", "ESTE É O MEU GANHA-PÃO", "LEVE NA ALMA, PESADO NA CARGA",
	"HOJE TEM, AMANHÃ QUEM SABE", "DIRIJO EU, DEUS ME GUIA", "SE ESTOU NA FRENTE, É PORQUE CHEGUEI PRIMEIRO",
	"PAI DE FAMÍLIA, NÃO BUZINE", "A ESTRADA É MINHA CASA", "SAUDADE É O AMOR QUE FICA",
	"QUEM NÃO ARRISCA NÃO PETISCA", "O BOM FILHO À CASA TORNA", "TUDO POSSO NAQUELE QUE ME FORTALECE",
	"NÃO SOU DONO DO MUNDO, MAS SOU FILHO DO DONO", "LAR DOCE CABINE", "POBRE MAS LIMPINHO",
	"DEVAGAR SE VAI AO LONGE", "VOU MAS VOLTO", "ELA DISSE QUE IA ESPERAR", "100% MOVIDO A CAFÉ",
]
const FRASES_TRATOR := ["DEVAGAR SE VAI AO LONGE", "DEUS É FIEL", "QUEM PLANTA COLHE", "FILHO DA TERRA",
	"O SOL NASCE PARA TODOS", "TRABALHO DIGNIFICA", "CHUVA É BÊNÇÃO", "SEM PRESSA"]
const FRASES_ONIBUS := ["DEUS É FIEL", "BOA VIAGEM", "VOLTE SEMPRE", "SAUDADE DE CASA", "FÉ EM DEUS", "VIAJAR É PRECISO"]

# Rare roadside events (mundo_eventos.gd): one every ~3 minutes, never the same twice in a row.
# roads: where it can happen; luz: "dia" (daylight), "noite", "" (any); aviso: discreet line when it shows up.
const EVENTOS := {
	"boiada": {"roads": ["terra"], "luz": "", "aviso": "BOIADA NA ESTRADA: O PEÃO VAI NA FRENTE, SEM PRESSA"},
	"carroca": {"roads": ["terra"], "luz": "", "aviso": "UMA CARROÇA NO ACOSTAMENTO, NO PASSO DO CAVALO"},
	"cavalo": {"roads": ["terra", "br"], "luz": "dia", "aviso": "CAVALO SOLTO PASTANDO NA BEIRA DA ESTRADA"},
	"romeiros": {"roads": ["terra", "br"], "luz": "dia", "aviso": "ROMEIROS A PÉ, A CAMINHO DA CAPELA"},
	"pamonha": {"roads": ["terra", "br"], "luz": "dia", "aviso": "OLHA A PAMONHA! PAMONHA FRESQUINHA, CURAU E MILHO VERDE"},
	"carro_som": {"roads": ["br", "terra"], "luz": "", "aviso": "É HOJE, NA PRAÇA DA MATRIZ: QUERMESSE COM QUENTÃO E PASTEL!"},
	"quermesse": {"roads": ["terra", "br"], "luz": "", "aviso": "QUERMESSE NA BEIRA DA ESTRADA: BANDEIRINHAS E PASTEL"},
	"ciclista": {"roads": ["terra", "br"], "luz": "dia", "aviso": "CICLISTA NO ACOSTAMENTO: DÊ ESPAÇO"},
	"caramelo": {"roads": ["br", "terra"], "luz": "", "aviso": "UM VIRA-LATA CARAMELO VENDO A ESTRADA PASSAR"},
	"borracharia": {"roads": ["br"], "luz": "", "aviso": "BORRACHARIA 24 H, PLACA PINTADA À MÃO"},
	"led": {"roads": ["expressa"], "luz": "", "aviso": "O PAINEL DE LED MANDOU RECADO"},
	"helicoptero": {"roads": ["expressa", "br"], "luz": "dia", "aviso": "HELICÓPTERO DA REPORTAGEM DE OLHO NO TRÂNSITO"},
	"balao": {"roads": ["terra", "br", "expressa"], "luz": "dia", "aviso": "UM BALÃO COLORIDO SUBINDO DEVAGAR"},
	"periquitos": {"roads": ["terra", "br", "expressa"], "luz": "dia", "aviso": "REVOADA DE PERIQUITOS, NA ALGAZARRA"},
	"vagalumes": {"roads": ["terra"], "luz": "noite", "aviso": "VAGA-LUMES PISCANDO NO PASTO"},
}
# Funny messages for the expressway LED panel event.
const LED_RECADOS := [["BEBEU?", "CHAME UM AMIGO"], ["SEM PRESSA", "A VIDA AGRADECE"], ["CHUVA?", "FAROL BAIXO"],
	["MANDE UM", "OI PRA MÃE"], ["CAFÉ", "NA PRÓXIMA"], ["SORRIA", "VOCÊ ESTÁ NA BR"]]

# Seasons (mundo_epoca.gd): "hoje" follows the system date; any of them can be picked all year.
const EPOCA_IDS := ["hoje", "nenhuma", "verao", "junina", "ipes", "natal"]
const EPOCAS := {
	"hoje": {"name": "PELO CALENDÁRIO", "desc": "A época segue a data de hoje."},
	"nenhuma": {"name": "SEM ÉPOCA", "desc": "A estrada de sempre, sem enfeite."},
	"verao": {"name": "VERÃO (JANEIRO)", "desc": "Pancada de chuva no meio da tarde, mesmo no sol.", "months": [1]},
	"junina": {"name": "FESTA JUNINA (JUNHO)", "desc": "Bandeirinhas, fogueira e balão no céu.", "months": [6, 7]},
	"ipes": {"name": "IPÊS (AGO-SET)", "desc": "Ipês amarelos, roxos e brancos florindo na beira da estrada.", "months": [8, 9]},
	"natal": {"name": "NATAL (DEZEMBRO)", "desc": "Pisca-pisca nas casas, na capela e nos postes.", "months": [12]},
}
