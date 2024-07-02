using JuMP, Printf, LinearAlgebra, Random, Gurobi, JLD2, FileIO, Plots, Printf
|
include("dados_60.jl")
g=45
#-------------------------------------------------------
function Construtiva(λ,Lista_voos,X_k_velho,Y_k_velho,I_k_velho,H_k_velho,T_k_velho,I_k,T_k,H_k,Voo_tarde_k,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.0)
    set_optimizer_attribute(modelo, "OutputFlag", 0)

    #Se designo o vôo i no período t pelo helicóptero h
    @variable(modelo, x[i ∈ I_k, t ∈ T_k, h ∈ intersect(Hi[i],H_k)], Bin)

    #Se o helicóptero h está sendo usado no instante t
    @variable(modelo, y[t ∈ T_k, h ∈ H_k], Bin)

    #Se alguma decolagem ocorre no instante t
    @variable(modelo, z[t ∈ T_k], Bin)

    #Se o helicóptero h é usado em algum vôo
    @variable(modelo, v[h ∈ H_k], Bin)

    #Se o vôo i não pode ser agendado para o dia
    @variable(modelo, k[i ∈ I_k], Bin)

    #Objetivos envolvidos
    @variable(modelo, z1>=0)
    @variable(modelo, z2>=0)
    @variable(modelo, z3>=0)


    @objective(modelo,Min,
    λ[1]*z1 + λ[2]*z2 + λ[3]*z3
    )

    if length(X_k_velho) > 0
        for i in I_k_velho, t in setdiff(T_k_velho,Voo_tarde_k), h in intersect(Hi[i],H_k_velho)
            fix(x[i,t,h], X_k_velho[i,t,h])
        end
    end
    if length(Y_k_velho) > 0
        for t in setdiff(T_k_velho,Voo_tarde_k), h in H_k_velho
            fix(y[t,h], Y_k_velho[t,h])
        end
    end

    @constraint(
    modelo,z1 == 0.4*sum(k[i] for i ∈ intersect(Ic,I_k)) + 0.3*sum(k[i] for i ∈ intersect(I2,I_k)) + 0.2*sum(k[i] for i ∈ intersect(I1,I_k)) + 0.1*sum(k[i] for i ∈ intersect(I0,I_k))
    )

    @constraint(
    modelo,z2 == 0.5*sum(v[h] for h ∈ intersect(Hs,H_k)) + 0.3*sum(v[h] for h ∈ intersect(Hp,H_k)) + 0.2*sum(v[h] for h ∈ intersect(Hn,H_k))
    )

    @constraint(
    modelo,z3 == sum(F*(t-r[i])*x[i,t,h] for i ∈ I_k for h ∈ intersect(Hi[i],H_k) for t ∈ T_k)
    )

    @constraint(
    modelo,[i ∈ I_k],
    sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) + k[i] == 1
    )

    if λ[2] >= 0.7
        @constraint(
        modelo,
        sum(x[i,t,h] for i in I_k for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) >= 
        minimum([length(Lista_voos) + 0.5*length(H_k),0.5*length(setdiff(I_k,Lista_voos)),length(I0)-length(Lista_voos)])
        )
    else
        @constraint(
        modelo,
        sum(x[i,t,h] for i in I_k for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) >= 
        minimum([length(Lista_voos) + length(H_k),0.8*length(setdiff(I_k,Lista_voos)),length(I0)-length(Lista_voos)])
        )
    end


    @constraint(
    modelo,[i ∈ I_k],
    sum(x[i,t,h] for t ∈ T_k for h ∈ intersect(Hi[i],H_k)) <= 1
    )

    @constraint(
    modelo,[t ∈ T_k],
    sum(x[i,t,h] for i ∈ I_k for h ∈ intersect(Hi[i],H_k)) == z[t]
    )

    @constraint(
    modelo,res[h ∈ H_k, t ∈ T_k],
    y[t,h] == sum(x[i,tt,h] for i ∈ intersect(Ih[h],I_k) for tt ∈ t:-1:maximum([r[i],t-tf[i]-tat+1]))
    )

    @constraint(
    modelo,[h ∈ H_k],
    sum(y[t,h] for t ∈ T_k) <= maximum(T_k)*v[h]
    )

    @constraint(
    modelo,[i ∈ intersect(union(I0,Ic),I_k)],
    sum((t-r[i])*x[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) <= d
    )

    for p in P
        for i in intersect(Ip[p],I_k)
            for j in intersect(Ip[p],I_k)
                for t in union(setdiff(T_k,T_k_velho),Voo_tarde_k)
                    for tt in T_k
                        if isempty(Voo_tarde_k)
                            if tt > t && i != j
                                @constraint(modelo,
                                tt*sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)) >=
                                t*sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                                maximum(T_k)*(2 - sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) - sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)))
                                )
                            end
                        else
                            if tt > maximum(Voo_tarde_k) && i != j
                                @constraint(modelo,
                                tt*sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)) >=
                                t*sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                                maximum(T_k)*(2 - sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) - sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)))
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(intersect(union(I1,I2),Ip[p]),I_k), j ∈ intersect(intersect(I0,Ip[p]),I_k), t ∈ T_k],
    sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k) for tt=1:t-1) + sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) <=1
    )

    @constraint(
    modelo,[i ∈ intersect(Ic,I_k),j ∈ I_k, h ∈ intersect(Hi[i],Hi[j]),t ∈ T_k;i != j],
    sum(x[j,tt,h] for tt=t+1:maximum(T_k)) + x[i,t,h] <=1
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(intersect(Ic,Ip[p]),I_k), j ∈ intersect(Ip[p],I_k), t ∈ T_k; j != i],
    sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k) for tt=t+1:maximum(T_k)) + sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) <= 1
    )

    #Fixação
    for i ∈ intersect(union(I0,Ic),I_k)
        for h ∈ intersect(Hi[i],H_k)
            for t ∈ T_k
                if  t< r[i] || t > r[i]+d || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    for i ∈ intersect(union(I1,I2),I_k)
        for h ∈ intersect(Hi[i],H_k)
            for t ∈ T_k
                if  t< r[i] || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end


    optimize!(modelo)
    CPUtime = MOI.get(modelo, MOI.SolveTime())

    X = value.(x)
    for i ∈ I_k, t ∈ T_k, h ∈ intersect(Hi[i],H_k)
        X[i,t,h] = round(Int, X[i,t,h])
    end
    X = Int.(X)

    Y = value.(y)
    for t ∈ T_k, h ∈ H_k
        Y[t,h] = round(Int, Y[t,h])
    end 
    Y = Int.(Y)
    Lista_voos = [sum(i*X[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) for i in I_k]
    Lista_voos = Lista_voos[findall(Lista_voos .>0)]

    Z1 = value(z1)
    Z2 = value(z2)
    Z3 = value(z3)


    return (X,Y,CPUtime,Z1,Z2,Z3,Lista_voos)
end

function Heuristica_melhorativa_1(λ,X_k,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.00)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    set_optimizer_attribute(modelo, "MIPFocus", 2)


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
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,
    λ[1]*z1 + λ[2]*z2 + λ[3]*z3
    )

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
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
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ setdiff(1:Tmax,T_livre)) <= size(ind_fixo,1)
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

    for p in P
        for i in setdiff(Ip[p],Lista_voos)
            for j in setdiff(Ip[p],Lista_voos)
                for t in union(T_livre,Voo_tarde)
                    for tt in union(T_livre,Voo_cedo)
                        if tt > t && i != j
                            @constraint(modelo,
                            tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                            t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                            maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                            )
                        end
                    end
                end
            end
        end
    end

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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Heuristica_melhorativa_2(λ,X_k,ind_fixo,Num_max,Unidades_usadas,Tmax,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.00)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    set_optimizer_attribute(modelo, "MIPFocus", 2)


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
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,
    λ[1]*z1 + λ[2]*z2 + λ[3]*z3
    )

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
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
    modelo,[p in Unidades_usadas],
    sum(x[i,t,h] for i in Ip[p] for h ∈ Hi[i] for t ∈ T) <= Num_max[p]
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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Heuristica_melhorativa_3(λ,X_k,Lista_voos,ind_fixo,Tmax,T_fixo,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.00)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    set_optimizer_attribute(modelo, "MIPFocus", 2)


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
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,
    λ[1]*z1 + λ[2]*z2 + λ[3]*z3
    )

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
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
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ T_fixo) <= size(ind_fixo,1)
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

    for p in P
        for i in setdiff(Ip[p],Lista_voos)
            for j in setdiff(Ip[p],Lista_voos)
                for t in 1:Voo_tarde
                    for tt in 1:Voo_tarde
                        if tt > t && i != j
                            @constraint(modelo,
                            tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                            t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                            maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                            )
                        end
                    end
                end
                if ~isempty(Voo_cedo)
                    for t in Voo_cedo:Tmax
                        for tt in Voo_cedo:Tmax
                            if tt > t && i != j
                                @constraint(modelo,
                                tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                                t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                                maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                                )
                            end
                        end
                    end
                end
            end
        end
    end


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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Heuristica_melhorativa_4(λ,X_k,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.00)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    set_optimizer_attribute(modelo, "MIPFocus", 2)


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
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,
    λ[1]*z1 + λ[2]*z2 + λ[3]*z3
    )

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
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
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ setdiff(1:Tmax,T_livre)) <= size(ind_fixo,1)
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

    for p in P
        for i in setdiff(Ip[p],Lista_voos)
            for j in setdiff(Ip[p],Lista_voos)
                for t in union(T_livre,Voo_tarde)
                    for tt in union(T_livre,Voo_cedo)
                        if tt > t && i != j
                            @constraint(modelo,
                            tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                            t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                            maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                            )
                        end
                    end
                end
            end
        end
    end

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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Integracao_heuristicas(λ,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    #--------------------------------------------------------
    #Fase Construtiva
    @printf("******************************************\n")
    @printf("**********Estamos na Construtiva**********\n")
    @printf("******************************************\n")
    CPUtime_construtiva=0
    iter = 0
    for Tmax in Particao1
        I_k = findall(r .<= Tmax)
        T_k=1:Tmax
        H_k = []
        for i in I_k
            H_k = union(H_k,Hi[i])
        end
        H_k = sort(H_k)
        if iter == 0 
            X_k_velho=[]
            Y_k_velho=[]
            I_k_velho=I_k
            H_k_velho=H_k
            T_k_velho=[]
            Voo_tarde_k=[]
            Lista_voos=[]
        end 
        global (X_k,Y_k,CPUtime,Z1_0,Z2_0,Z3_0,Lista_voos) = Construtiva(λ,Lista_voos,X_k_velho,Y_k_velho,I_k_velho,H_k_velho,T_k_velho,I_k,T_k,H_k,Voo_tarde_k,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
        global X_k_velho=X_k
        global Y_k_velho=Y_k
        global I_k_velho=I_k
        global H_k_velho=H_k
        global T_k_velho=T_k
        global Voo_tarde_k = maximum([ sum(t*X_k_velho[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k ) for i in I_k])
        CPUtime_construtiva = CPUtime_construtiva + CPUtime
        iter = iter +1
    end 
    #-------------------------------------------------------
    #Heuristica 1
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 1**********\n")
    @printf("******************************************\n")
    Tmax = maximum([maximum(T) - tf[i] for i in I])
    CPUtime_melhorativa_1=0
    i=0
    for j in 2:length(Particao2)
        i=i+1
        T_livre = Particao2[i]:Particao2[i+1]
        if i==1
            Voo_tarde = [] 
        else
            Voo_tarde = maximum([sum(t*round(X_k[i,t,h]) for h ∈ Hi[i] for t ∈ 1:Tmax if t < minimum(T_livre)) for i in I])
        end
        if i<length(Particao2)-1
            aux = [sum(t*X_k[i,t,h] for h ∈ Hi[i] for t in 1:Tmax if t > maximum(T_livre)) for i in I]
            if sum(aux) > 0 
                Voo_cedo = minimum(aux[findall(aux .>0)])
            else
                Voo_cedo = [] 
            end 
        else  
            Voo_cedo = []
        end 
        ind_fixo=zeros(0,3);
        for t in setdiff(1:Tmax,T_livre), i in I, h in Hi[i]
            if X_k[i,t,h] > 0.5
                ind_fixo = [ind_fixo;[i t h]]
            end
        end
        ind_fixo = Int.(ind_fixo)
        Lista_voos = [sum(i*X_k[i,t,h] for h ∈ Hi[i] for t ∈ setdiff(1:Tmax,T_livre)) for i in I]
        Lista_voos = Lista_voos[findall(Lista_voos .>0)]
        global (X_k,CPUtime,Z1_1,Z2_1,Z3_1) = Heuristica_melhorativa_1(λ,X_k,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
        CPUtime_melhorativa_1 = CPUtime_melhorativa_1 + CPUtime
    end 
    X_k1 = X_k
    #-------------------------------------------------------
    #Heuristica 2
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 2**********\n")
    @printf("******************************************\n")
    Isolto=[]
    for p in P 
        if length(Ip[p]) ==1
            Isolto = [Isolto;Ip[p]]
        end 
    end 
    ind_fixo=zeros(0,3);
    for t in T,i in setdiff(I,Isolto), h in Hi[i]
        if X_k1[i,t,h] > 0.5
            ind_fixo = [ind_fixo;[i t h]]
        end
    end
    ind_fixo = Int.(ind_fixo)

    Num_max=zeros(maximum(P))
    for p in P,i in 1:size(ind_fixo,1)
        if ind_fixo[i,1] ∈ Ip[p]
            Num_max[p] = Num_max[p] + 1
        end 
    end 
    Unidades_usadas = findall(Num_max .> 0)

    global (X_k2,CPUtime_melhorativa_2,Z1_2,Z2_2,Z3_2) = Heuristica_melhorativa_2(λ,X_k1,ind_fixo,Num_max,Unidades_usadas,Tmax,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
    X_k3 = X_k2 
    #-------------------------------------------------------
    #Heuristica 3
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 3**********\n")
    @printf("******************************************\n")
    Maior_janela = zeros(length(I),length(I));
    for i in I 
        for j in I 
            if i != j 
                Maior_janela[i,j] = 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) 
            end 
        end 
    end 
    Ma = Int(ceil(findmax(Maior_janela)[1]))
    Ma = maximum([Ma,30])

    T_cedo = 40
    T_tarde = T_cedo+Ma 
    T_fixo = T_cedo:T_tarde 
    T_livre = setdiff(T,T_fixo)
    Voo_tarde = maximum([sum(t*X_k3[i,t,h] for h ∈ Hi[i] for t ∈ 1:T_cedo-1) for i in I])
    aux = [sum(t*X_k3[i,t,h] for h ∈ Hi[i] for t ∈ T_tarde+1:Tmax) for i in I]
    if sum(aux) > 0
       Voo_cedo = minimum(aux[findall(aux .>0)])
    else 
        Voo_cedo=[]
    end 
    ind_fixo=zeros(0,3);
    for t in T_fixo, i in I, h in Hi[i]
        if X_k3[i,t,h] > 0.5
            ind_fixo = [ind_fixo;[i t h]]
        end
    end
    ind_fixo = Int.(ind_fixo)
    Lista_voos = [sum(i*X_k3[i,t,h] for h ∈ Hi[i] for t ∈ T_fixo) for i in I]
    Lista_voos = Lista_voos[findall(Lista_voos .>0)]

    global (X_k4,CPUtime_melhorativa_3,Z1_3,Z2_3,Z3_3) = Heuristica_melhorativa_3(λ,X_k3,Lista_voos,ind_fixo,Tmax,T_fixo,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    X_k5 = X_k4
    #-------------------------------------------------------
    #Heuristica 4
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 4**********\n")
    @printf("******************************************\n")
    T_livre = T_fixo 
    Voo_tarde = maximum([sum(t*X_k5[i,t,h] for h ∈ Hi[i] for t ∈ 1:minimum(T_livre)-1) for i in I])
    aux = [sum(t*X_k5[i,t,h] for h ∈ Hi[i] for t ∈ maximum(T_livre)+1:Tmax) for i in I]
    if sum(aux) > 0
        Voo_cedo = minimum(aux[findall(aux .>0)])
     else 
         Voo_cedo=[]
     end 

    ind_fixo=zeros(0,3);
    for t in setdiff(T,T_livre), i in I, h in Hi[i]
        if X_k5[i,t,h] > 0.5
            ind_fixo = [ind_fixo;[i t h]]
        end
    end
    ind_fixo = Int.(ind_fixo)
    Lista_voos = [sum(i*X_k5[i,t,h] for h ∈ Hi[i] for t ∈ setdiff(T,T_livre)) for i in I]
    Lista_voos = Lista_voos[findall(Lista_voos .>0)]

    global (X_heuristico,CPUtime_melhorativa_4,Z1_4,Z2_4,Z3_4) = Heuristica_melhorativa_4(λ,X_k5,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)

    info = [Z1_0 Z2_0 Z3_0 CPUtime_construtiva;
            Z1_1 Z2_1 Z3_1 CPUtime_melhorativa_1;
            Z1_2 Z2_2 Z3_2 CPUtime_melhorativa_2;
            Z1_3 Z2_3 Z3_3 CPUtime_melhorativa_3;
            Z1_4 Z2_4 Z3_4 CPUtime_melhorativa_4
            ]

    return (X_heuristico,info) 
end

function Tchebycheff_Construtiva(λ,ε,Z_ideal,Z_nadir,iter,Lista_voos,X_k_velho,Y_k_velho,I_k_velho,H_k_velho,T_k_velho,I_k,T_k,H_k,Voo_tarde_k,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.01)
    set_optimizer_attribute(modelo, "OutputFlag", 0)

    #Se designo o vôo i no período t pelo helicóptero h
    @variable(modelo, x[i ∈ I_k, t ∈ T_k, h ∈ intersect(Hi[i],H_k)], Bin)

    #Se o helicóptero h está sendo usado no instante t
    @variable(modelo, y[t ∈ T_k, h ∈ H_k], Bin)

    #Se alguma decolagem ocorre no instante t
    @variable(modelo, z[t ∈ T_k], Bin)

    #Se o helicóptero h é usado em algum vôo
    @variable(modelo, v[h ∈ H_k], Bin)

    #Se o vôo i não pode ser agendado para o dia
    @variable(modelo, k[i ∈ I_k], Bin)

    #Objetivos envolvidos
    @variable(modelo, z1>=0)
    @variable(modelo, z2>=0)
    @variable(modelo, z3>=0)

    #Var auxiliar
    @variable(modelo, u >=0)


    @objective(modelo,Min,u)

    if length(X_k_velho) > 0
        for i in I_k_velho, t in setdiff(T_k_velho,Voo_tarde_k), h in intersect(Hi[i],H_k_velho)
            fix(x[i,t,h], X_k_velho[i,t,h])
        end
    end
    if length(Y_k_velho) > 0
        for t in setdiff(T_k_velho,Voo_tarde_k), h in H_k_velho
            fix(y[t,h], Y_k_velho[t,h])
        end
    end

    @constraint(modelo,
    λ[1]*(z1 - Z_ideal[iter,1])/(Z_nadir[iter,1] - Z_ideal[iter,1]) <= u
    )

    @constraint(modelo,
    λ[2]*(z2 - Z_ideal[iter,2])/(Z_nadir[iter,2] - Z_ideal[iter,2]) <= u
    )

    @constraint(modelo,
    λ[3]*(z3 - Z_ideal[iter,3])/(Z_nadir[iter,3] - Z_ideal[iter,3]) <= u
    )

    @constraint(
    modelo,z1 == 0.4*sum(k[i] for i ∈ intersect(Ic,I_k)) + 0.3*sum(k[i] for i ∈ intersect(I2,I_k)) + 0.2*sum(k[i] for i ∈ intersect(I1,I_k)) + 0.1*sum(k[i] for i ∈ intersect(I0,I_k))
    )

    @constraint(
    modelo,z2 == 0.5*sum(v[h] for h ∈ intersect(Hs,H_k)) + 0.3*sum(v[h] for h ∈ intersect(Hp,H_k)) + 0.2*sum(v[h] for h ∈ intersect(Hn,H_k))
    )

    @constraint(
    modelo,z3 == sum(F*(t-r[i])*x[i,t,h] for i ∈ I_k for h ∈ intersect(Hi[i],H_k) for t ∈ T_k)
    )

    @constraint(
    modelo,[i ∈ I_k],
    sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) + k[i] == 1
    )

    if λ[2] >= 0.7
        @constraint(
        modelo,
        sum(x[i,t,h] for i in I_k for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) >= 
        minimum([length(Lista_voos) + 0.5*length(H_k),0.5*length(setdiff(I_k,Lista_voos)),length(I0)-length(Lista_voos)])
        )
    else
        @constraint(
        modelo,
        sum(x[i,t,h] for i in I_k for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) >= 
        minimum([length(Lista_voos) + length(H_k),0.8*length(setdiff(I_k,Lista_voos)),length(I0)-length(Lista_voos)])
        )
    end

    @constraint(
    modelo,[i ∈ I_k],
    sum(x[i,t,h] for t ∈ T_k for h ∈ intersect(Hi[i],H_k)) <= 1
    )

    @constraint(
    modelo,[t ∈ T_k],
    sum(x[i,t,h] for i ∈ I_k for h ∈ intersect(Hi[i],H_k)) == z[t]
    )

    @constraint(
    modelo,res[h ∈ H_k, t ∈ T_k],
    y[t,h] == sum(x[i,tt,h] for i ∈ intersect(Ih[h],I_k) for tt ∈ t:-1:maximum([r[i],t-tf[i]-tat+1]))
    )

    @constraint(
    modelo,[h ∈ H_k],
    sum(y[t,h] for t ∈ T_k) <= maximum(T_k)*v[h]
    )

    @constraint(
    modelo,[i ∈ intersect(union(I0,Ic),I_k)],
    sum((t-r[i])*x[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) <= d
    )

    for p in P
        for i in intersect(Ip[p],I_k)
            for j in intersect(Ip[p],I_k)
                for t in union(setdiff(T_k,T_k_velho),Voo_tarde_k)
                    for tt in T_k
                        if isempty(Voo_tarde_k)
                            if tt > t && i != j
                                @constraint(modelo,
                                tt*sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)) >=
                                t*sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                                maximum(T_k)*(2 - sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) - sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)))
                                )
                            end
                        else
                            if tt > maximum(Voo_tarde_k) && i != j
                                @constraint(modelo,
                                tt*sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)) >=
                                t*sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                                maximum(T_k)*(2 - sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) - sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k)))
                                )
                            end
                        end
                    end
                end
            end
        end
    end

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(intersect(union(I1,I2),Ip[p]),I_k), j ∈ intersect(intersect(I0,Ip[p]),I_k), t ∈ T_k],
    sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k) for tt=1:t-1) + sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) <=1
    )

    @constraint(
    modelo,[i ∈ intersect(Ic,I_k),j ∈ I_k, h ∈ intersect(Hi[i],Hi[j]),t ∈ T_k;i != j],
    sum(x[j,tt,h] for tt=t+1:maximum(T_k)) + x[i,t,h] <=1
    )

    @constraint(
    modelo,[p ∈ P, i ∈ intersect(intersect(Ic,Ip[p]),I_k), j ∈ intersect(Ip[p],I_k), t ∈ T_k; j != i],
    sum(x[j,tt,h] for h ∈ intersect(Hi[j],H_k) for tt=t+1:maximum(T_k)) + sum(x[i,t,h] for h ∈ intersect(Hi[i],H_k)) <= 1
    )

    #Fixação
    for i ∈ intersect(union(I0,Ic),I_k)
        for h ∈ intersect(Hi[i],H_k)
            for t ∈ T_k
                if  t< r[i] || t > r[i]+d || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end

    for i ∈ intersect(union(I1,I2),I_k)
        for h ∈ intersect(Hi[i],H_k)
            for t ∈ T_k
                if  t< r[i] || t > maximum(T) - tf[i]+1
                    fix(x[i,t,h],0)
                end
            end
        end
    end


    optimize!(modelo)
    CPUtime = MOI.get(modelo, MOI.SolveTime())

    X = value.(x)
    for i ∈ I_k, t ∈ T_k, h ∈ intersect(Hi[i],H_k)
        X[i,t,h] = round(Int, X[i,t,h])
    end
    X = Int.(X)

    Y = value.(y)
    for t ∈ T_k, h ∈ H_k
        Y[t,h] = round(Int, Y[t,h])
    end 
    Y = Int.(Y)
    Lista_voos = [sum(i*X[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k) for i in I_k]
    Lista_voos = Lista_voos[findall(Lista_voos .>0)]

    Z1 = value(z1)
    Z2 = value(z2)
    Z3 = value(z3)


    return (X,Y,CPUtime,Z1,Z2,Z3,Lista_voos)
end

function Tchebycheff_Heuristica_melhorativa_1(λ,ε,Z_ideal,Z_nadir,X_k,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.000)
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

    #Var auxiliar
    @variable(modelo, u>=0)

    for i in I, t in 1:Tmax, h in Hi[i]
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,u)

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
    end

    @constraint(modelo,
    λ[1]*(z1 - Z_ideal[end,1])/(Z_nadir[end,1] - Z_ideal[end,1]) <= u
    )

    @constraint(modelo,
    λ[2]*(z2 - Z_ideal[end,2])/(Z_nadir[end,2] - Z_ideal[end,2]) <= u
    )

    @constraint(modelo,
    λ[3]*(z3 - Z_ideal[end,3])/(Z_nadir[end,3] - Z_ideal[end,3]) <= u
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
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ setdiff(1:Tmax,T_livre)) <= size(ind_fixo,1)
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

    for p in P
        for i in setdiff(Ip[p],Lista_voos)
            for j in setdiff(Ip[p],Lista_voos)
                for t in union(T_livre,Voo_tarde)
                    for tt in union(T_livre,Voo_cedo)
                        if tt > t && i != j
                            @constraint(modelo,
                            tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                            t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                            maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                            )
                        end
                    end
                end
            end
        end
    end

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

function Tchebycheff_Heuristica_melhorativa_2(λ,ε,Z_ideal,Z_nadir,X_k,ind_fixo,Num_max,Unidades_usadas,Tmax,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.005)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    #set_optimizer_attribute(modelo, "MIPFocus", 2)


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

    #Var auxiliar
    @variable(modelo, u>=0)

    for i in I, t in 1:Tmax, h in Hi[i]
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,u)

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
    end

    @constraint(modelo,
    λ[1]*(z1 - Z_ideal[end,1])/(Z_nadir[end,1] - Z_ideal[end,1]) <= u
    )

    @constraint(modelo,
    λ[2]*(z2 - Z_ideal[end,2])/(Z_nadir[end,2] - Z_ideal[end,2]) <= u
    )

    @constraint(modelo,
    λ[3]*(z3 - Z_ideal[end,3])/(Z_nadir[end,3] - Z_ideal[end,3]) <= u
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
    modelo,[p in Unidades_usadas],
    sum(x[i,t,h] for i in Ip[p] for h ∈ Hi[i] for t ∈ T) <= Num_max[p]
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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Tchebycheff_Heuristica_melhorativa_3(λ,ε,Z_ideal,Z_nadir,X_k,Lista_voos,ind_fixo,Tmax,T_fixo,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit",  300)
    set_optimizer_attribute(modelo, "MIPGap", 0.005)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    #set_optimizer_attribute(modelo, "MIPFocus", 2)


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

    #Var auxiliar
    @variable(modelo, u>=0)

    for i in I, t in 1:Tmax, h in Hi[i]
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,u)

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
    end

    @constraint(modelo,
    λ[1]*(z1 - Z_ideal[end,1])/(Z_nadir[end,1] - Z_ideal[end,1]) <= u
    )

    @constraint(modelo,
    λ[2]*(z2 - Z_ideal[end,2])/(Z_nadir[end,2] - Z_ideal[end,2]) <= u
    )

    @constraint(modelo,
    λ[3]*(z3 - Z_ideal[end,3])/(Z_nadir[end,3] - Z_ideal[end,3]) <= u
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
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ T_fixo) <= size(ind_fixo,1)
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

    for p in P
        for i in setdiff(Ip[p],Lista_voos)
            for j in setdiff(Ip[p],Lista_voos)
                for t in 1:Voo_tarde
                    for tt in 1:Voo_tarde
                        if tt > t && i != j
                            @constraint(modelo,
                            tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                            t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                            maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                            )
                        end
                    end
                end
                if ~isempty(Voo_cedo)
                    for t in Voo_cedo:Tmax
                        for tt in Voo_cedo:Tmax
                            if tt > t && i != j
                                @constraint(modelo,
                                tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                                t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                                maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                                )
                            end
                        end
                    end
                end
            end
        end
    end


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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Tchebycheff_Heuristica_melhorativa_4(λ,ε,Z_ideal,Z_nadir,X_k,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    modelo = Model(Gurobi.Optimizer)
    set_optimizer_attribute(modelo, "TimeLimit", 300)
    set_optimizer_attribute(modelo, "MIPGap", 0.005)
    set_optimizer_attribute(modelo, "OutputFlag", 0)
    #set_optimizer_attribute(modelo, "MIPFocus", 2)

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

    #Var auxiliar
    @variable(modelo, u>=0)

    for i in I, t in 1:Tmax, h in Hi[i]
        set_start_value(x[i,t,h], X_k[i,t,h])
    end

    @objective(modelo,Min,u)

    for ℓ in 1:size(ind_fixo,1)
        fix(x[ind_fixo[ℓ,1],ind_fixo[ℓ,2],ind_fixo[ℓ,3]],1)
    end

    @constraint(modelo,
    λ[1]*(z1 - Z_ideal[end,1])/(Z_nadir[end,1] - Z_ideal[end,1]) <= u
    )

    @constraint(modelo,
    λ[2]*(z2 - Z_ideal[end,2])/(Z_nadir[end,2] - Z_ideal[end,2]) <= u
    )

    @constraint(modelo,
    λ[3]*(z3 - Z_ideal[end,3])/(Z_nadir[end,3] - Z_ideal[end,3]) <= u
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
    sum(x[i,t,h] for i in I for h ∈ Hi[i] for t ∈ setdiff(1:Tmax,T_livre)) <= size(ind_fixo,1)
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

    for p in P
        for i in setdiff(Ip[p],Lista_voos)
            for j in setdiff(Ip[p],Lista_voos)
                for t in union(T_livre,Voo_tarde)
                    for tt in union(T_livre,Voo_cedo)
                        if tt > t && i != j
                            @constraint(modelo,
                            tt*sum(x[j,tt,h] for h ∈ Hi[j]) >=
                            t*sum(x[i,t,h] for h ∈ Hi[i]) + 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) -
                            maximum(T)*(2 - sum(x[i,t,h] for h ∈ Hi[i]) - sum(x[j,tt,h] for h ∈ Hi[j]))
                            )
                        end
                    end
                end
            end
        end
    end

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

    return (X,CPUtime,Z1,Z2,Z3)
end

function Tchebycheff_Integracao_heuristicas(λ,ε,Z_ideal,Z_nadir,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    #--------------------------------------------------------
    #Fase Construtiva
    @printf("******************************************\n")
    @printf("**********Estamos na Construtiva**********\n")
    @printf("******************************************\n")
    CPUtime_construtiva=0
    iter = 0
    for Tmax in Particao1
        iter = iter +1
        I_k = findall(r .<= Tmax)
        T_k=1:Tmax
        H_k = []
        for i in I_k
            H_k = union(H_k,Hi[i])
        end
        H_k = sort(H_k)
        if iter == 1 
            X_k_velho=[]
            Y_k_velho=[]
            I_k_velho=I_k
            H_k_velho=H_k
            T_k_velho=[]
            Voo_tarde_k=[]
            Lista_voos=[]
        end 
        global (X_k,Y_k,CPUtime,Z1_0,Z2_0,Z3_0,Lista_voos) = Tchebycheff_Construtiva(λ,ε,Z_ideal,Z_nadir,iter,Lista_voos,X_k_velho,Y_k_velho,I_k_velho,H_k_velho,T_k_velho,I_k,T_k,H_k,Voo_tarde_k,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
        global X_k_velho=X_k
        global Y_k_velho=Y_k
        global I_k_velho=I_k
        global H_k_velho=H_k
        global T_k_velho=T_k
        global Voo_tarde_k = maximum([ sum(t*X_k_velho[i,t,h] for h ∈ intersect(Hi[i],H_k) for t ∈ T_k ) for i in I_k])
        CPUtime_construtiva = CPUtime_construtiva + CPUtime
    end 
    #-------------------------------------------------------
    #Heuristica 1
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 1**********\n")
    @printf("******************************************\n")
    Tmax = maximum([maximum(T) - tf[i] for i in I])
    CPUtime_melhorativa_1=0
    i=0
    for j in 2:length(Particao2)
        i=i+1
        T_livre = Particao2[i]:Particao2[i+1]
        if i==1
            Voo_tarde = [] 
        else
            Voo_tarde = maximum([sum(t*round(X_k[i,t,h]) for h ∈ Hi[i] for t ∈ 1:Tmax if t < minimum(T_livre)) for i in I])
        end
        if i<length(Particao2)-1
            aux = [sum(t*X_k[i,t,h] for h ∈ Hi[i] for t in 1:Tmax if t > maximum(T_livre)) for i in I]
            if sum(aux) > 0 
                Voo_cedo = minimum(aux[findall(aux .>0)])
            else
                Voo_cedo = [] 
            end 
        else  
            Voo_cedo = []
        end 
        ind_fixo=zeros(0,3);
        for t in setdiff(1:Tmax,T_livre), i in I, h in Hi[i]
            if X_k[i,t,h] > 0.5
                ind_fixo = [ind_fixo;[i t h]]
            end
        end
        ind_fixo = Int.(ind_fixo)
        Lista_voos = [sum(i*X_k[i,t,h] for h ∈ Hi[i] for t ∈ setdiff(1:Tmax,T_livre)) for i in I]
        Lista_voos = Lista_voos[findall(Lista_voos .>0)]
        global (X_k,CPUtime,Z1_1,Z2_1,Z3_1) = Tchebycheff_Heuristica_melhorativa_1(λ,ε,Z_ideal,Z_nadir,X_k,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
        CPUtime_melhorativa_1 = CPUtime_melhorativa_1 + CPUtime
    end 
    X_k1 = X_k
    #-------------------------------------------------------
    #Heuristica 2
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 2**********\n")
    @printf("******************************************\n")
    Isolto=[]
    for p in P 
        if length(Ip[p]) ==1
            Isolto = [Isolto;Ip[p]]
        end 
    end 
    ind_fixo=zeros(0,3);
    for t in T,i in setdiff(I,Isolto), h in Hi[i]
        if X_k1[i,t,h] > 0.5
            ind_fixo = [ind_fixo;[i t h]]
        end
    end
    ind_fixo = Int.(ind_fixo)

    Num_max=zeros(maximum(P))
    for p in P,i in 1:size(ind_fixo,1)
        if ind_fixo[i,1] ∈ Ip[p]
            Num_max[p] = Num_max[p] + 1
        end 
    end 
    Unidades_usadas = findall(Num_max .> 0)

    global (X_k2,CPUtime_melhorativa_2,Z1_2,Z2_2,Z3_2) = Tchebycheff_Heuristica_melhorativa_2(λ,ε,Z_ideal,Z_nadir,X_k1,ind_fixo,Num_max,Unidades_usadas,Tmax,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F);
    X_k3 = X_k2 
    #-------------------------------------------------------
    #Heuristica 3
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 3**********\n")
    @printf("******************************************\n")
    Maior_janela = zeros(length(I),length(I));
    for i in I 
        for j in I 
            if i != j 
                Maior_janela[i,j] = 0.5*(tf[i]-tu[i]) + tu[i] - 0.5*(tf[j]-tu[j]) 
            end 
        end 
    end 
    Ma = Int(ceil(findmax(Maior_janela)[1]))
    Ma = maximum([Ma,30])

    T_cedo = 40
    T_tarde = T_cedo+Ma 
    T_fixo = T_cedo:T_tarde 
    T_livre = setdiff(T,T_fixo)
    Voo_tarde = maximum([sum(t*X_k3[i,t,h] for h ∈ Hi[i] for t ∈ 1:T_cedo-1) for i in I])
    aux = [sum(t*X_k3[i,t,h] for h ∈ Hi[i] for t ∈ T_tarde+1:Tmax) for i in I]
    if sum(aux) > 0
        Voo_cedo = minimum(aux[findall(aux .>0)])
     else 
         Voo_cedo=[]
     end 
    ind_fixo=zeros(0,3);
    for t in T_fixo, i in I, h in Hi[i]
        if X_k3[i,t,h] > 0.5
            ind_fixo = [ind_fixo;[i t h]]
        end
    end
    ind_fixo = Int.(ind_fixo)
    Lista_voos = [sum(i*X_k3[i,t,h] for h ∈ Hi[i] for t ∈ T_fixo) for i in I]
    Lista_voos = Lista_voos[findall(Lista_voos .>0)]

    global (X_k4,CPUtime_melhorativa_3,Z1_3,Z2_3,Z3_3) = Tchebycheff_Heuristica_melhorativa_3(λ,ε,Z_ideal,Z_nadir,X_k3,Lista_voos,ind_fixo,Tmax,T_fixo,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
    X_k5 = X_k4
    
    #-------------------------------------------------------
    #Heuristica 4
    @printf("******************************************\n")
    @printf("**********Estamos na heurística melhorativa 4**********\n")
    @printf("******************************************\n")
    T_livre = T_fixo 
    Voo_tarde = maximum([sum(t*X_k5[i,t,h] for h ∈ Hi[i] for t ∈ 1:minimum(T_livre)-1) for i in I])
    aux = [sum(t*X_k5[i,t,h] for h ∈ Hi[i] for t ∈ maximum(T_livre)+1:Tmax) for i in I]
    if sum(aux) > 0
        Voo_cedo = minimum(aux[findall(aux .>0)])
     else 
         Voo_cedo=[]
     end 

    ind_fixo=zeros(0,3);
    for t in setdiff(T,T_livre), i in I, h in Hi[i]
        if X_k5[i,t,h] > 0.5
            ind_fixo = [ind_fixo;[i t h]]
        end
    end
    ind_fixo = Int.(ind_fixo)
    Lista_voos = [sum(i*X_k5[i,t,h] for h ∈ Hi[i] for t ∈ setdiff(T,T_livre)) for i in I]
    Lista_voos = Lista_voos[findall(Lista_voos .>0)]

    global (X_heuristico,CPUtime_melhorativa_4,Z1_4,Z2_4,Z3_4) = Tchebycheff_Heuristica_melhorativa_4(λ,ε,Z_ideal,Z_nadir,X_k5,Lista_voos,ind_fixo,Tmax,T_livre,Voo_tarde,Voo_cedo,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)

    info = [Z1_0 Z2_0 Z3_0 CPUtime_construtiva;
            Z1_1 Z2_1 Z3_1 CPUtime_melhorativa_1;
            Z1_2 Z2_2 Z3_2 CPUtime_melhorativa_2;
            Z1_3 Z2_3 Z3_3 CPUtime_melhorativa_3;
            Z1_4 Z2_4 Z3_4 CPUtime_melhorativa_4
            ]

    return (X_heuristico,info) 
end

function Valores_obj(Particao1,X_k,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
    Y=zeros(length(T),length(H))
    V=zeros(length(H))
    K=zeros(length(I))
    X=zeros(length(I),length(T),length(H))
    Tmax = maximum([maximum(T) - tf[i] for i in I])
    for i in I,t in 1:Tmax, h in Hi[i]
        X[i,t,h] = X_k[i,t,h]
    end
    Obj1=zeros(length(Particao1))
    Obj2=zeros(length(Particao1))
    Obj3=zeros(length(Particao1))
    j=1
    for Tmax in Particao1
        for i in I
            K[i] = 1-sum(X[i,t,h] for h ∈ Hi[i] for t ∈ 1:Tmax)
        end 
        for t in 1:Tmax, h in H
            s=0
            for i in Ih[h] 
                if maximum([r[i],t-tf[i]-tat+1])<=t 
                    for tt in t:-1:maximum([r[i],t-tf[i]-tat+1]) 
                        s = s + X[i,tt,h]
                    end
                end 
            end 
            Y[t,h] = s
        end 
        for h in H 
            if sum(Y[t,h] for t ∈ 1:Tmax)  > 0 
                V[h] = 1
            end 
        end 
        #-----------------------------------------------
        Obj1[j]=0
        if ~isempty(Ic)
            Obj1[j] = 0.4*sum(K[i] for i ∈ Ic)
        end 
        if ~isempty(I2)
            Obj1[j] = Obj1[j] + 0.3*sum(K[i] for i ∈ I2)
        end 
        if ~isempty(I1)
            Obj1[j] = Obj1[j] + 0.2*sum(K[i] for i ∈ I1)
        end 
        Obj1[j] = Obj1[j] + 0.1*sum(K[i] for i ∈ I0)
        #-----------------------------------------------
        Obj2[j]=0
        if ~isempty(Hs)
            Obj2[j] = 0.5*sum(V[h] for h ∈ Hs)
        end 
        if ~isempty(Hp)
            Obj2[j] = Obj2[j] + 0.3*sum(V[h] for h ∈ Hp)
        end 
        Obj2[j] = Obj2[j] + 0.2*sum(V[h] for h ∈ Hn)
        #-----------------------------------------------
        Obj3[j] = sum(F*(t-r[i])*X[i,t,h] for i ∈ I for h ∈ Hi[i] for t ∈ 1:Tmax)
        #-----------------------------------------------
        j=j+1
    end
    return (Obj1,Obj2,Obj3)
end

#-------------------------------------------------------
if maximum(I) <= 12
    Particao1=[40,80,maximum([maximum(T) - tf[i] for i in I])]
    Particao2=[1,70,maximum([maximum(T) - tf[i] for i in I])]
else 
    Particao1=[30,60,90,maximum([maximum(T) - tf[i] for i in I])]
    Particao2=[1,45,90,maximum([maximum(T) - tf[i] for i in I])]
end   
#-------------------------------------------------------
#Sol. min z1
λ=[0.9999;0.00005;0.00005];
(X_heuristico,info) = Integracao_heuristicas(λ,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_1 = X_heuristico
info_1 = info
#---------------------------------------------------
#Sol. min z2
λ=[0.00005;0.9999;0.00005];
(X_heuristico,info) = Integracao_heuristicas(λ,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_2 = X_heuristico
info_2 = info
#---------------------------------------------------
#Sol. min z3
λ=[0.00005;0.00005;0.9999];
(X_heuristico,info) = Integracao_heuristicas(λ,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_3 = X_heuristico
info_3 = info
#---------------------------------------------------
FileIO.save("X_heuristico_1_$g.jld2","RH",X_heuristico_1)
FileIO.save("X_heuristico_2_$g.jld2","RH",X_heuristico_2)
FileIO.save("X_heuristico_3_$g.jld2","RH",X_heuristico_3)
X_heuristico_1 = FileIO.load("X_heuristico_1_$g.jld2","RH")
X_heuristico_2 = FileIO.load("X_heuristico_2_$g.jld2","RH")
X_heuristico_3 = FileIO.load("X_heuristico_3_$g.jld2","RH")
#---------------------------------------------------
(Obj1_1,Obj2_1,Obj3_1) = Valores_obj(Particao1,X_heuristico_1,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
(Obj1_2,Obj2_2,Obj3_2) = Valores_obj(Particao1,X_heuristico_2,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
(Obj1_3,Obj2_3,Obj3_3) = Valores_obj(Particao1,X_heuristico_3,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)

Z1_ideal = minimum.([Obj1_1 Obj1_2 Obj1_3][i,:] for i in 1:length(Particao1))
Z2_ideal = minimum.([Obj2_1 Obj2_2 Obj2_3][i,:] for i in 1:length(Particao1))
Z3_ideal = minimum.([Obj3_1 Obj3_2 Obj3_3][i,:] for i in 1:length(Particao1))

Z1_nadir = maximum.([Obj1_1 Obj1_2 Obj1_3][i,:] for i in 1:length(Particao1))
Z2_nadir = maximum.([Obj2_1 Obj2_2 Obj2_3][i,:] for i in 1:length(Particao1))
Z3_nadir = maximum.([Obj3_1 Obj3_2 Obj3_3][i,:] for i in 1:length(Particao1))

Z_ideal = [Z1_ideal Z2_ideal Z3_ideal]
Z_nadir = [Z1_nadir Z2_nadir Z3_nadir]
#------------------------------------------------------
#Sol. com peso λ=[0.7 0.15 0.15]
λ=[0.7 0.15 0.15];
ε=0.0001
(X_Tchebycheff,info) = Tchebycheff_Integracao_heuristicas(λ,ε,Z_ideal,Z_nadir,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_4 = X_Tchebycheff
info_4 = info
FileIO.save("X_heuristico_4_$g.jld2","RH",X_heuristico_4)
X_heuristico_4 = FileIO.load("X_heuristico_4_$g.jld2","RH")
(Obj1_4,Obj2_4,Obj3_4) = Valores_obj(Particao1,X_heuristico_4,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
#------------------------------------------------------
#Sol. com peso λ=[0.15 0.7 0.15]
λ=[0.15 0.7 0.15];
(X_Tchebycheff,info) = Tchebycheff_Integracao_heuristicas(λ,ε,Z_ideal,Z_nadir,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_5 = X_Tchebycheff
info_5 = info
FileIO.save("X_heuristico_5_$g.jld2","RH",X_heuristico_5)
X_heuristico_5 = FileIO.load("X_heuristico_5_$g.jld2","RH")
(Obj1_5,Obj2_5,Obj3_5) = Valores_obj(Particao1,X_heuristico_5,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
#------------------------------------------------------
#Sol. com peso λ=[0.15 0.15 0.7]
λ=[0.15 0.15 0.7];
(X_Tchebycheff,info) = Tchebycheff_Integracao_heuristicas(λ,ε,Z_ideal,Z_nadir,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_6 = X_Tchebycheff
info_6 = info
FileIO.save("X_heuristico_6_$g.jld2","RH",X_heuristico_6)
X_heuristico_6 = FileIO.load("X_heuristico_6_$g.jld2","RH")
(Obj1_6,Obj2_6,Obj3_6) = Valores_obj(Particao1,X_heuristico_6,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
#------------------------------------------------------
#Sol. com peso λ=[1/3 1/3 1/3]
λ=[1/3 1/3 1/3];
(X_Tchebycheff,info) = Tchebycheff_Integracao_heuristicas(λ,ε,Z_ideal,Z_nadir,Particao1,Particao2,I,H,P,tat,d,tu,T,tf,r,I0,I1,I2,Ic,Ih,Ip,Hn,Hp,Hs,Hi,F)
X_heuristico_7 = X_Tchebycheff
info_7 = info
FileIO.save("X_heuristico_7_$g.jld2","RH",X_heuristico_7)
X_heuristico_7 = FileIO.load("X_heuristico_7_$g.jld2","RH")
(Obj1_7,Obj2_7,Obj3_7) = Valores_obj(Particao1,X_heuristico_7,I,T,Hi,H,Ih,r,tf,tat,Ic,I2,I1,I0,Hs,Hp,Hn,F)
#------------------------------------------------------
Pontos_n_dominados_heuristico =[
    Obj1_1[end] Obj2_1[end] Obj3_1[end]
    Obj1_2[end] Obj2_2[end] Obj3_2[end]
    Obj1_3[end] Obj2_3[end] Obj3_3[end]
    Obj1_4[end] Obj2_4[end] Obj3_4[end]
    Obj1_5[end] Obj2_5[end] Obj3_5[end]
    Obj1_6[end] Obj2_6[end] Obj3_6[end]
    Obj1_7[end] Obj2_7[end] Obj3_7[end]
]
FileIO.save("Pontos_n_dominados_heuristico_$g.jld2","RH",Pontos_n_dominados_heuristico)

info = [
    info_1
    info_2
    info_3
    info_4
    info_5
    info_6
    info_7
]
FileIO.save("informacoes_heuristico_$g.jld2","RH",info)

