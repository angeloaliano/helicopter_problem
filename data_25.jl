#-------------------------------------------------------------------------------
#Dados
I = 1:25 #Conjunto de Vôos
H = 1:12 #Conjunto de Helicópteros
P = 1:20 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(25) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 07:00hs e 133 -> 18:00hs (qtos 5 min)
tf = Int.(ceil.([146,172,174,120,117,174,119,169,170,
167,176,166,160,165,143,170,148,160,159,110,146,
142,174,163,149]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [1,	54,	1,	52,	99,	10,	9,	2,	7,	49,	93,	46,	2,	3,	95,	1,	65,	1,	51,	8,	13,	101,	4,	67,	1] #Horário de Partida do vôo i (escala de 5min)
M = [1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
0	0	0	1	1	1	0	0	0	0	0	0;
0	0	0	1	1	1	0	0	0	0	0	0;
0	0	0	1	1	1	0	0	0	0	0	0;
0	0	0	1	1	1	0	0	0	0	0	0;
0	0	0	1	1	1	0	0	0	0	0	0;
0	0	0	1	1	1	0	0	0	0	0	0;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
1	1	1	0	0	0	1	1	1	1	1	1;
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [2,4,5,6,7,8,9,10,11,12,13,14,15,17,19,20,21,22,23,24] #Vôo de Tabela
I1 = [1,3,16,18,25] #Vôos transferidos do dia anterior
I2 = [] #Vôos com dois ou mais dias de atraso
Ic = [] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
    [1],
    [2,16],
    [3,23],
    [4,5,7],
    [6],
    [8],
    [9],
    [10],
    [11],
    [12],
    [13],
    [14,18],
    [15],
    [17],
    [19],
    [20],
    [21],
    [22],
    [24],
    [25]
] #Conjunto de vôo com destino a UM p
Hn = [1,2,3,4,5,6,7,8,9,10,11,12] #Helicóptero normal
Hp = [] #Helicóptero pool
Hs = [] #Helicóptero spot
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5


