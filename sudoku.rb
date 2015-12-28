#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'base64'
require 'rubygems'
require 'json'

class SudokuPuzzle
  attr_accessor :grid, :title, :date_label, :difficulty
  def initialize()
    @grid = Array.new
    @title = ''
    @date_label = ''
    @difficulty = 0
  end
end

class SudokuLoader

  def initialize()
    @debug = false
  end

  def get_url(source)
    result = ''
    case source
    when :NYT
			result = 'http://nytsyn.pzzl.com/nytsyn-sudoku/nytsynhardsudoku?pm=uuid&username=&password='
    when :NYTnew
            result = 'http://www.nytimes.com/crosswords/game/sudoku/medium'
    when :USA
      today = Time.new.strftime("%y%m%d")
			result = "http://picayune.uclick.com/comics/ussud/data/ussud#{today}.xml"
    else
      result = ''
    end
    print("Using URL #{result}\n") if true == @debug
    return result
  end
  private :get_url

  def save_url(url, file, redirect)
    result = false
    print("Requesting #{url} as #{file}\n") if true == @debug
    uri = URI.parse(url)
    res = Net::HTTP::get_response(uri)
    if (res.code.to_i == 200)
      f = File.new(file, "w")
      f.write(res.body)
      f.close()
      result = true
    end
    if (redirect > 0 && (res.code.to_i / 100 == 3))
      print("Redirecting to #{res['location']}\n") if true == @debug
      return save_url(res['location'], file, redirect - 1)
    end
    print("Request result was #{result} #{res.code}\n")
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
    when :NYT
      result = save_url(get_url(source), "#{cache_folder}req_tmp_nyt.txt", 5)
      if (true == result)
        f = File.new("#{cache_folder}req_tmp_nyt.txt", "r")
        url = f.readline()
        url.strip!
        url = 'http://nytsyn.pzzl.com/nytsyn-sudoku/nytsynhardsudoku?pm=load&type=current&uuid=' + URI::escape(url)
        f.close()
        print("Using redirect URL #{url}\n") if true == @debug
        result = save_url(url, "#{cache_folder}req_nyt.txt", 5)
      end
    when :NYTnew
      #result = save_url(get_url(source), "#{cache_folder}req_tmp_nytnew.txt", 5)
      # Cheating and using wget because there's some magic about user agent, cookies, and the
      # redirect that NYT uses to detect scraping:
      cmd = "wget -q -O '#{cache_folder}req_tmp_nytnew.txt' '#{get_url(source)}'"
      `#{cmd}`
      f = File.new("#{cache_folder}req_tmp_nytnew.txt", "r")
      content = f.read()
      f.close()
      if (!content.empty?)
        content.gsub!(/.*window.preload = "/m, '')
        content.gsub!(/".*/m, '')
        #print("Using content #{content}\n") if true == @debug
        decoded = Base64.decode64(content)
        #print("Using decoded content #{decoded}\n") if true == @debug
        f = File.new("#{cache_folder}req_nytnew.txt", "w")
        f.write(decoded)
        f.close()
      end
    when :USA
      result = save_url(get_url(source), "#{cache_folder}req_usa.txt", 5)
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
    when :NYT
      filename = "#{cache_folder}req_nyt.txt"
    when :NYTnew
      filename = "#{cache_folder}req_nytnew.txt"
    when :USA
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

  def parse_data(source, cache_folder)
    result = SudokuPuzzle.new
    if (cache_folder.rindex('/') != cache_folder.length - 1)
      cache_folder += '/'
    end
    throw "Cache folder does not exist" if !File.exists?(cache_folder)
    throw "Cache folder is not a folder" if !File.directory?(cache_folder)
    case source
    when :NYT
      filename = "#{cache_folder}req_nyt.txt"
    when :NYTnew
      filename = "#{cache_folder}req_nytnew.txt"
    when :USA
      filename = "#{cache_folder}req_usa.txt"
    else
      throw "Unknown source"
    end
    data = File.new(filename, "r").read()
    if (:NYT == source)
      result.title = "New York Times"
      result.difficulty = 5
      pos1 = data.index('<LABEL>')
      pos2 = data.index('</LABEL>')
      return nil if (nil == pos1 || nil == pos2)
      result.date_label << data[(pos1 + 7)...(pos2)]
      pos1 = data.index('<STARTGRID>')
      pos2 = data.index('</STARTGRID>')
      return nil if (nil == pos1 || nil == pos2)
      data = data[(pos1 + 11)...pos2]
      pos1 = data.index('</COLUMNS>')
      data = data[pos1...data.length]
    elsif (:NYTnew == source)
      result.title = "New York Times"
      result.difficulty = 4
      json_data = JSON.parse(data)
      json_level = json_data['medium']
      p json_level if true == @debug
      result.date_label = json_level['print_date']
      puzzle_data = json_level['puzzle_data']['puzzle']
      p puzzle_data if true == @debug
      puzzle_data.map! { |val|
          val = '.' if nil == val
          val = '.' if 'nil' == val
          val = '.' if 'null' == val
          val = val.to_s
      }
      data = puzzle_data.join(' ')
      p data if true == @debug
    elsif (:USA == source)
      result.title = "USA Today"
      pos1 = data.index('<Difficulty v=')
      return nil if nil == pos1
      result.difficulty = data[(pos1 + 15)...(pos1 + 16)].to_i
      pos1 = data.index('<Date v=')
      return nil if nil == pos1
      compact_date = data[(pos1 + 9)...(pos1 + 15)]
      date = Time.local(compact_date[0..1].to_i + 2000, compact_date[2..3].to_i, compact_date[4..5].to_i, 0, 0, 0, 0)
      result.date_label << date.strftime("%A, %B %-d, %Y")
      pos1 = data.index('<layout>')
      pos2 = data.index('</layout>')
      return nil if (nil == pos1 || nil == pos2)
      data = data[(pos1 + 8)...pos2]
      data.gsub!(/<l[1-9]/, '')
    else
        throw "Unknown puzzle source"
    end
    print("#{data}\n") if true == @debug
    data.each_byte { |b|
      if b >= "0".ord() && b <= "9".ord()
        result.grid << b.chr
      elsif :NYT == source && b == ".".ord() # blank space is dot
        result.grid << '.'
      elsif :NYTnew == source && b == ".".ord() # blank space is dot
        result.grid << '.'
      elsif :USA == source && b == "-".ord() # blank space is dash
        result.grid << '.'
      end
    }
    throw "Grid too small (#{result.grid.length})" if result.grid.length < 81
    throw "Grid too big (#{result.grid.length})" if result.grid.length > 81
    return result
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

