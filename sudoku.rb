#!/usr/bin/ruby

require 'net/http'
require 'uri'

class SudokuLoader
  NYT = 1
  USA = 2

  def initialize()
    @debug = false
  end

  def get_url(source)
    result = ''
    case source
    when NYT
			result = 'http://nytsyn.pzzl.com/nytsyn-sudoku/nytsynhardsudoku?pm=uuid&username=&password='
    when USA
      today = Time.new.strftime("%y%m%d")
			result = "http://picayune.uclick.com/comics/ussud/data/ussud#{today}.xml"
    else
      result = ''
    end
    print("Using URL #{result}\n") if true == @debug
    return result
  end
  private :get_url

  def save_url(url, file)
    result = false
    uri = URI.parse(url)
    res = Net::HTTP::get_response(uri)
    if (res.code == "200")
      f = File.new(file, "w")
      f.write(res.body)
      f.close()
      result = true
    end
    return result
  end
  private :save_url

  def load_remote_data(source, cache_folder)
    result = false
    if (cache_folder.rindex('/') != cache_folder.length - 1)
      cache_folder += '/'
    end
    throw "Cache folder does not exist" if !File.exists?(cache_folder)
    throw "Cache folder is not a folder" if !File.directory?(cache_folder)
    case source
    when NYT:
      result = save_url(get_url(source), "#{cache_folder}req_tmp_nyt.txt")
      if (true == result)
        f = File.new("#{cache_folder}req_tmp_nyt.txt", "r")
        url = f.readline()
        url.strip!
        url = 'http://nytsyn.pzzl.com/nytsyn-sudoku/nytsynhardsudoku?pm=load&type=current&uuid=' + URI::escape(url)
        f.close()
        print("Using redirect URL #{url}\n") if true == @debug
        result = save_url(url, "#{cache_folder}req_nyt.txt")
      end
    when USA:
      result = save_url(get_url(source), "#{cache_folder}req_usa.txt")
    else
      throw "Unknown source"
    end
    return result
  end
  private :load_remote_data

  def update_data(source, cache_folder)
    result = false
    if (cache_folder.rindex('/') != cache_folder.length - 1)
      cache_folder += '/'
    end
    throw "Cache folder does not exist" if !File.exists?(cache_folder)
    throw "Cache folder is not a folder" if !File.directory?(cache_folder)
    case source
    when NYT
      filename = "#{cache_folder}req_nyt.txt"
    when USA
      filename = "#{cache_folder}req_usa.txt"
    else
      throw "Unknown source"
    end
    now = Time.new
    stamp = now - 60 * 60 * 24 * 2
    if File.exists?(filename)
      stamp = File.mtime(filename)
    end
    if now.mday() != stamp.mday()
      load_remote_data(source, cache_folder)
    elsif true == @debug
      print("Cache hit\n")
    end
  end

  def parse_data(source, cache_folder, date_label)
    if (cache_folder.rindex('/') != cache_folder.length - 1)
      cache_folder += '/'
    end
    throw "Cache folder does not exist" if !File.exists?(cache_folder)
    throw "Cache folder is not a folder" if !File.directory?(cache_folder)
    case source
    when NYT
      filename = "#{cache_folder}req_nyt.txt"
    when USA
      filename = "#{cache_folder}req_usa.txt"
    else
      throw "Unknown source"
    end
    data = File.new(filename, "r").read()
    if (NYT == source)
      pos1 = data.index('<LABEL>')
      pos2 = data.index('</LABEL>')
      return false if (nil == pos1 || nil == pos2)
      date_label << data[(pos1 + 7)...(pos2)]
      pos1 = data.index('<STARTGRID>')
      pos2 = data.index('</STARTGRID>')
      return false if (nil == pos1 || nil == pos2)
      data = data[(pos1 + 11)...pos2]
      pos1 = data.index('</COLUMNS>')
      data = data[pos1...data.length]
    elsif (USA == source)
      pos1 = data.index('<Date v=')
      return false if nil == pos1
      compact_date = data[(pos1 + 9)...(pos1 + 15)]
      date = Time.local(compact_date[0..1].to_i + 2000, compact_date[2..3].to_i, compact_date[4..5].to_i, 0, 0, 0, 0)
      date_label << date.strftime("%A, %B %-d, %Y")
      pos1 = data.index('<layout>')
      pos2 = data.index('</layout>')
      return false if (nil == pos1 || nil == pos2)
      data = data[(pos1 + 8)...pos2]
      data.gsub!(/<l[1-9]/, '')
    end
    print("#{data}\n") if true == @debug
    grid_numbers = Array.new
    data.each_byte { |b|
      if b >= "0"[0] && b <= "9"[0]
        grid_numbers << b.chr
      elsif NYT == source && b == "."[0] # blank space is dot
        grid_numbers << '.'
      elsif USA == source && b == "-"[0] # blank space is dash
        grid_numbers << '.'
      end
    }
    throw "Grid too small (#{grid_numbers.length})" if grid_numbers.length < 81
    throw "Grid too big (#{grid_numbers.length})" if grid_numbers.length > 81
    return grid_numbers
  end
  
  def self.grid_to_string(grid)
    result = ''
    (0...9).each { |y|
      (0...9).each { |x|
        result << grid[y * 9 + x]
        result << '|' if (x + 1) % 3 == 0 && x < 8
      }
      result << "\n"
      result << "---+---+---\n" if (y + 1) % 3 == 0 && y < 8
    }
    return result
  end

end

