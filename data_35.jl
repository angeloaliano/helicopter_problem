
#-------------------------------------------------------------------------------
#Dados
I = 1:35 #Conjunto de Vôos
H = 1:12 #Conjunto de Helicópteros
P = 1:26 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(35) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 07:00hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([
149;
124;
154;
149;
146;
154;
158;
152;
160;
153;
144;
160;
154;
114;
148;
144;
181;
152;
128;
108;
92 ;
101;
91 ;
92 ;
113;
91 ;
106;
106;
108;
130;
129;
134;
136;
146;
323
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [
    2  ;
    54 ;
    2  ;
    52 ;
    99 ;
    58 ;
    9  ;
    2  ;
    7  ;
    97 ;
    46 ;
    2  ;
    3  ;
    95 ;
    2  ;
    93 ;
    2  ;
    51 ;
    61 ;
    101;
    2  ;
    67 ;
    2  ;
    2  ;
    2  ;
    2  ;
    2  ;
    2  ;
    2  ;
    34 ;
    74 ;
    100;
    2  ;
    32 ;
    80 
] #Horário de Partida do vôo i (escala de 5min)
M = [1	0	0	1	0	0	0	0	1	1	0	0;
1	1	1	1	1	1	0	1	1	0	1	1;
1	1	0	0	0	0	0	0	1	1	0	0;
1	1	1	0	1	0	0	0	1	1	1	0;
0	1	1	1	1	0	0	1	1	0	1	0;
0	0	1	1	0	1	0	1	1	1	1	1;
0	1	1	0	1	1	1	1	0	0	0	1;
1	0	0	1	0	1	0	1	1	1	0	0;
0	0	0	1	1	0	0	1	1	1	0	1;
1	1	1	0	1	0	0	1	0	1	1	1;
0	1	0	0	1	1	0	0	1	0	1	1;
1	1	0	0	1	1	1	1	1	1	1	0;
0	1	1	0	1	0	1	1	0	0	0	1;
1	1	1	1	0	0	1	0	1	0	0	1;
1	0	1	0	0	0	1	1	0	1	0	0;
0	1	0	1	1	1	1	1	0	0	1	1;
0	1	0	0	0	0	0	0	0	1	1	1;
0	1	0	0	1	0	1	1	1	1	1	0;
0	0	0	0	1	1	1	1	1	1	1	1;
0	0	1	0	1	1	0	0	1	0	0	0;
1	1	0	0	0	0	1	0	1	0	0	1;
0	0	1	0	0	0	1	0	0	1	1	1;
1	1	0	1	0	1	0	1	0	1	1	0;
1	0	1	1	0	0	1	1	1	0	0	0;
0	1	0	0	1	0	1	1	1	1	1	0;
1	1	1	1	1	0	0	0	0	0	0	0;
1	0	1	1	0	0	0	1	1	0	1	1;
1	1	0	0	1	0	0	0	0	1	0	1;
0	1	0	0	0	0	0	1	0	1	1	1;
0	1	0	0	0	1	1	0	1	0	1	0;
1	1	1	1	1	1	1	1	1	1	1	1;
1	0	0	1	0	1	1	0	1	0	1	0;
1	0	0	1	0	0	1	1	0	1	0	1;
1	1	0	1	0	0	1	1	0	1	0	1;
1	0	0	0	1	1	1	1	0	1	0	1;]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
    2 ;
4 ;
5 ;
6 ;
7 ;
8 ;
9 ;
10;
11;
12;
13;
14;
16;
18;
19;
20;
22;
30;
31;
32;
33;
34
] #Vôo de Tabela
I1 = [
    1 ;
3 ;
15;
17;
21;
23;
24;
26;
28;
29
] #Vôos transferidos do dia anterior
I2 = [
    25;
27] #Vôos com dois ou mais dias de atraso
Ic = [35] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
    [26],
    [9],
    [6,33],
    [30,24],
    [13],
    [8],
    [27],
    [29],
    [31],
    [22],
    [4],
    [1],
    [14],
    [25],
    [18],
    [23],
    [3],
    [7,34],
    [10,28],
    [11],
    [15,17],
    [12],
    [32,35],
    [5,20],
    [2,16],
    [21]
] #Conjunto de vôo com destino a UM p
Hn = [1,2,3,4,5,6,7,8,9,10,11,12] #Helicóptero normal
Hp = [] #Helicóptero pool -->> pode crescer
Hs = [] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
