
#-------------------------------------------------------------------------------
#Dados
I = 1:9 #Conjunto de Vôos
H = 1:5 #Conjunto de Helicópteros
P = 1:7 #Conjunto de Unidades Marítmas
tat = 9 #45min: Intervalo de tempo mínimo, em unidades de 5min, entre vôos consecutivos por um mesmo helicóptero
d = 48 #4h ou 240min: Atraso máximo permitido, em min, na hora de partida de um Vôo de Tabela ou Comitiva
tu = 3*ones(9) #Tempo de permanência do vôo em uma UM
T = 1:134 #1 -> 07:00hs e 146 -> 19:00hs (qtos 5 min)
tf = Int.(ceil.([
    104;
    93;
    91;
    103;
    79;
    87;
    85;
    87;
    100
]/5)) #Alterar #Tempo de Vôo a cada unidade marítima (em min)
r = [
    2;
    1;
    70;
    98;
    1;
    24;
    68;
    92;
    104
] #Horário de Partida do vôo i (escala de 5min)
M = [
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;
    1   1	1  1	1;     
]#Matriz que define compatibilidade entre o vôo (linha) e helicóptero (coluna)
I0 = [
    1;
    3;
    4;
    6;
    7;
    8;
    9
] #Vôo de Tabela
I1 = [2] #Vôos transferidos do dia anterior
I2 = [5] #Vôos com dois ou mais dias de atraso
Ic = [] #Vôos de comitiva
Ih =[findall(M[:,h] .> 0) for h ∈ H] #Conjunto dos vôos do helicóptero h
Ip=[
    [6],
    [2],
    [9],
    [7],
    [3,8],
    [1,4],
    [5]
] #Conjunto de vôo com destino a UM p
Hn = [1,2,3] #Helicóptero normal
Hp = [4] #Helicóptero pool -->> pode crescer
Hs = [5] #Helicóptero spot -->> pode crescer
Hi = [findall(M[i,:] .> 0) for i ∈ I] #Conj. dos Helicópteros para fazer o vôo i
#Fator de conversão da unidade temporal
F = 5
α = 0.5
