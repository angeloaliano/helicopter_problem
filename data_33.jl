
#-------------------------------------------------------------------------------
#Dados
I = 1:33 #Conjunto de Vôos
H = 1:11 #Conjunto de Helicópteros
P = 1:20 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(length(I)) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 06:55hs e 146 -> 19:00hs (qtos 5 min)
tf = [
    66;
    16;
    22;
    17;
    16;
    16;
    20;
    23;
    16;
    17;
    22;
    17;
    16;
    21;
    22;
    16;
    16;
    22;
    21;
    18;
    17;
    18;
    21;
    18;
    17;
    23;
    24;
    8 ;
    21;
    27;
    18;
    23;
    19    
]
r = [
    1  ;
    1  ;
    1  ;
    1  ;
    34 ;
    79 ;
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
    75 ;
    87 ;
    1  ;
    1  ;
    1  ;
    28 ;
] #Horário de Partida do vôo i (escala de 5min)
M = [
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	1	0	0	0	0	0	0	0	0 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    0	0	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	1	1	1	1	1	1	1	1	1 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	1	0	0	0	0	0	0	0	0 ;
    1	1	1	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;    
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
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
    32;
    27;
    25;
    24;
    23;
    22;
    20;
    18;
    17;
    16;
    15;
    11;
    10;
    8 ;
    3 ;
    2 ;
    1 ;       
] #Vôos transferidos do dia anterior
I2 = [
    4;
    7;
    30;
    31;     
] #Vôos com dois ou mais dias de atraso
Ic = [33] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
[15],
[27],
[6],
[13],
[7],
[31],
[11],
[10],
[5],
[33],
[29,22],
[19],
[25,32],
[12],
[14],
[26],
[9,21,28,1,17,18,24,30],
[20],
[2,8,23,16],
[4]
] #Conjunto de vôo com destino a UM p
Hn = [
    2;
    6;
    7;
    8;
    9;
    10;
    11; 
] #Helicóptero normal
Hp = [
2
] #Helicóptero pool -->> pode crescer
Hs = [
    3;
    4;
    5  
] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
