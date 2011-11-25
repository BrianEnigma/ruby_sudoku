#!/usr/bin/ruby

require 'sudoku.rb'

s = SudokuLoader.new()
s.update_data(SudokuLoader::USA, ".")
date_label = ''
grid = s.parse_data(SudokuLoader::USA, ".", date_label)
print("USA Today, #{date_label}:\n")
print(SudokuLoader::grid_to_string(grid))
#print("#{grid.inspect}\n")

s.update_data(SudokuLoader::NYT, ".")
date_label = ''
grid = s.parse_data(SudokuLoader::NYT, ".", date_label)
print("New York Times, #{date_label}:\n")
print(SudokuLoader::grid_to_string(grid))

