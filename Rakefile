require 'rake/clean'

#DUMP_SPREADSHEET_RB = 'bundle exec ruby tool/dump_spreadsheet.rb'
#DEBUG_SERVER_RB = 'bundle exec ruby oretool/debug_server.rb'
DUMP_SPREADSHEET_RB = 'ruby dump_spreadsheet.rb'
DEBUG_SERVER_RB = 'ruby debug_server.rb'
UNITY_DIR = '../client'
ASSETS_DIR = "#{UNITY_DIR}/Assets"
STREAMINGASSETS_DIR = "#{ASSETS_DIR}/StreamingAssets"

CLEAN.include('*.log')

task :default => [:dump]



directory STREAMINGASSETS_DIR
task :dump => STREAMINGASSETS_DIR do
  sh "#{DUMP_SPREADSHEET_RB} -o #{STREAMINGASSETS_DIR}/spreadsheet.msgpack"
end


task :server do
  sh "#{DEBUG_SERVER_RB} --document-root=#{STREAMINGASSETS_DIR}"
end
