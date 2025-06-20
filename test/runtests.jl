using GastonRecipes: @gpkw, PlotRecipe, AxisRecipe, FigureRecipe
using Test

@testset "Recipes" begin
    p = PlotRecipe((1:10, 11:20))
    @test p.data[1] == 1:10
    @test p.data[2] == 11:20
    @test p.plotline == ""
    p = PlotRecipe((1:10, 11:20), "11")
    @test p.data[1] == 1:10
    @test p.data[2] == 11:20
    @test p.plotline == "11"
    a = AxisRecipe([p])
    @test a.settings == ""
    @test a.plots[1].plotline == "11"
    @test a.is3d == false
    a = AxisRecipe("22", [p])
    @test a.settings == "22"
    @test a.plots[1].plotline == "11"
    @test a.is3d == false
    a = AxisRecipe("22", [p], true)
    @test a.settings == "22"
    @test a.plots[1].plotline == "11"
    @test a.is3d == true
    f = FigureRecipe([a])
    @test f.axes[1].plots[1].plotline == "11"
    @test f.multiplot == ""
    @test f.autolayout == true
    f = FigureRecipe([a], "mp")
    @test f.axes[1].plots[1].plotline == "11"
    @test f.multiplot == "mp"
    @test f.autolayout == true
    f = FigureRecipe([a], "mp", false)
    @test f.axes[1].plots[1].plotline == "11"
    @test f.multiplot == "mp"
    @test f.autolayout == false
    s = @gpkw {grid, grid = false, gg = "test"}
    @test s[1] == ("grid" => true)
    @test s[2] == ("grid" => false)
    @test s[3] == ("gg" => "test")
end
