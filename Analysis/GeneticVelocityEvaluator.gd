class_name GeneticVelocityEvaluator
extends Node

# This script was written by ChatGPT with prompt "Take a look at this manual evaluator. Write a super simple script that does a genetic algorithm version of this, picking the top n scoring detectors @sym:VelocityEvaluator and calling mutate on them with decreasing step size over time"

@export var population_size := 100
@export var generations := 50
@export var top_n := 10
@export var initial_step_size := 1.0
@export var starting_hand_threshold := 5.0
@export var starting_tip_threshold := 16.0
@export var starting_vel_dot_forward_max := 10.0
@export var starting_hold_velocity_threshold := 0.5

@onready var slash_evaluator: SlashDetectionEvaluator = $"../Evaluator"

func run() -> VelocityEvaluator:
	var population: Array[VelocityEvaluator] = [VelocityEvaluator.new(
		starting_hand_threshold,
		starting_tip_threshold,
		starting_vel_dot_forward_max,
		starting_hold_velocity_threshold,
	)]
	population.append_array(population[0].mutate(population_size - 1, initial_step_size))

	var best_detector := population[0]
	var best_score := -INF
	var survivor_count := clampi(top_n, 1, population_size)

	for generation in generations:
		var ranked_population: Array = []
		for detector in population:
			ranked_population.append([slash_evaluator.evaluate(detector), detector])
		ranked_population.sort_custom(func(a, b): return a[0] > b[0])

		if ranked_population[0][0] > best_score:
			best_score = ranked_population[0][0]
			best_detector = ranked_population[0][1]

		LoggerGlobal.info("Generation %d score: %f detector: %s" % [
			generation,
			ranked_population[0][0],
			ranked_population[0][1],
		])

		var survivors: Array[VelocityEvaluator] = []
		for index in survivor_count:
			survivors.append(ranked_population[index][1])

		var step_size := initial_step_size * (1.0 - float(generation + 1) / float(maxi(generations, 1)))
		population = survivors.duplicate()
		var children_needed := population_size - population.size()
		var children_per_survivor := ceili(float(children_needed) / float(survivors.size()))
		for survivor in survivors:
			population.append_array(survivor.mutate(children_per_survivor, step_size))
		population = population.slice(0, population_size)

	return best_detector
