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
desc 'dump params'
task :dump => STREAMINGASSETS_DIR do
  files = ['sd_params', 'sd_params_debug']
  files.each do |fn|
    sh "#{DUMP_SPREADSHEET_RB} --dump 'OinkGames/sd/#{fn}' -o #{STREAMINGASSETS_DIR}/#{fn}.msgpack"
  end
end

desc 'copy sd_params'
task :copy => STREAMINGASSETS_DIR do
  sh "#{DUMP_SPREADSHEET_RB} --copy 'OinkGames/sd/sd_params' --dst 'OinkGames/sd/sd_params_debug'"
end

desc 'invoke server'
task :server do
  sh "#{DEBUG_SERVER_RB} --document-root=#{STREAMINGASSETS_DIR}"
end
