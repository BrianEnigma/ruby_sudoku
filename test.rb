#!/usr/bin/ruby

require './sudoku.rb'

print "Retrieving USA Today\n"
s = SudokuLoader.new()
s.update_data(:USA, ".")
`cat req_usa.txt`
date_label = ''
print "Parsing USA Today\n"
puzzle = s.parse_data(:USA, ".")
print("#{puzzle.title}, #{puzzle.date_label}, #{puzzle.difficulty}:\n")
print(SudokuLoader::grid_to_string(puzzle.grid))
#print("#{grid.inspect}\n")

print "Retrieving New York Times\n"
s.update_data(:NYTnew, ".")
`cat req_nytnew.txt`
date_label = ''
print "Parsing New York Times\n"
puzzle = s.parse_data(:NYTnew, ".")
print("#{puzzle.title}, #{puzzle.date_label}, #{puzzle.difficulty}:\n")
print(SudokuLoader::grid_to_string(puzzle.grid))

