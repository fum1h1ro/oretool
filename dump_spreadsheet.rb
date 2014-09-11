require "rubygems"
require "google_drive"
require "yaml"
require "msgpack"
require 'optparse'

def load_config
  path = File.dirname(File.expand_path(__FILE__))
  YAML.load(File.read("#{path}/.config"))
end
config = load_config
gdrive = config["google_drive"]

class Dumper
  def initialize(username, password)
    @session = GoogleDrive.login(username, password)
  end
  def dump_spreadsheet(key)
    # First worksheet of
    # https://docs.google.com/spreadsheet/ccc?key=pz7XtlQC-PYx-jrVMJErTcg
    #p session.spreadsheet_by_key(gdrive["spreadsheet"]).worksheets
    worksheets = @session.spreadsheet_by_key(key).worksheets
    dic = {}
    worksheets.each do |ws|
      data = dump_worksheet(ws)
      dic[ws.title] = data unless data.nil?
    end
    dic
  end
  def dump_worksheet(ws)
    if ws.num_rows == 0 or ws.num_cols == 0
      nil
    elsif ws[1, 1] == 'use'
      dump_worksheet_as_table(ws)
    else
      dump_worksheet_as_matrix(ws)
    end
  end
  def dump_worksheet_as_table(ws)
    use = find_use_list(ws)
    table = {}
    for col in 2..ws.num_cols
      list = []
      name = ws[1, col]
      unless name[0] == '_'
        for row in 2..ws.num_rows
          next unless use[row-1]
          v =  ws.numeric_value(row, col)
          if true#v.nil?
            list << ws[row, col]
          else
            list << v
          end
        end
        table[name] = list
      end
    end
    table
  end
  def dump_worksheet_as_matrix(ws)
    m = []
    for col in 1..ws.num_cols
      c = []
      for row in 1..ws.num_rows
        v = ws.numeric_value(row, col)
        if true#v.nil?
          c << ws[row, col]
        else
          c << v
        end
      end
      m << c
    end
    m
  end



  def find_use_list(ws)
    list = []
    for row in 1..ws.num_rows
      list << !ws[row, 1].empty?
    end
    list
  end





end

opts = {
  :o => '',
}
OptionParser.new do |opt|
  opt.on('-o FILENAME') { |f| opts[:o] = f }
  opt.parse(ARGV)
end
dmp = Dumper.new(gdrive["username"], gdrive["password"])
dic = dmp.dump_spreadsheet(gdrive["spreadsheet"])
bin = dic.to_msgpack
p dic
p MessagePack.unpack(bin)
unless opts[:o].empty?
  p opts[:o]
  File.open(opts[:o], 'w+') do |f|
    f.write(bin)
  end
end


#print YAML.dump({"jo"=>6})


# Gets content of A2 cell.
#p ws[1, 2]  #==> "hoge"

exit
# Changes content of cells.
# Changes are not sent to the server until you call ws.save().
#ws[2, 1] = "foo"
#ws[2, 2] = "bar"
#ws.save()

# Dumps all cells.
for row in 1..ws.num_rows
  for col in 1..ws.num_cols
      p ws[row, col]
  end
end
exit
# Yet another way to do so.
p ws.rows  #==> [["fuga", ""], ["foo", "bar]]

# Reloads the worksheet to get changes by other clients.
ws.reload()
