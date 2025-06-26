module GastonRecipes

using MacroTools: postwalk, @capture

"""
    PlotRecipe(data::Tuple, plotline)

Plot properties returned by a recipe using convert_args.
"""
struct PlotRecipe
    data     :: Tuple
    plotline
end

PlotRecipe(x) = PlotRecipe(x, "")

"""
    AxisRecipe(settings,
               plots::Vector{PlotRecipe},
               is3d::Bool = false)

Axis properties returned by a recipe using convert_args.
"""
struct AxisRecipe
    settings                       # axis settings
    plots    :: Vector{PlotRecipe} # one PlotRecipe per curve in the axis
    is3d     :: Bool               # if true, 'splot' is used; otherwise, 'plot' is used
end

AxisRecipe(x) = AxisRecipe("", x)

AxisRecipe(x, y) = AxisRecipe(x, y, false)

abstract type AbstractFigure end

"""
    FigureRecipe

"Bare" figure (without handle or associated gnuplot process) returned by a recipe
using convert_args.
"""
struct FigureRecipe <: AbstractFigure
    axes       :: Vector{AxisRecipe}
    multiplot  :: String
    autolayout :: Bool
end

FigureRecipe(a) = FigureRecipe(a, "", true)

FigureRecipe(a, s) = FigureRecipe(a, s, true)

function convert_args() end

function convert_args3() end

# @gpkw
function expand(d...)
    dd = Pair[]
    for (k,v) in d
        if v isa Vector{Pair}
            for (k1,v1) in v
                push!(dd, k1 => v1)
            end
        else
            push!(dd, k => v)
        end
    end
    return dd
end

function prockey(key)
    if @capture(key, a_ = b_)
        return :($(string(a)) => $b)
    elseif @capture(key, g_...)
        return :("theme" => $g)
    elseif @capture(key, a_)
        return :($(string(a)) => true)
    end
end

function procopts(d)
    if @capture(d, {xs__})
        return :($(expand)($(map(prockey, xs)...)))
    elseif @capture(d, f_(xs__))
        return :($f($(map(procopts, xs)...)))
    else
        return d
    end
end

"""
    @gpkw

Convert a variable number of keyword arguments to a vector of pairs of strings.

# Example

```julia
julia> @gpkw {title = Q"Example", grid = true}
2-element Vector{Pair}:
 "title" => "'Example'"
  "grid" => true
```
"""
macro gpkw(ex)
    esc(postwalk(procopts, ex))
end

### DataBlock

struct DataBlock
    data :: IOBuffer
end

"""
    DataBlock(vs::Vector{<:AbstractString}...)

Create a DataBlock from a vector of strings. Each vector is interpreted as a
block (separated by newlines).

### Example

```julia
julia> x = ["1 0 0", "1 1 1"]
julia> y = ["0 1 0"]
julia> z = ["0 0 1", "0 0 0"]
julia> db = DataBlock(x, y, z)
julia> print(String(take!(db.data)))
1 0 0
1 1 1

0 1 0

0 0 1
0 0 0
```
"""
function DataBlock(vs::Vector{<:AbstractString}...)
    iob = IOBuffer()
    for block in vs
        for l in block
            write(iob, l*"\n")
        end
        write(iob, "\n")
    end
    DataBlock(iob)
end

"""
    DataBlock(ts::NTuple{N, AbstractString) where N

Create a DataTable from a tuple of strings.

### Example

```julia
julia> x = ("1 0 0", "1 1 1", "0 1 0", "0 0 1", "0 0 0")
julia> db = DataBlock(x)
julia> print(String(take!(db.data)))
1 0 0
1 1 1
0 1 0
0 0 1
0 0 0
```
"""
function DataBlock(ts::NTuple{N, AbstractString}) where N
    iob = IOBuffer()
    for l in ts
        write(iob, l*"\n")
    end
    DataBlock(iob)
end

"""
    DataBlock(args::Union{AbstractVector{<:Real},
                          AbstractMatrix{<:Real}}...)

Create a DataTable from vectors or matrices. Each array is a
datablock, which are separated by newlines.

### Example
```julia
julia> X = [1 0 0; 0 0 1]
julia> Y = [1 0 1; 0 1 0]
julia> db = DataBlock(X, Y)
julia> print(String(take!(db.data)))
1 0 0
0 0 1

1 0 1
0 1 0
```
"""
function DataBlock(args::Union{AbstractVector{<:Real},
                               AbstractMatrix{<:Real}}...)
    iob = IOBuffer()
    for m in args
        m isa AbstractVector && (m = m')  # convert to row vector
        for r in eachrow(m)
            write(iob, join(r, " "))
            write(iob, "\n")
        end
        write(iob, "\n")
    end
    DataBlock(iob)
end

end # module GastonRecipes
