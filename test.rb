#!/usr/bin/ruby

require 'sudoku.rb'

s = SudokuLoader.new()
s.update_data(SudokuLoader::USA, ".")
date_label = ''
puzzle = s.parse_data(SudokuLoader::USA, ".")
print("#{puzzle.title}, #{puzzle.date_label}, #{puzzle.difficulty}:\n")
print(SudokuLoader::grid_to_string(puzzle.grid))
#print("#{grid.inspect}\n")

s.update_data(SudokuLoader::NYT, ".")
date_label = ''
puzzle = s.parse_data(SudokuLoader::NYT, ".")
print("#{puzzle.title}, #{puzzle.date_label}, #{puzzle.difficulty}:\n")
print(SudokuLoader::grid_to_string(puzzle.grid))

