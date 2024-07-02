
#-------------------------------------------------------------------------------
#Dados
I = 1:55 #Conjunto de Vôos
H = 1:13 #Conjunto de Helicópteros
P = 1:25 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(55) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 06:55hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([96,	117,	91,	135,	107,	41,	98,	83,	104,	92,	103,	89,	115,	92,	106,	108,	78,	81,	112,	103,	100,	107,	112,	116,	101,	113,	102,	100,	100,	105,	99,	89,	94,	80,	115,	116,	100,	107,	95,	114,	103,	107,	99,	330,	101,	113,	102,	100,	100,	105,	99,	89,	94,	80,	115
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [
    1  ;
    1  ;
    1  ;
    1  ;
    34 ;
    31 ;
    1  ;
    1  ;
    9  ;
    1  ;
    1  ;
    3  ;
    29 ;
    33 ;
    1  ;
    1  ;
    1  ;
    1  ;
    2  ;
    1  ;
    38 ;
    1  ;
    1  ;
    1  ;
    1  ;
    3  ;
    1  ;
    3  ;
    15 ;
    1  ;
    1  ;
    1  ;
    4  ;
    13 ;
    1  ;
    110;
    2  ;
    13 ;
    14 ;
    32 ;
    39 ;
    4  ;
    22 ;
    28 ;
    88 ;
    27 ;
    87 ;
    27 ;
    101;
    79 ;
    75 ;
    63 ;
    40 ;
    57 ;
    61          
] #Horário de Partida do vôo i (escala de 5min)
M = [1	1	1	0	0	1	0	0	0	1	1	0	0;
1	1	0	1	1	0	0	0	0	0	0	0	0;
1	1	1	0	0	1	0	0	0	0	0	0	1;
1	1	1	1	0	0	0	0	1	0	0	0	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	0	0	0	0	0	0	0	0	1;
1	1	1	1	1	1	1	1	1	1	1	0	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	1	0	0	0	0	0	0	0	1;
1	1	1	0	1	1	0	1	0	1	0	0	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	0	0	0	0	0	0	0	0	0;	
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	0	1	0	1	0	1	0	0	0	0	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	1	1	1	1	1	1	1	1	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	1	1	1	1	1	0	0	0	1;
1	1	1	0	0	0	1	1	0	0	0	0	0;
1	1	1	1	0	0	0	0	0	0	0	0	0;
1	1	1	1	0	0	0	0	0	0	0	0	0;
1	1	1	1	1	1	1	1	1	1	1	1	0;
1	1	1	1	0	0	0	0	0	0	0	0	0;	
1	1	1	0	0	0	0	0	0	0	0	0	0;
1	1	1	1	1	1	1	1	1	1	1	0	0;
1	1	1	0	0	0	0	0	0	0	0	0	0;
1	1	1	0	0	0	1	0	0	0	0	0	0;
1	1	1	0	1	0	0	0	0	0	0	0	0;
1	1	0	1	0	0	0	1	0	0	0	0	0;	
1	1	1	0	1	0	0	0	0	0	0	1	1;
1	1	0	1	0	0	1	0	1	1	1	1	0;
1	1	0	0	0	0	1	0	0	0	0	0	1;
1	1	1	1	0	0	0	0	0	0	0	0	1;
1	1	1	1	0	0	0	0	0	0	0	0	1;
1	1	1	0	0	0	0	0	0	0	0	0	0;	
1	1	0	0	0	0	0	0	0	0	0	0	1;
1	1	1	1	1	1	1	1	1	0	0	0	1;
1	1	1	1	0	0	1	1	1	1	1	1	1;	
1	1	0	0	0	0	0	0	0	0	0	0	1;
1	1	0	1	0	0	1	1	1	1	0	1	0;
1	1	1	1	0	1	0	1	1	0	0	0	0;
1	1	0	1	0	0	0	0	0	0	0	0	1;
1	1	0	0	0	0	1	0	0	0	0	0	1;
1	1	1	1	0	1	0	0	1	0	0	0	0;
1	1	0	1	1	0	0	0	0	0	0	0	0;
1	1	1	0	0	1	1	1	1	1	0	0	1;
1	1	0	0	0	0	0	0	0	0	0	0	0;
1	1	1	1	1	1	1	1	1	0	0	0	0;
1	1	1	1	1	0	1	1	1	1	1	0	0;
1	1	0	0	0	0	0	0	0	0	0	1	1;
1	1	0	1	1	0	0	0	0	0	0	1	1;
1	1	1	1	0	1	0	1	1	0	0	1	1;
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [5,	6,	9,	12,	13,	14,	19,	21,	26,	28,	29,	33,	34,	37,	38,	39,	40,	41,	42,	43,	46,	48,	49,	53,	54] #Vôo de Tabela
I1 = [1,2,3,	8,	10,	11,	15,	16,	17,	18,	20,	22,	23,	24,	25,	27,	31,	32,	45,	47,	51,	52] #Vôos transferidos do dia anterior
I2 = [4,	7,	30,	35,	36,	50,	55] #Vôos com dois ou mais dias de atraso
Ic = [44] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
[33,15,1,2],
[27,47,43,53],
[3],
[37],
[55],
[35],
[36],
[31],
[11],
[51],
[38,41,44,10,7,6,13],
[29,49,22,5],
[42,25,32,45,19,52],
[12],
[14],
[26,46],
[28,48],
[9,21,34,40,17,30,18,39],
[20],
[50],
[8,16],
[24],
[23],
[4],
[54]
] #Conjunto de vôo com destino a UM p
Hn = [5,6,7,8,9,10,11,12,13] #Helicóptero normal
Hp = [3,4] #Helicóptero pool -->> pode crescer
Hs = [1,2] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
