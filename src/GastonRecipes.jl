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

end # module GastonRecipes
