# frozen_string_literal: true

class StringsFile
  def initialize(name)
    @name = name.downcase
    @values = {}
  end

  def add(key, value)
    @values[key] = value
  end

  def write_to_dir(dir, name)
    file_path = output_file_in_dir(dir, name)
    write_to_file file_path
  end

  def write_to_file(file_path)
    File.open file_path, 'w+' do |file|
      file.write(@values.map { |key, value| "\"#{key}\" = \"#{value}\";" }.join("\n"))
    end
  end

  def output_file_in_dir(dir, name)
    lproj_path = File.join dir, "#{@name}.lproj"
    Dir.mkdir lproj_path unless File.directory? lproj_path
    File.join lproj_path, "#{name}.strings"
  end

  def get_keys
    @values.keys.map { |s| s.to_s }
  end

  def get_values
    @values.values.map { |v| v.to_s }
  end
end
