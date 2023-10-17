# frozen_string_literal: true
require 'rubyXL'
require 'rubyXL/convenience_methods'
require './strings_file'
require './string_file_crypt'

class ReadStringExcel
  def initialize(excel_path)
    @excel_path = excel_path
    parse
  end

  def parse
    workbook = RubyXL::Parser.parse(@excel_path)
    worksheet = workbook[0]
    # key, language_0, language_1
    # line 0 is key and language code
    (0 .. worksheet.count - 1).each do |i|
      cell = worksheet[i]
      if i == 0
        parse_code cell
      else
        parse_key_value cell
      end
    end
  end

  def parse_key_value(cell)
    # cell 0 is key
    key = cell[0].value
    raise "key is empty" if key.nil? || key.empty?

    (1 .. cell.size).each do |i|
      break if cell[i].nil?
      value = cell[i].value
      code = @codes[i - 1]
      string_file = @code_strings[code]
      next if string_file.nil? || value.nil? || value.empty?
      string_file.add key, value
    end
  end

  def parse_code(cell)
    @code_strings = {}
    @codes = []
    (1 .. cell.size).each do |i|
      value = cell[i].value
      break if value.nil? || value.empty?
      value = value.downcase
      @code_strings[value] = StringsFile.new value
      @codes.push value
    end
  end

  def write_file(dir = nil, name)
    dir = Dir.getwd if dir.nil?
    @code_strings.values.each do |string_file|
      string_file.write_to_dir(dir, name)
    end
  end

  def output_files(dir = nil, name)
    dir = Dir.getwd if dir.nil?
    @code_strings.values.map { |string_file| string_file.output_file_in_dir(dir, name) }
  end

  def get_string_file(code)
    @code_strings[code.downcase]
  end
end


