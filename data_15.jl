
#-------------------------------------------------------------------------------
#Dados
I = 1:15 #Conjunto de Vôos
H = 1:7 #Conjunto de Helicópteros
P = 1:11 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(15) #Tempo de permanência do vôo em uma UM
T = 1:134 #1 -> 07:00hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([
    102;
    102;
    87 ;
    79 ;
    120;
    96 ;
    85 ;
    86 ;
    79 ;
    330;
    84 ;
    87 ;
    82 ;
    80 ;
    109
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [
    1 ;
    1 ;
    1 ;
    2 ;
    3 ;
    4 ;
    5 ;
    6 ;
    7 ;
    14;
    29;
    33;
    34;
    36;
    38
] #Horário de Partida do vôo i (escala de 5min)
M = [
    0	0	1	0	0	1	1 ;
    1	0	1	1	1	1	0 ;
    1	1	1	1	1	1	1 ;
    1	1	0	0	0	1	1 ;
    1	1	0	1	1	0	0 ;
    0	1	1	1	0	1	0 ;
    0	0	0	1	1	0	0 ;
    1	0	1	0	1	1	0 ;
    1	0	1	0	1	1	0 ;
    1	1	0	1	1	1	1 ;
    1	0	0	1	0	1	0 ;
    1	0	1	1	1	0	0 ;
    1	1	0	1	0	1	0 ;
    1	1	1	1	0	0	1 ;
    1	1	1	0	1	1	1 
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
    4;
    5;
    6;
    7;
    8;
    9;
    11;
    12;
    13;
    14;
    15
] #Vôo de Tabela
I1 = [
2;
3
] #Vôos transferidos do dia anterior
I2 = [1] #Vôos com dois ou mais dias de atraso
Ic = [10] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
    [7,10],
    [6],
    [15,2,1],
    [14],
    [11],
    [13],
    [4],
    [9],
    [12,3],
    [8],
    [5]
] #Conjunto de vôo com destino a UM p
Hn = [1,2,3] #Helicóptero normal
Hp = [4,5] #Helicóptero pool -->> pode crescer
Hs = [6,7] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
