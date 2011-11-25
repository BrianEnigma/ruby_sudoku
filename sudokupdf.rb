#!/usr/bin/ruby
require 'rubygems'
require 'prawn'
require 'prawn/security'
require "prawn/layout"
require "prawn/graphics"
require "prawn/graphics/transformation"
require 'sudoku.rb'

Prawn.debug = false

INCHES_3p5 = 252
INCHES_5 = 360

grid = [".", ".", ".", ".", "2", ".", ".", ".", ".", ".", "3", "8", ".", "1", "5", "6", ".", ".", ".", ".", "5", ".", "6", "3", ".", "7", ".", ".", ".", ".", ".", "8", ".", ".", "3", "4", "1", ".", ".", ".", ".", ".", ".", ".", "2", "5", "8", ".", ".", "4", ".", ".", ".", ".", ".", "2", ".", "1", "7", ".", "4", ".", ".", ".", ".", "9", "2", "3", ".", "7", "8", ".", ".", ".", ".", ".", "9", ".", ".", ".", "."]

def draw_card(pdf, card_number, x, y, title, date, grid)
    grid_width = INCHES_3p5 - 10
    # Outer rectangle
    pdf.fill_color = '000000'
    pdf.stroke_color = '000000'
    pdf.rectangle([x, pdf.bounds.height - y], INCHES_3p5, INCHES_5)
    pdf.line_width(0.25)
    pdf.stroke
    # Title
    pdf.font "Helvetica"
    pdf.text_box("Sudoku, #{title}", {:kerning => true, :size => 12, :at => [x + 5, pdf.bounds.height - y - 5]})
    # Divider and date
    pdf.rectangle([x + 5, pdf.bounds.height - y - 20], grid_width, 10)
    pdf.fill
    pdf.font "Helvetica-Bold"
    pdf.fill_color = 'FFFFFF'
    pdf.stroke_color = 'FFFFFF'
    pdf.text_box("#{date}", {:kerning => true, :size => 8, :at => [x + 5 + 3, pdf.bounds.height - y - 20 - 2]})
    pdf.font "Helvetica"
    pdf.fill_color = 'FFFFFF'
    pdf.stroke_color = '000000'
    # Grid Outer Box
    pdf.rectangle([x + 5, pdf.bounds.height - y - 35], grid_width, grid_width)
    pdf.line_width(0.5)
    pdf.stroke
    (0...8).each { |i|
        offset = (i + 1) * (grid_width.to_f / 9)
        # vertical lines
        pdf.line([x + 5 + offset, pdf.bounds.height - y - 35], [x + 5 + offset, pdf.bounds.height - y - 35 - grid_width])
        if (i + 1) % 3 == 0 && i < 8
            pdf.line_width(2)
        else
            pdf.line_width(0.5)
        end
        pdf.stroke
        # horizontal lines
        pdf.line([x + 5, pdf.bounds.height - y - 35 - offset], [x + 5 + grid_width, pdf.bounds.height - y - 35 - offset])
        pdf.stroke
    }
    pdf.fill_color = '000000'
    pdf.stroke_color = '000000'
    grid_x = x + 5
    grid_y = pdf.bounds.height - y - 35
    if grid.length != 81
        pdf.text_box("Invalid data", {:size =>12, :at => [grid_x, grid_y - grid_width - 2]})
    else
        (0...81).each { |i|
            xpos = grid_x + (i % 9) * (grid_width.to_f / 9)
            ypos = grid_y - (i / 9) * (grid_width.to_f / 9)
            if grid[i] != '.'
                pdf.text_box(grid[i], {:size =>24, :at => [xpos, ypos - 2], :width => grid_width.to_f / 9, :height => grid_width.to_f / 9, :align => :center, :valign => :center})
            end
        }
    end
    
    
    
end

pdf = Prawn::Document.new()
s = SudokuLoader.new()

s.update_data(SudokuLoader::USA, "./cache/")
date_label = ''
grid = s.parse_data(SudokuLoader::USA, "./cache/", date_label)
#print("USA Today, #{date_label}:\n")
#print(SudokuLoader::grid_to_string(grid))
draw_card(pdf, 1, 0, 0, "USA Today", date_label, grid)

s.update_data(SudokuLoader::NYT, "./cache/")
date_label = ''
grid = s.parse_data(SudokuLoader::NYT, "./cache/", date_label)
#print("New York Times, #{date_label}:\n")
#print(SudokuLoader::grid_to_string(grid))
draw_card(pdf, 2, INCHES_3p5, 0, "New York Times", date_label, grid)

pdf.render_file("./results/sudoku-#{Time.new.strftime('%Y%m%d')}.pdf")