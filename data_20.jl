
#-------------------------------------------------------------------------------
#Dados
I = 1:20 #Conjunto de Vôos
H = 1:11 #Conjunto de Helicópteros
P = 1:14 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = [
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    3;
    48    
]
 #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 06:55hs e 146 -> 19:00hs (qtos 5 min)
tf = [
    19;
    23;
    18;
    27;
    21;
    8;
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
    66;          
]
r = [
    1;
    1;
    1;
    1;
    34;
    79;
    1;
    1;
    9;
    1;
    1;
    3;
    29;
    33;
    1;
    1;
    1;
    1;
    2;
    28;            
] #Horário de Partida do vôo i (escala de 5min)
M = [
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	1	0	0	0	0	0	0	0	0 ;
    1	1	1	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
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
    0	0	1	1	1	1	1	1	1	1	1 ;
    1	1	1	0	0	0	0	0	0	0	0 ;
    1	1	0	0	0	0	0	0	0	0	0 ;
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
    5;
    6;
    9;
    12;
    13;
    14;
    19;    
] #Vôo de Tabela
I1 = [
    1;
    2;
    3;
    8;
    10;
    11;
    15;
    16;
    17;
    18;    
] #Vôos transferidos do dia anterior
I2 = [
4;
7;   
] #Vôos com dois ou mais dias de atraso
Ic = [20] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
[15],
[6],
[13],
[3],
[7],
[11],
[10],
[5],
[20],
[19],
[12,14],
[9,1,17,18],
[2,8,16],
[4]
] #Conjunto de vôo com destino a UM p
Hn = [
    7;
    8;
    9;
    10;
    11    
] #Helicóptero normal
Hp = [
1;
2;
] #Helicóptero pool -->> pode crescer
Hs = [
    3;
    4;
    5;
    6;    
] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5

