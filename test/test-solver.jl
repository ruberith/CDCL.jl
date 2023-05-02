@testitem "Empty formula" begin
    model = Model()

    @clause model c1 []

    @test solve!(model) == false
end

@testitem "Satisfiable formula" begin
    model = Model()

    @variable model x
    @variable model y

    @clause model c1 [x y]
    @clause model c2 [!x !y]

    @test solve!(model) == true
end

@testitem "Unsatisfiable formula" begin
    model = Model()

    @variable model x
    @variable model y

    @clause model c1 [x y]
    @clause model c2 [!x !y]
    @clause model c3 [!x y]
    @clause model c4 [x !y]

    @test solve!(model) == false
end