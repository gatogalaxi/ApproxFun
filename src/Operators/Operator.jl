export Operator,RowOperator,InfiniteOperator
export bandrange, linsolve



abstract Operator{T} #T is the entry type, Flaot64 or Complex{Float64}
abstract RowOperator{T} <: Operator{T}
abstract InfiniteOperator{T} <: Operator{T}
abstract BandedBelowOperator{T} <: InfiniteOperator{T}
abstract BandedOperator{T} <: BandedBelowOperator{T}

abstract ShiftOperator{T} <: Operator{T} #For biinfinite operators
abstract InfiniteShiftOperator{T} <: ShiftOperator{T}
abstract BandedShiftOperator{T} <: InfiniteShiftOperator{T}
abstract RowShiftOperator{T} <: ShiftOperator{T}


## We assume operators are T->T
domain(A::Operator)=Any

domain(f::IFun)=f.domain
domain(::Number)=Any

function domain(P::Vector)
    ret = Any
    
    for op in P
        d = domain(op)
        @assert ret == Any || d == Any || ret == d
        
        if d != Any
            ret = d
        end
    end
    
    ret
end


Base.size(::InfiniteOperator)=[Inf,Inf]
Base.size(::RowOperator)=Any[1,Inf] #use Any vector so the 1 doesn't become a float
Base.size(op::Operator,k::Integer)=size(op)[k]


Base.getindex(op::Operator,k::Integer,j::Integer)=op[k:k,j:j][1,1]
Base.getindex(op::Operator,k::Integer,j::Range1)=op[k:k,j][1,:]
Base.getindex(op::Operator,k::Range1,j::Integer)=op[k,j:j][:,1]


Base.getindex(op::RowOperator,k::Integer)=op[k:k][1]

function Base.getindex(op::RowOperator,j::Range1,k::Range1)
  @assert j[1]==1 && j[end]==1
  op[k]' #TODO conjugate transpose?
end
function Base.getindex(op::RowOperator,j::Integer,k::Range1)
  @assert j==1
  op[k]' #TODO conjugate transpose?
end



function Base.getindex(B::Operator,k::Range1,j::Range1)
    BandedArray(B,k,j)[k,j]
end


## indexrange

function indexrange(b::BandedBelowOperator,k::Integer)
    ret = bandrange(b) + k
  
    (ret[1] < 1) ? (1:ret[end]) : ret
end

index(b::BandedBelowOperator)=1-bandrange(b)[1]



## Multiplication of operator * fun


ultraiconversion(g::Vector,m::Integer)=(m==0)? g : backsubstitution!(MutableAlmostBandedOperator(Operator[ConversionOperator(0:m)]),copy(g))
ultraconversion(g::Vector,m::Integer)=(m==0)? g : ConversionOperator(0:m)*g

function *{T<:Number}(A::BandedOperator,b::Vector{T})
    n=length(b)
    m=n-bandrange(A)[1]
    ret = zeros(T,m)
    BA = BandedArray(A,1:m)
    
    for k=1:n - bandrange(A)[end]
        for j=indexrange(BA,k)
            ret[k] += BA[k,j]*b[j] 
        end
    end
    
    for k=max(n-bandrange(A)[end]+1,1):m
        for j=indexrange(BA,k)[1]:n
            ret[k] += BA[k,j]*b[j]             
        end
    end

    ret
end



*(A::InfiniteOperator,b::IFun)=IFun(ultraiconversion(A*ultraconversion(b.coefficients,domainspace(A).order),rangespace(A).order),b.domain)

*(A::RowOperator,b::Vector)=dot(A[1:length(b)],b)
*(A::RowOperator,b::IFun)=A*b.coefficients
*{T<:Operator}(A::Vector{T},b::IFun)=map(a->a*b,convert(Array{Any,1},A))



## Linear Solve


IFun_coefficients(b::Vector,sp)=vcat(map(f-> typeof(f)<: IFun? coefficients(f,sp) :  f,b)...)
FFun_coefficients(b::Vector)=vcat(map(f-> typeof(f)<: FFun? interlace(f.coefficients) :  interlace(f),b)...) #Assume only FFun or ShiftVector

function IFun_linsolve{T<:Operator}(A::Vector{T},b::Vector;tolerance=0.01eps(),maxlength=Inf)
    u=adaptiveqr(A,IFun_coefficients(b,rangespace(A[end]).order),tolerance,maxlength)  ##TODO: depends on ordering of A
    
    IFun(u,domain([A,b]))
end

function FFun_linsolve{T<:Operator}(A::Vector{T},b::Vector;tolerance=0.01eps(),maxlength=Inf)
    @assert length(A) == 1

    u=adaptiveqr([interlace(A[1])],FFun_coefficients(b),tolerance,maxlength)
    
    FFun(deinterlace(u),domain([A,b]))    
end

function linsolve{T<:Operator}(A::Vector{T},b::Vector;tolerance=0.01eps(),maxlength=Inf)
    d=domain([A,b])

    if typeof(d) <: IntervalDomain
        IFun_linsolve(A,b;tolerance=tolerance,maxlength=maxlength)
    elseif typeof(d) <: PeriodicDomain
        FFun_linsolve(A,b;tolerance=tolerance,maxlength=maxlength)
    else
        adaptiveqr(A,b,tolerance,maxlength)
    end    
end


##Todo nxn operator
# function linsolve{T<:Operator}(A::Array{T,2},b::Vector)
#     ret=adaptiveqr(interlace(A),b)
#     [IFun(ret[1:2:end],domain(A[:,1])),
#     IFun(ret[2:2:end],domain(A[:,2]))]
# end
# 


linsolve(A::Operator,b::Vector;kwds...)=linsolve([A],b;kwds...)
linsolve(A,b;kwds...)=linsolve(A,[b];kwds...)


\{T<:Operator}(A::Array{T,2},b::Vector)=linsolve(A,b)
\{T<:Operator}(A::Vector{T},b::Vector)=linsolve(A,b)
\(A::Operator,b)=linsolve(A,b)



include("ShiftArray.jl")

include("OperatorSpace.jl")

include("ToeplitzOperator.jl")

include("ConstantOperator.jl")

include("Ultraspherical/MultiplicationOperator.jl")
include("Ultraspherical/EvaluationOperator.jl")
include("Ultraspherical/ConversionOperator.jl")
include("Ultraspherical/DerivativeOperator.jl")
include("Ultraspherical/IntegrationOperator.jl")



include("AlmostBandedOperator.jl")
include("adaptiveqr.jl")


include("OperatorAlgebra.jl")
include("RowOperatorAlgebra.jl")

include("specialfunctions.jl")

include("TransposeOperator.jl")
include("StrideOperator.jl")
include("CompactOperator.jl")

include("Fourier/FourierDerivativeOperator.jl")

include("null.jl")



## Convenience routines

Base.diff(d::IntervalDomain,μ::Integer)=DerivativeOperator(0:μ,d)
Base.diff(d::PeriodicDomain,μ::Integer)=FourierDerivativeOperator(μ,d)
Base.diff(d::Domain)=Base.diff(d,1)

Base.eye(d::IntervalDomain)=MultiplicationOperator(IFun([1.],d))
Base.eye(d::PeriodicDomain)=MultiplicationOperator(FFun(ShiftVector([1.],1),d))

integrate(d::IntervalDomain)=IntegrationOperator(1,d)

evaluate(d::IntervalDomain,x)=EvaluationOperator(d,x)
dirichlet(d::IntervalDomain)=[evaluate(d,d.a),evaluate(d,d.b)]
neumann(d::IntervalDomain)=[EvaluationOperator(d,d.a,1),EvaluationOperator(d,d.b,1)]

Base.start(d::IntervalDomain)=evaluate(d,d.a)
Base.endof(d::IntervalDomain)=evaluate(d,d.b)

## Conversion

Base.convert{N<:Number}(A::Type{Operator},n::N)=ConstantOperator(1.n,0)
