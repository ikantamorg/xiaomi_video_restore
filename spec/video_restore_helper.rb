require_relative '../video_restore'


class Starter
  def self.options(filename)
    o = OptparseExample::ScriptOptions.new
    o.input = File.expand_path("spec/support/#{filename}.mp4")
    o.part_size = 50
    o
  end
end

class MyDir
  def self.clear
    self.files.each {|f| File.delete(f) }
  end

  def self.files
    Dir.glob("./output/*")
  end
end

class Result
  def self.correct?(filename)
    f = File.new(filename, 'rb').read
    f[0..11] == "\x00\x00\x00 ftypavc1" && f[-1].ord == 255
  end
end
