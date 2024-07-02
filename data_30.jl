
#-------------------------------------------------------------------------------
#Dados
I = 1:30 #Conjunto de Vôos
H = 1:11 #Conjunto de Helicópteros
P = 1:20 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(30) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 07:00hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([
96 ;
300;
118;
84 ;
92 ;
103;
89 ;
85 ;
92 ;
106;
108;
78 ;
81 ;
112;
103;
80 ;
87 ;
112;
85 ;
81 ;
113;
102;
80 ;
109;
94 ;
90 ;
115;
106;
90 ;
87 
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [
1 ;
56;
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
1 ;
4 ;
63;
1 ;
1 ;
2 ;
61
] #Horário de Partida do vôo i (escala de 5min)
M = [
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
    1	1	1	1	1	1	1	1	1	1	1    
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
4;
7;
8;
9;
14;
16;
21;
23;
25;
26;
29;
30
] #Vôo de Tabela
I1 = [
1;
5;
6;
10;
11;
12;
13;
15;
17;
18;
19;
20;
22;
24;
27;
28
] #Vôos transferidos do dia anterior
I2 = [3] #Vôos com dois ou mais dias de atraso
Ic = [2] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
    [10,25],
    [22],
    [8],
    [29],
    [27],
    [28],
    [3],
    [24],
    [6],
    [5],
    [17,30],
    [14],
    [20],
    [7],
    [9],
    [21],
    [1,12,13,19,23,4,16,26],
    [15],
    [18,2],
    [11]
] #Conjunto de vôo com destino a UM p
Hn = [1,2,4,5,6,9,1] #Helicóptero normal
Hp = [3,8] #Helicóptero pool -->> pode crescer
Hs = [7,11] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
