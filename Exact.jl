using JuMP, Printf, LinearAlgebra, Random, Gurobi, JLD2, FileIO, Printf
include("dados_60.jl")
g=60
#-------------------------------------------------------
function Exato(λ,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)

    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit", 3600)
    set_optimizer_attribute(modelo, "MIPGap", 0.000)
    #set_optimizer_attribute(modelo, "Cuts", 3)
    #set_optimizer_attribute(modelo, "MIPFocus", 1)
    set_optimizer_attribute(modelo, "OutputFlag", 0)


    #Se designo o vôo i no período t pelo helicóptero h
    @variable(modelo, x[i ∈ I, t ∈ T, h ∈ Hi[i]], Bin)

    #Se o helicóptero h está sendo usado no instante t
    @variable(modelo, y[t ∈ T, h ∈ H], Bin)

    #Se alguma decolagem ocorre no instante t
    @variable(modelo, z[t ∈ T], Bin)

    #Se o helicóptero h é usado em algum vôo
    @variable(modelo, v[h ∈ H], Bin)

    #Se o vôo i não pode ser agendado para o dia
    @variable(modelo, k[i ∈ I], Bin)

    #Objetivos envolvidos
    @variable(modelo, z1>=0)
    @variable(modelo, z2>=0)
    @variable(modelo, z3>=0)


    @objective(modelo,Min,
        λ[1]*z1 + λ[2]*z2 + λ[3]*z3
    )

    @constraint(
    modelo,z1 == 0.4*sum(k[i] for i ∈ Ic) + 0.3*sum(k[i] for i ∈ I2) + 0.2*sum(k[i] for i ∈ I1) + 0.1*sum(k[i] for i ∈ I0)
    )

    @constraint(
    modelo,z2 == 0.5*sum(v[h] for h ∈ Hs) + 0.3*sum(v[h] for h ∈ Hp) + 0.2*sum(v[h] for h ∈ Hn)
    )

    @constraint(
    modelo,z3 == sum(F*(t-r[i])*x[i,t,h] for i ∈ I for h ∈ Hi[i] for t ∈ T)
    )

    @constraint(
    modelo,
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ T) >= length(I0)
    )

    @constraint(
    modelo,[i ∈ I],
    sum(x[i,t,h] for t ∈ T for h ∈ Hi[i]) <= 1
    )

    @constraint(
    modelo,[i ∈ I],
    sum(x[i,t,h] for h ∈ Hi[i] for t ∈ T) + k[i] == 1
    )

    @constraint(
    modelo,[t ∈ T],
    sum(x[i,t,h] for i ∈ I for h ∈ Hi[i]) == z[t]
    )

    @constraint(
    modelo,res[h ∈ H, t ∈ T],
    y[t,h] == sum(x[i,tt,h] for i ∈ Ih[h] for tt ∈ t:-1:maximum([r[i],t-tf[i]-tat+1]))
    )

    @constraint(
    modelo,[h ∈ H],
    sum(y[t,h] for t ∈ T) <= maximum(T)*v[h]
    )

    @constraint(
    modelo,[i ∈ intersect(union(I0,Ic),I)],
    sum((t-r[i])*x[i,t,h] for h ∈ Hi[i] for t ∈ T) <= d
    )

    @constraint(
    modelo,[p ∈ P, i ∈ Ip[p], j ∈ Ip[p], t ∈ T, tt ∈ T; tt>t && i != j],
    tt*sum(x[j,tt,h] for h ∈ Hi[j]) >= t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) - maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(union(I1,I2),Ip[p]), j ∈ intersect(I0,Ip[p]), t ∈ T],
    sum(x[j,tt,h] for h ∈ Hi[j] for tt=1:t-1) + sum(x[i,t,h] for h ∈ Hi[i]) <=1
    )

    @constraint(
    modelo,[i ∈ Ic,j ∈ I, h ∈ intersect(Hi[i],Hi[j]),t ∈ T;i != j],
    sum(x[j,tt,h] for tt=t+1:maximum(T)) + x[i,t,h] <=1
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(Ic,Ip[p]), j ∈ Ip[p], t ∈ T; j != i],
    sum(x[j,tt,h] for h ∈ Hi[j] for tt=t+1:maximum(T)) + sum(x[i,t,h] for h ∈ Hi[i]) <= 1
    )

    #Fixação
    for i ∈ union(I0,Ic)
        for h ∈ Hi[i]
            for t ∈ T
                if  t< r[i] || t > r[i]+d || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    for i ∈ union(I1,I2)
        for h ∈ Hi[i]
            for t ∈ T
                if  t< r[i] || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    optimize!(modelo)

    CPUtime = MOI.get(modelo, MOI.SolveTime())

    X = value.(x)

    Z1 = value(z1)
    Z2 = value(z2)
    Z3 = value(z3)
    N_restricoes = sum(num_constraints(modelo, F, S) for (F, S) in list_of_constraint_types(modelo))
    N_var = num_variables(modelo)
    Gap = MOI.get(modelo, MOI.RelativeGap())


    return (X,CPUtime,Z1,Z2,Z3,N_restricoes,N_var,Gap)
end

function Exato_Tchebycheff(λ,ε,Z_ideal,Z_nadir,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)

    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit", 1800)
    set_optimizer_attribute(modelo, "MIPGap", 0.000)
    #set_optimizer_attribute(modelo, "Cuts", 3)
    #set_optimizer_attribute(modelo, "MIPFocus", 1)
    set_optimizer_attribute(modelo, "OutputFlag", 0)

    #Se designo o vôo i no período t pelo helicóptero h
    @variable(modelo, x[i ∈ I, t ∈ T, h ∈ Hi[i]], Bin)

    #Se o helicóptero h está sendo usado no instante t
    @variable(modelo, y[t ∈ T, h ∈ H], Bin)

    #Se alguma decolagem ocorre no instante t
    @variable(modelo, z[t ∈ T], Bin)

    #Se o helicóptero h é usado em algum vôo
    @variable(modelo, v[h ∈ H], Bin)

    #Se o vôo i não pode ser agendado para o dia
    @variable(modelo, k[i ∈ I], Bin)

    #Objetivos envolvidos
    @variable(modelo, z1>=0)
    @variable(modelo, z2>=0)
    @variable(modelo, z3>=0)

    @variable(modelo, u>=0)


    @objective(modelo,Min,u)

    @constraint(
    modelo,z1 == 0.4*sum(k[i] for i ∈ Ic) + 0.3*sum(k[i] for i ∈ I2) + 0.2*sum(k[i] for i ∈ I1) + 0.1*sum(k[i] for i ∈ I0)
    )

    @constraint(
    modelo,z2 == 0.5*sum(v[h] for h ∈ Hs) + 0.3*sum(v[h] for h ∈ Hp) + 0.2*sum(v[h] for h ∈ Hn)
    )

    @constraint(
    modelo,z3 == sum(F*(t-r[i])*x[i,t,h] for i ∈ I for h ∈ Hi[i] for t ∈ T)
    )

    @constraint(modelo,
    λ[1]*(z1 - Z_ideal[1])/(Z_nadir[1] - Z_ideal[1]) <= u
    )

    @constraint(modelo,
    λ[2]*(z2 - Z_ideal[2])/(Z_nadir[2] - Z_ideal[2]) <= u
    )

    @constraint(modelo,
    λ[3]*(z3 - Z_ideal[3])/(Z_nadir[3] - Z_ideal[3]) <= u
    )

    @constraint(
    modelo,
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ T) >= length(I0)
    )

    @constraint(
    modelo,[i ∈ I],
    sum(x[i,t,h] for t ∈ T for h ∈ Hi[i]) <= 1
    )

    @constraint(
    modelo,[i ∈ I],
    sum(x[i,t,h] for h ∈ Hi[i] for t ∈ T) + k[i] == 1
    )

    @constraint(
    modelo,[t ∈ T],
    sum(x[i,t,h] for i ∈ I for h ∈ Hi[i]) == z[t]
    )

    @constraint(
    modelo,res[h ∈ H, t ∈ T],
    y[t,h] == sum(x[i,tt,h] for i ∈ Ih[h] for tt ∈ t:-1:maximum([r[i],t-tf[i]-tat+1]))
    )

    @constraint(
    modelo,[h ∈ H],
    sum(y[t,h] for t ∈ T) <= maximum(T)*v[h]
    )

    @constraint(
    modelo,[i ∈ intersect(union(I0,Ic),I)],
    sum((t-r[i])*x[i,t,h] for h ∈ Hi[i] for t ∈ T) <= d
    )

    @constraint(
    modelo,[p ∈ P, i ∈ Ip[p], j ∈ Ip[p], t ∈ T, tt ∈ T; tt>t && i != j],
    tt*sum(x[j,tt,h] for h ∈ Hi[j]) >= t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) - maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(union(I1,I2),Ip[p]), j ∈ intersect(I0,Ip[p]), t ∈ T],
    sum(x[j,tt,h] for h ∈ Hi[j] for tt=1:t-1) + sum(x[i,t,h] for h ∈ Hi[i]) <=1
    )

    @constraint(
    modelo,[i ∈ Ic,j ∈ I, h ∈ intersect(Hi[i],Hi[j]),t ∈ T;i != j],
    sum(x[j,tt,h] for tt=t+1:maximum(T)) + x[i,t,h] <=1
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(Ic,Ip[p]), j ∈ Ip[p], t ∈ T; j != i],
    sum(x[j,tt,h] for h ∈ Hi[j] for tt=t+1:maximum(T)) + sum(x[i,t,h] for h ∈ Hi[i]) <= 1
    )

    #Fixação
    for i ∈ union(I0,Ic)
        for h ∈ Hi[i]
            for t ∈ T
                if  t< r[i] || t > r[i]+d || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    for i ∈ union(I1,I2)
        for h ∈ Hi[i]
            for t ∈ T
                if  t< r[i] || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    optimize!(modelo)

    CPUtime = MOI.get(modelo, MOI.SolveTime())

    X = value.(x)

    Z1 = value(z1)
    Z2 = value(z2)
    Z3 = value(z3)
    N_restricoes = sum(num_constraints(modelo, F, S) for (F, S) in list_of_constraint_types(modelo))
    N_var = num_variables(modelo)
    Gap = MOI.get(modelo, MOI.RelativeGap())


    return (X,CPUtime,Z1,Z2,Z3,N_restricoes,N_var,Gap)
end
#-------------------------------------------------------
#Sol. min z1
ε=0.001
@printf("------------------------------------\n")
@printf("Estamos no problema 1...............\n")
@printf("------------------------------------\n")
λ=[0.9999;0.00005;0.00005];
(X_exato,CPUtime,Z1_1,Z2_1,Z3_1,N_restricoes,N_var,Gap)  = Exato(λ,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_1 = X_exato
FileIO.save("X_exato_1_$g.jld2","RH",X_exato_1)
info_1 = [Z1_1 Z2_1 Z3_1 CPUtime Gap N_restricoes N_var]
#---------------------------------------------------
#Sol. min z2
@printf("------------------------------------\n")
@printf("Estamos no problema 2...............\n")
@printf("------------------------------------\n")
λ=[0.00005;0.9999;0.00005];
(X_exato,CPUtime,Z1_2,Z2_2,Z3_2,N_restricoes,N_var,Gap)  = Exato(λ,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_2 = X_exato
FileIO.save("X_exato_2_$g.jld2","RH",X_exato_2)
info_2 = [Z1_2 Z2_2 Z3_2 CPUtime Gap N_restricoes N_var]
#---------------------------------------------------
#Sol. min z3
@printf("------------------------------------\n")
@printf("Estamos no problema 3...............\n")
@printf("------------------------------------\n")
λ=[0.00005;0.00005;0.9999];
(X_exato,CPUtime,Z1_3,Z2_3,Z3_3,N_restricoes,N_var,Gap)  = Exato(λ,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_3 = X_exato
FileIO.save("X_exato_3_$g.jld2","RH",X_exato_3)
info_3 = [Z1_3 Z2_3 Z3_3 CPUtime Gap N_restricoes N_var]
#---------------------------------------------------
Z1_ideal = minimum([Z1_1 Z1_2 Z1_3])
Z2_ideal = minimum([Z2_1 Z2_2 Z2_3])
Z3_ideal = minimum([Z3_1 Z3_2 Z3_3])

Z1_nadir = maximum([Z1_1 Z1_2 Z1_3])
Z2_nadir = maximum([Z2_1 Z2_2 Z2_3])
Z3_nadir = maximum([Z3_1 Z3_2 Z3_3])

Z_ideal = [Z1_ideal;Z2_ideal;Z3_ideal]
Z_nadir = [Z1_nadir;Z2_nadir;Z3_nadir]
#-------------------------------------------------------
#Sol. com peso λ=[0.7 0.15 0.15]
λ=[0.7 0.15 0.15];
@printf("------------------------------------\n")
@printf("Estamos no problema 4...............\n")
@printf("------------------------------------\n")
(X_exato,CPUtime,Z1_4,Z2_4,Z3_4,N_restricoes,N_var,Gap)  = Exato_Tchebycheff(λ,ε,Z_ideal,Z_nadir,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_4 = X_exato
FileIO.save("X_exato_4_$g.jld2","RH",X_exato_4)
info_4 = [Z1_4 Z2_4 Z3_4 CPUtime Gap N_restricoes N_var]
#-------------------------------------------------------
#Sol. com peso λ=[0.15 0.7 0.15]
λ=[0.15 0.7 0.15];
@printf("------------------------------------\n")
@printf("Estamos no problema 5...............\n")
@printf("------------------------------------\n")
(X_exato,CPUtime,Z1_5,Z2_5,Z3_5,N_restricoes,N_var,Gap)  = Exato_Tchebycheff(λ,ε,Z_ideal,Z_nadir,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_5 = X_exato
FileIO.save("X_exato_5_$g.jld2","RH",X_exato_5)
info_5 = [Z1_5 Z2_5 Z3_5 CPUtime Gap N_restricoes N_var]
#-------------------------------------------------------
#Sol. com peso λ=[0.15 0.15 0.7]
λ=[0.15 0.15 0.7];
@printf("------------------------------------\n")
@printf("Estamos no problema 6...............\n")
@printf("------------------------------------\n")
(X_exato,CPUtime,Z1_6,Z2_6,Z3_6,N_restricoes,N_var,Gap)  = Exato_Tchebycheff(λ,ε,Z_ideal,Z_nadir,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_6 = X_exato
FileIO.save("X_exato_6_$g.jld2","RH",X_exato_6)
info_6 = [Z1_6 Z2_6 Z3_6 CPUtime Gap N_restricoes N_var]
#-------------------------------------------------------
#Sol. com peso λ=[1/3 1/3 1/3]
λ=[1/3 1/3 1/3];
@printf("------------------------------------\n")
@printf("Estamos no problema 7...............\n")
@printf("------------------------------------\n")
(X_exato,CPUtime,Z1_7,Z2_7,Z3_7,N_restricoes,N_var,Gap)  = Exato_Tchebycheff(λ,ε,Z_ideal,Z_nadir,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
X_exato_7 = X_exato
FileIO.save("X_exato_7_$g.jld2","RH",X_exato_7)
info_7 = [Z1_7 Z2_7 Z3_7 CPUtime Gap N_restricoes N_var]
#------------------------------------------------------
Pontos_n_dominados_exato =[
    Z1_1 Z2_1 Z3_1
    Z1_2 Z2_2 Z3_2
    Z1_3 Z2_3 Z3_3
    Z1_4 Z2_4 Z3_4
    Z1_5 Z2_5 Z3_5
    Z1_6 Z2_6 Z3_6
    Z1_7 Z2_7 Z3_7
]
FileIO.save("Pontos_n_dominados_exato_$g.jld2","RH",Pontos_n_dominados_exato)
info = [
    info_1
    info_2
    info_3
    info_4
    info_5
    info_6
    info_7
]
FileIO.save("informacoes_exato_$g.jld2","RH",info)

#=
function Teste_factibilidade(w,X,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F,α)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  600)
    set_optimizer_attribute(modelo, "MIPGap", 0.00)

    #Se designo o vôo i no período t pelo helicóptero h
    @variable(modelo, x[i ∈ I, t ∈ T, h ∈ Hi[i]], Bin)

    #Se o helicóptero h está sendo usado no instante t
    @variable(modelo, y[t ∈ T, h ∈ H], Bin)

    #Se alguma decolagem ocorre no instante t
    @variable(modelo, z[t ∈ T], Bin)

    #Se o helicóptero h é usado em algum vôo
    @variable(modelo, v[h ∈ H], Bin)

    #Se o vôo i não pode ser agendado para o dia
    @variable(modelo, k[i ∈ I], Bin)

    #Objetivos envolvidos
    @variable(modelo, z1>=0)
    @variable(modelo, z2>=0)
    @variable(modelo, z3>=0)

    for i in I, t in 1:Tmax, h in Hi[i]
        set_start_value(x[i,t,h], X[i,t,h])
    end

    @objective(modelo,Min,
        w[1]*z1 + w[2]*z2 + w[3]*z3
    )

    for i ∈ I, t ∈ T, h ∈ Hi[i]
        fix(x[i,t,h],X[i,t,h])
    end



    @constraint(
    modelo,z1 == 0.4*sum(k[i] for i ∈ Ic) + 0.3*sum(k[i] for i ∈ I2) + 0.2*sum(k[i] for i ∈ I1) + 0.1*sum(k[i] for i ∈ I0)
    )

    @constraint(
    modelo,z2 == 0.5*sum(v[h] for h ∈ Hs) + 0.3*sum(v[h] for h ∈ Hp) + 0.2*sum(v[h] for h ∈ Hn)
    )

    @constraint(
    modelo,z3 == sum(F*(t-r[i])*x[i,t,h] for i ∈ I for h ∈ Hi[i] for t ∈ T)
    )

    @constraint(
    modelo,
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ T) >= length(I0)
    )

    @constraint(
    modelo,[i ∈ I],
    sum(x[i,t,h] for t ∈ T for h ∈ Hi[i]) <= 1
    )

    @constraint(
    modelo,[i ∈ I],
    sum(x[i,t,h] for h ∈ Hi[i] for t ∈ T) + k[i] == 1
    )

    @constraint(
    modelo,[t ∈ T],
    sum(x[i,t,h] for i ∈ I for h ∈ Hi[i]) == z[t]
    )

    @constraint(
    modelo,res[h ∈ H, t ∈ T],
    y[t,h] == sum(x[i,tt,h] for i ∈ Ih[h] for tt ∈ t:-1:maximum([r[i],t-tf[i]-tat+1]))
    )

    @constraint(
    modelo,[h ∈ H],
    sum(y[t,h] for t ∈ T) <= maximum(T)*v[h]
    )

    @constraint(
    modelo,[i ∈ union(I0,Ic)],
    sum((t-r[i])*x[i,t,h] for h ∈ Hi[i] for t ∈ T) <= d
    )

    @constraint(
    modelo,[p ∈ P, i ∈ Ip[p], j ∈ Ip[p], t ∈ T, tt ∈ T; tt>t && i != j],
    tt*sum(x[j,tt,h] for h ∈ Hi[j]) >= t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) - maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(union(I1,I2),Ip[p]), j ∈ intersect(I0,Ip[p]), t ∈ T],
    sum(x[j,tt,h] for h ∈ Hi[j] for tt=1:t-1) + sum(x[i,t,h] for h ∈ Hi[i]) <=1
    )

    @constraint(
    modelo,[i ∈ Ic,j ∈ I, h ∈ intersect(Hi[i],Hi[j]),t ∈ T;i != j],
    sum(x[j,tt,h] for tt=t+1:maximum(T)) + x[i,t,h] <=1
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(Ic,Ip[p]), j ∈ Ip[p], t ∈ T; j != i],
    sum(x[j,tt,h] for h ∈ Hi[j] for tt=t+1:maximum(T)) + sum(x[i,t,h] for h ∈ Hi[i]) <= 1
    )

    #Fixação
    for i ∈ union(I0,Ic)
        for h ∈ Hi[i]
            for t ∈ T
                if  t< r[i] || t > r[i]+d || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    for i ∈ union(I1,I2)
        for h ∈ Hi[i]
            for t ∈ T
                if  t< r[i] || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    optimize!(modelo)
    CPUtime = MOI.get(modelo, MOI.SolveTime())

    X = value.(x)
    for i ∈ I, t ∈ T, h ∈ Hi[i]
        X[i,t,h] =round(Int, X[i,t,h])
    end
    X = Int.(X)

    Z1 = value(z1)
    Z2 = value(z2)
    Z3 = value(z3)
    N_restricoes = sum(num_constraints(modelo, F, S) for (F, S) in list_of_constraint_types(modelo))
    N_var = num_variables(modelo)

    return (X,CPUtime,Z1,Z2,Z3,N_restricoes,N_var)
end

(X,CPUtime,Z1,Z2,Z3) = Teste_factibilidade(w,X_k,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F,α)


(X,CPUtime,Z1,Z2,Z3,N_restricoes,N_var,Gap) = Exato(λ,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);

λ = [1/3 1/3 1/3]
Z_ideal =[ 0.0  0.8  40.0]
Z_nadir =[4.6  2.2  6250.0]

(X,CPUtime,Z1,Z2,Z3,N_restricoes,N_var,Gap) = Exato_Tchebycheff(λ,ε,Z_ideal,Z_nadir,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);


Num_voos=0
for t in 1:Tmax,i in I, h in Hi[i]
    if X_k5[i,t,h] > 0.5
        Num_voos=Num_voos+1
        @printf("Alocamos o vôo i=%1d no tempo t=%1d com o helicop. h=%1d com atraso %1d\n",i,t,h,t-r[i])
    end
end
Num_voos

=#
