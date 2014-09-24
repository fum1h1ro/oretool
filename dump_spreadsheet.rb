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

module Ore
  class Drive
    #
    def initialize(username, password)
      @session = GoogleDrive.login(username, password)
    end
    #
    def collection(dir)
      pathto = dir.split('/')
      col = @session.root_collection
      pathto.each do |path|
        col = col.subcollection_by_title(path)
        if col.nil?
          raise "unknown folder: #{path}"
        end
      end
      col
    end
    #
    def exist?(filename)
      path = File.dirname(filename)
      title = File.basename(filename)
      col = collection(path)
      col.files('title'=>title, 'title-exact'=>'true').size > 0
    end
    #
    def delete(filename)
      path = File.dirname(filename)
      title = File.basename(filename)
      col = collection(path)
      fs = col.files('title'=>title, 'title-exact'=>'true')
      fs[0].delete if fs.size > 0
    end
    #
    def duplicate_spreadsheet(filename, newname)
      path = File.dirname(filename)
      title = File.basename(filename)
      col = collection(path)
      ss = col.spreadsheets('title'=>title, 'title-exact'=>'true')
      if ss.size > 0
        newpath = File.dirname(newname)
        newtitle = File.basename(newname)
        newss = ss[0].duplicate(newtitle)
        newcol = collection(newpath)
        unless newcol.root?
          newcol.add(newss)
          @session.root_collection.remove(newss)
        end
      end
    end
    #
    def move(filename, dir)
      pathto = dir.split('/')
      col = root = @session.root_collection
      pathto.each do |path|
        col = col.subcollection_by_title(path)
        if col.nil?
          raise "unknown folder: #{path}"
        end
      end
      f = root.files('title'=>filename, 'title-exact'=>'true')
      unless f.empty?
        col.add(f[0])
        root.remove(f[0])
      end
    end


    def dump_spreadsheet(filename)
      path = File.dirname(filename)
      title = File.basename(filename)
      worksheets = nil
      unless path.empty?
        col = collection(path)
        sss = col.spreadsheets('title'=>title, 'title-exact'=>'true')
        raise "not found #{filename}" if sss.empty?
        raise "duplicate? #{filename}" if sss.size > 1
        worksheets = sss[0].worksheets
      else
        # First worksheet of
        # https://docs.google.com/spreadsheet/ccc?key=pz7XtlQC-PYx-jrVMJErTcg
        #p session.spreadsheet_by_key(gdrive["spreadsheet"]).worksheets
        worksheets = @session.spreadsheet_by_title(title).worksheets
      end
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
end
opts = {
  :o => '',
  :dump => '',
  :copy => '',
  :dst => '',
}
OptionParser.new do |opt|
  opt.on('-o FILENAME') { |f| opts[:o] = f }
  opt.on('--dump CONTENT') { |f| opts[:dump] = f }
  opt.on('--copy SRCCONTENT') { |f| opts[:copy] = f }
  opt.on('--dst DSTCONTENT') { |f| opts[:dst] = f }
  opt.parse(ARGV)
end
drive = Ore::Drive.new(gdrive["username"], gdrive["password"])

#if drive.exist?('sd_params_debug')
#  drive.delete('sd_params_debug')
#end
#drive.duplicate_spreadsheet('sd_params', 'sd_params_debug')
#drive.move('sd_params_debug', 'OinkGames/sd')

if !opts[:o].empty? and !opts[:dump].empty?
  begin
    dic = drive.dump_spreadsheet(opts[:dump])
    bin = dic.to_msgpack
    #p dic
    #p MessagePack.unpack(bin)
    unless opts[:o].empty?
      #p opts[:o]
      File.open(opts[:o], 'w+') do |f|
        f.write(bin)
      end
    end
  rescue => e
    p e # not error
  end
end

if !opts[:copy].empty? and !opts[:dst].empty?
  drive.delete(opts[:dst])
  drive.duplicate_spreadsheet(opts[:copy], opts[:dst])
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
