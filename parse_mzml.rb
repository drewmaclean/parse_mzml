require 'base64'

def parseFile(parse_file)
  # XML from file

  rtArray = []
  mzArray = []
  mzBinaryArray = []
  intensityArray = []
  intensityBinaryArray = []
  binaryArray = []

  resultArray = []


  readfile = File.open(parse_file, 'r')
  isCorrectMS = false

  while line = readfile.gets
    line.chomp!

    if line['defaultArrayLength']
      /defaultArrayLength="(?<val>\d+)"/ =~ line
      tempLength = val.to_i
    end

    if line['value="1"']
      isCorrectMS = true
    elsif line['value="2"']
      isCorrectMS = false
    end

    if isCorrectMS && line['scan start time']
      /value="(?<val1>\d+).(?<val2>\d+)"/ =~ line
      tempLength.times { rtArray << val1 + "." + val2 } # repeat for each mz / intensity value in the array
    end


    if isCorrectMS && line['<binary>']
      binaryArray << line[/<binary>(.*?)<\/binary>/, 1]
    end


  end

  # move binary strings to correct arrays / mz is always before intensity
  binaryArray.each_with_index do |val, idx|
    mzBinaryArray << val if idx.even?
    intensityBinaryArray << val if idx.odd?
  end

  # decode strings
  mzBinaryArray.each { |val| mzArray << Base64.decode64(val).unpack('E*') } # double precision - little endian
  mzArray.flatten!
  mzArray.map! { |x| x.round(4) }
  mzArray.map! { |x| x.to_f }

  intensityBinaryArray.each { |val| intensityArray << Base64.decode64(val).unpack('e*') } # single precision - little endian
  intensityArray.flatten!
  intensityArray.map! { |x| x.round(4) }
  intensityArray.map! { |x| x.to_f }

  rtArray.map! { |x| x.to_f }

  # append to a arraylist of 3 tuple
  resultArray = [mzArray, rtArray, intensityArray]

  return resultArray

end

def sort(array, sort_type)
  puts array[0][100]
  if sort_type == '-mz'
    puts 'sort mz'
    array.sort_by! { |e| [e[2]] }

    #array[0].sort!
  end
  if sort_type == '-rt'
    puts 'sort rt'
    array.sort_by! { |e| [e[1]] }
  end
  puts array[0][100]
  return array
end


def main(in_file, sort_flag, sort_type)
  writefile = File.open('results.csv', 'w')
  array = parseFile(in_file)

  array = sort(array, sort_type) if sort_flag

  # write each array to csv file
  array[0].length.times do |i|
    writefile.print "#{array[0][i]},#{array[1][i]},#{array[2][i]}\n"
  end
end


main('mouse_uncompressed.mzML', '-s', '-mz')
#main(ARGV[0], ARGV[1], ARGV[2])