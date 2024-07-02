
#-------------------------------------------------------------------------------
#Dados
I = 1:50 #Conjunto de Vôos
H = 1:11 #Conjunto de Helicópteros
P = 1:31 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(length(I)) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 06:55hs e 146 -> 19:00hs (qtos 5 min)
tf = [
    19;
    23;
    18;
    27;
    21;
    8 ;
    24;
    23;
    17;
    18;
    21;
    18;
    17;
    18;
    21;
    22;
    16;
    16;
    22;
    21;
    16;
    17;
    22;
    17;
    16;
    23;
    20;
    16;
    16;
    17;
    22;
    16;
    19;
    18;
    23;
    21;
    18;
    17;
    19;
    17;
    19;
    17;
    20;
    17;
    18;
    23;
    23;
    21;
    17;
    23;
]
r = [
    1 ;
    1 ;
    1 ;
    1 ;
    34;
    79;
    1 ;
    1 ;
    9 ;
    1 ;
    1 ;
    3 ;
    29;
    33;
    1 ;
    1 ;
    1 ;
    1 ;
    2 ;
    1 ;
    38;
    1 ;
    1 ;
    1 ;
    1 ;
    3 ;
    1 ;
    75;
    87;
    1 ;
    1 ;
    1 ;
    4 ;
    63;
    1 ;
    1 ;
    2 ;
    61;
    11;
    80;
    39;
    88;
    82;
    6 ;
    55;
    14;
    13;
    1 ;
    25;
    1 ;       
] #Horário de Partida do vôo i (escala de 5min)
M = [
    1	1	0	0	0	0	0	0	0	0	0;
    1	1	1	0	0	0	0	0	0	0	0;
    1	1	1	0	0	0	0	0	0	0	0;
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
    1	1	1	0	0	0	0	0	0	0	0;
    1	1	0	0	0	0	0	0	0	0	0;
    1	1	1	0	0	0	0	0	0	0	0;
    1	1	1	1	1	0	0	1	0	0	1;
    1	1	1	1	1	1	0	0	0	0	1;
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
    49;
    47;
    46;
    45;
    44;
    43;
    42;
    41;
    40;
    39;
    38;
    37;
    34;
    33;
    29;
    28;
    26;
    21;
    19;
    14;
    13;
    12;
    9 ;
    6 ;
    5 ;    
] #Vôo de Tabela
I1 = [
    1 ;
    2 ;
    3 ;
    4 ;
    7 ;
    8 ;
    10;
    11;
    15;
    16;
    17;
    18;
    20;
    22;
    23;
    24;
    25;
    27;
    30;
    31;
    32;
    48;
    50;
] #Vôos transferidos do dia anterior
I2 = [
  35;
  36   
] #Vôos com dois ou mais dias de atraso
Ic = [] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
    [33,15],
    [43],
    [27],
    [6],
    [45],
    [13],
    [49],
    [47],
    [50],
    [48],
    [3],
    [37],
    [35],
    [36],
    [7],
    [31],
    [11],
    [10],
    [5],
    [29,38,22],
    [19],
    [42,25,32],
    [12],
    [14],
    [41],
    [26],
    [9,21,28,34,39,40,44,1,17,18,24,30],
    [20],
    [46],
    [2,8,23,16],
    [4],
] #Conjunto de vôo com destino a UM p
Hn = [
    5,
    6,
    7,
    8,
    9,
    10,
    11
] #Helicóptero normal
Hp = [4] #Helicóptero pool -->> pode crescer
Hs = [1,2,3] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5

