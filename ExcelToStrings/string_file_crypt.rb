# frozen_string_literal: true
require 'aescrypt'
require 'base64'
class StringFileCrypt
  def initialize(key = 'asjdlfjasdlkfaqw', iv = 'alsjflkasdjflkaq', cipher_type = 'AES-128-CBC')
    @key = key
    @iv = iv
    @cipher_type = cipher_type
  end

  def encrypt(file_path)
    base_name = File.basename file_path
    dir_name = File.dirname file_path
    editing_file = File.join dir_name, "~$#{base_name}"
    encrypt_file file_path, editing_file
    File.delete file_path
    File.rename editing_file, file_path
  end

  def encrypt_file(origin_file, new_file)
    editing_file = File.open(new_file, 'w+')
    File.open(origin_file) do |file|
      line = file.readline
      until line.nil?
        new_line = encrypt_line line
        editing_file.write new_line
        unless file.eof?
          line = file.readline
        else
          line = nil
        end
      end
    end
    editing_file.close
  end

  def encrypt_line(line)
    return line if line.nil? || line.empty?
    words = line.split('=')
    return line if words.count < 2
    key = words[0]
    value = words[1].chomp.chop.chop.reverse.chop.chop.reverse
    encrypt_value = encrypt_string value
    "//#{line.chomp}\n#{key} = \"#{encrypt_value}\";\n\n"
  end

  def encrypt_string(string)
    ret = Base64.encode64(AESCrypt.encrypt_data(string, @key, @iv, @cipher_type)).chomp
    ret = ret.delete "\n"
    ret = ret.delete "\r\n"
    ret = ret.delete "\r"
    # puts(ret.count '\r')
    ret
  end
end
