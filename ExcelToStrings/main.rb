# frozen_string_literal: true
require './read_string_excel'
require './string_file_crypt'
require './replace_string_occurs'

# file = 'live_strings.xlsx'
# reader = ReadStringExcel.new(file)
# reader.write_file 'live'

ase_crypt = StringFileCrypt.new('asjdlfjasdlkfaqw', 'alsjflkasdjflkaq', 'AES-128-CBC')

files = %w[/Users/mayong/Desktop/Localizable_ar.strings /Users/mayong/Desktop/Localizable.strings]

# files = reader.output_files 'live'
files.each do |file|
  ase_crypt.encrypt file
end

# strings_file = reader.get_string_file 'en'

# keys = strings_file.get_keys
# values = strings_file.get_values

# key_values = {}
# (0 .. keys.count).each { |i| key_values[values[i]] = keys[i] }
#
# replace = ReplaceStringOccurs.new key_values
# replace.parse_file '/Users/mayong/Desktop/wudi/LiveKitSwift/BF_LiveKitSwift/'