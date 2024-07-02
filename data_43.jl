
#-------------------------------------------------------------------------------
#Dados
I = 1:43 #Conjunto de Vôos
H = 1:12 #Conjunto de Helicópteros
P = 1:27 #Conjunto de Unidades Marítmas
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
    66;    
]
r = [
    1  ;
    1  ;
    1  ;
    1  ;
    10 ;
    19 ;
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
    10 ;
    1  ;
    1  ;
    1  ;
    1  ;
    3  ;
    1  ;
    15 ;
    27 ;
    1  ;
    1  ;
    1  ;
    4  ;
    63 ;
    1  ;
    1  ;
    2  ;
    61 ;
    110;
    80 ;
    11 ;
    36 ;
    14 ;    
] #Horário de Partida do vôo i (escala de 5min)
M = [
    1	0	0	0	1	0	0	1	1	1	1	1;
    1	1	0	1	0	0	1	1	1	1	1	1;
    1	0	0	1	0	0	0	1	1	1	1	1;
    1	0	0	1	0	1	0	0	1	0	1	1;
    1	1	1	1	1	0	1	1	1	1	1	1;
    0	1	0	0	0	1	1	0	1	0	1	1;
    0	1	0	0	0	0	0	1	1	1	1	1;
    1	1	0	0	1	0	0	0	1	1	0	1;
    1	0	0	0	1	1	1	1	0	1	1	1;
    0	0	0	1	0	0	0	1	1	1	1	1;
    1	0	0	1	0	0	1	1	0	1	1	1;
    1	0	0	0	0	1	0	0	1	0	1	1;
    1	1	0	0	1	0	1	1	0	1	1	1;
    0	0	0	0	0	0	1	0	1	0	1	1;
    0	1	0	0	0	0	0	1	0	1	1	1;
    1	1	0	0	1	0	0	0	1	1	0	1;
    1	0	0	1	0	0	0	1	1	1	1	1;
    1	1	1	1	1	0	0	0	1	1	0	1;
    0	1	0	0	0	0	1	1	1	1	1	1;
    1	0	1	0	0	0	1	1	1	1	0	0;
    1	0	0	1	0	1	0	1	1	1	1	1;
    0	0	1	0	0	0	1	0	1	1	1	1;
    1	1	0	0	0	0	1	0	1	1	1	1;
    0	0	1	0	0	1	0	0	1	1	0	0;
    0	0	0	0	1	1	1	1	1	1	1	1;
    0	1	0	0	1	0	1	1	1	1	1	0;
    0	0	0	0	0	0	0	0	1	1	1	1;
    0	1	0	1	1	1	1	1	1	1	1	1;
    1	0	0	0	0	0	1	1	1	1	1	0;
    1	1	0	1	0	0	1	0	1	1	0	1;
    0	0	1	0	1	0	1	1	1	1	1	1;
    1	0	0	0	1	1	1	1	1	1	1	0;
    0	1	0	0	0	1	0	0	1	1	1	1;
    1	0	1	0	1	0	0	1	1	1	1	1;
    0	0	0	1	1	0	0	1	1	1	1	1;
    1	0	0	1	0	1	0	1	1	1	1	0;
    0	1	1	0	1	1	1	1	1	1	1	1;
    0	0	0	1	0	1	0	1	1	1	1	1;
    0	1	1	1	1	0	0	1	1	1	1	1;
    1	0	1	0	1	0	0	0	1	1	1	1;
    0	1	0	0	0	0	0	0	1	1	1	1;
    1	1	1	1	0	1	0	1	1	1	1	1;
    1	0	0	1	0	0	0	0	1	1	1	1;    
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
    5 ;
    6 ;
    9 ;
    12;
    13;
    14;
    19;
    21;
    26;
    28;
    29;
    33;
    34;
    37;
    38;
    39;
    40;
    41;
    42;
] #Vôo de Tabela
I1 = [
    1 ;
    2 ;
    3 ;
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
    31;
    32;
    35;
    36;
] #Vôos transferidos do dia anterior
I2 = [
    4 ;
    7 ;
    30;    
] #Vôos com dois ou mais dias de atraso
Ic = [43] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
[33,15],
[27],
[6],
[13],
[37],
[35],
[36],
[7],
[31],
[11],
[43,10],
[5],
[29,38,22],
[19],
[42,32],
[25],
[12],
[14],
[41],
[26],
[9,21,28,34,39,40,1,30],
[20],
[2,8,23,16],
[24],
[18],
[17],
[4]
] #Conjunto de vôo com destino a UM p
Hn = [
    1;
    2;
    3;
    4;
    5;
    6;
    7;
    8;    
] #Helicóptero normal
Hp = [
    9;
    10;    
] #Helicóptero pool -->> pode crescer
Hs = [
11;
12
] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
