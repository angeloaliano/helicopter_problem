
#-------------------------------------------------------------------------------
#Dados
I = 1:45 #Conjunto de Vôos
H = 1:11 #Conjunto de Helicópteros
P = 1:27 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(45) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 07:00hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([96	117	91	135	107	41	118	113	84	92	103	89	85	92	106	108	78	81	112	103	80	87	112	85	81	113	102	80	80	84	109	79	94	90	115	106	90	87	95	84	93	87	99	87	91
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [1,	1,	1,	1,	34,	79,	1,	1,	9,	1,	1,	3,	29,	33,	1,	1,	1,	1,	2,	1,	38,	1,	1,	1,	1,	3,	1,	75,	87,	1,	1,	1,	4,	63,	1,	1,	2,	61,	110,	80,	39,	88,	82,	6,	55] #Horário de Partida do vôo i (escala de 5min)
M = [1	1	0	0	0	0	0	0	0	0	0;
1	1	0	0	0	0	0	0	0	0	0;
1	1	0	0	0	0	0	0	0	0	0;
1	1	0	0	0	0	0	0	0	0	0;
1	1	0	0	0	0	0	0	0	0	0;
1	1	0	0	0	0	0	0	0	0	0;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
0	0	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	0	0	0	0	0	0	0	0	0;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
1	1	1	1	1	1	1	1	1	1	1;
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [5,6,9,12,13,14,19,21,26,28,29,33,34,37,38,39,40,41,42,43,44,45] #Vôo de Tabela
I1 = [1,2,3,8,10,11,15,16,17,18,20,22,23,24,25,27,31,32,35,36] #Vôos transferidos do dia anterior
I2 = [4,7,30] #Vôos com dois ou mais dias de atraso
Ic = [] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
[1, 9, 17, 18, 21, 24, 28, 30, 34, 39, 40, 44],
[2, 8, 23],
[3],
[4],
[5],
[6],
[7],
[10],
[11],
[12],
[13],
[14],
[15, 33],
[16],
[19],
[20],
[22, 29, 38],
[25, 32, 42],
[26],
[27],
[31],
[35],
[36],
[37],
[41],
[43],
[45],
] #Conjunto de vôo com destino a UM p
Hn = [1,2,3,4,5,6,7,8,9,10,11] #Helicóptero normal
Hp = [] #Helicóptero pool -->> pode crescer
Hs = [] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
