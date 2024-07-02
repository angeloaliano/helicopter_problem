
#-------------------------------------------------------------------------------
#Dados
I = 1:37 #Conjunto de Vôos
H = 1:11 #Conjunto de Helicópteros
P = 1:17 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(37) #Tempo de permanência do vôo em uma UM
T = 1:146 #1 -> 07:00hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([
    95 ;
    101;
    94 ;
    98 ;
    108;
    94 ;
    84 ;
    88 ;
    86 ;
    101;
    106;
    93 ;
    100;
    80 ;
    81 ;
    84 ;
    87 ;
    87 ;
    86 ;
    87 ;
    99 ;
    89 ;
    109;
    84 ;
    87 ;
    84 ;
    87 ;
    107;
    91 ;
    79 ;
    84 ;
    86 ;
    128;
    94 ;
    85 ;
    128;
    101    
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [1  ;
2  ;
29 ;
11 ;
7  ;
61 ;
1  ;
4  ;
63 ;
88 ;
107;
1  ;
33 ;
62 ;
82 ;
112;
1  ;
38 ;
55 ;
86 ;
1  ;
39 ;
80 ;
109;
1  ;
5  ;
40 ;
101;
1  ;
36 ;
87 ;
108;
3  ;
6  ;
10 ;
41 ;
76 ] #Horário de Partida do vôo i (escala de 5min)
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
1	1	1	1	1	1	1	1	1	1	1;]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
2 ;
3 ;
4 ;
5 ;
6 ;
8 ;
9 ;
10;
11;
13;
14;
15;
16;
18;
19;
20;
22;
23;
24;
26;
27;
28;
30;
31;
32;
33;
34;
35;
36;
37] #Vôo de Tabela
I1 = [
1;
7;
12;
17;
21;
25;
29] #Vôos transferidos do dia anterior
I2 = [] #Vôos com dois ou mais dias de atraso
Ic = [] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
[13],
[21],
[15,32,29],
[19,27,37],
[3],
[9],
[16,20,30],
[23],
[2,5,10],
[14,26,31,35,17],
[33],
[28],
[11],
[36],
[8],
[18,12],
[4,6,22,24,34,1,7,25]
] #Conjunto de vôo com destino a UM p
Hn = [1,2,3,4,5,6,7,8,9,10,11] #Helicóptero normal
Hp = [] #Helicóptero pool -->> pode crescer
Hs = [] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
