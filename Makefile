.PHONY: test run start day01 day02 day03 day04 day05 day06 day07 day08 day09 day10 day11 day12 day13 day14 day15 day16 day17 day18 day19 day20 day21 day22 day23 day24 day25

.DEFAULT_GOAL := test

test:
	gleam test

# Run today's code
run:
	time gleam run -m day$(shell date +%d)/solution

test/day%_test.gleam:
	- sed -E 's/dayXX/day$(*)/' templates/dayXX_test.gleam > $@

src/day%/solution.gleam:
	mkdir -p src/day$(*)
	- sed -E 's/dayXX/day$(*)/' templates/solution.gleam > $@

# This block should be easier, but you can start a day using dayXX
day01: test/day01_test.gleam src/day01/solution.gleam
day02: test/day02_test.gleam src/day02/solution.gleam
day03: test/day03_test.gleam src/day03/solution.gleam
day04: test/day04_test.gleam src/day04/solution.gleam
day05: test/day05_test.gleam src/day05/solution.gleam
day06: test/day06_test.gleam src/day06/solution.gleam
day07: test/day07_test.gleam src/day07/solution.gleam
day08: test/day08_test.gleam src/day08/solution.gleam
day09: test/day09_test.gleam src/day09/solution.gleam
day10: test/day10_test.gleam src/day10/solution.gleam
day11: test/day11_test.gleam src/day11/solution.gleam
day12: test/day12_test.gleam src/day12/solution.gleam
day13: test/day13_test.gleam src/day13/solution.gleam
day14: test/day14_test.gleam src/day14/solution.gleam
day15: test/day15_test.gleam src/day15/solution.gleam
day16: test/day16_test.gleam src/day16/solution.gleam
day17: test/day17_test.gleam src/day17/solution.gleam
day18: test/day18_test.gleam src/day18/solution.gleam
day19: test/day19_test.gleam src/day19/solution.gleam
day20: test/day20_test.gleam src/day20/solution.gleam
day21: test/day21_test.gleam src/day21/solution.gleam
day22: test/day22_test.gleam src/day22/solution.gleam
day23: test/day23_test.gleam src/day23/solution.gleam
day24: test/day24_test.gleam src/day24/solution.gleam
day25: test/day25_test.gleam src/day25/solution.gleam

# Start today's problem
start: test/day$(shell date +%d)_test.gleam src/day$(shell date +%d)/solution.gleam
