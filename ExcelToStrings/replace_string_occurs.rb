# frozen_string_literal: true

class ReplaceStringOccurs
  def initialize(key_values)
    @values = key_values
  end

  def parse_file(file)
    return if File.symlink? file
    if File.directory? file
      Dir.foreach file do |f|
        next if f.start_with? '.'
        parse_file File.join(file, f)
      end
    else
      parse_file_with_path file
    end
  end

  def should_parse(file_path)
    %w[.swift .m].include? File.extname file_path
  end

  def parse_file_with_path(file_path)
    return unless should_parse file_path
    new_file_path = editing_file_path_for file_path
    new_file = File.open(new_file_path, 'w+')

    File.open(file_path) do |file|
      line = file.readline
      until line.nil?
        new_line = handle_line line
        new_file.write new_line
        unless file.eof?
          line = file.readline
        else
          line = nil
        end
      end
    end

    new_file.close
    File.delete file_path
    File.rename new_file_path, file_path
  end

  def handle_line(line)
    new_line = @values.reduce(line) do |l, (k, v)|
      return l if k.nil? || k.empty?
      key = "\"#{k}\""
      value = "BFLocalizedString.bf_localizedString(\"#{v}\")"
      l.gsub(key, value)
    end
    new_line
  end

  def editing_file_path_for(file_path)
    base_name = File.basename file_path
    dir_name = File.dirname file_path
    File.join dir_name, "~$#{base_name}"
  end
end
