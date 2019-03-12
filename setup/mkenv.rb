#!/usr/bin/env ruby
#
# mkenv.rb - Make 'Plato2' environment image
#
# Usage: ruby mkenv.rb [instdir]
#   instdir:  'Plato' install directory (default: '~/plato' or 'c:/plato')
#

require 'fileutils'

PLATO_UI = 'plato-ui'

puts "<< mkenv.rb >>"

#
# functions
#

# _cp(src, dst)
#   `cp -R <src> <dst>`
def _cp(src, dst)
  FileUtils.cp_r(src, dst, {:remove_destination => true})
rescue => e
  puts "warning: #{e}" if $DEBUG
end


#
# main
#

# Get platform
$platform = case RUBY_PLATFORM.downcase
when /mswin(?!ce)|mingw|cygwin|bccwin/
  :win
when /darwin/
  :mac
when /linux/
  :linux
else
  :other
end
$exe = $platform == :win ? '.exe' : ''
$home = $platform == :win ? 'c:/' : Dir.home
puts "Platform: #{$platform}"

# Setup install directory
srcroot = File.join(File.dirname($0), '..')
instdir = ARGV[0] ? ARGV[0] : File.join($home, 'plato2')
FileUtils.mkdir_p(instdir)
puts "instdir: '#{instdir}'"

# make sub projects

## Plato UI
puts 'build Plato UI...'
# `cd #{File.join(srcroot, PLATO_UI)}; make init; make #{$platform}`
`make -C #{File.join(srcroot, PLATO_UI)} #{$platform}`

###############################

# # $PLATO/.plato
# #   plato.sh
# #   plato.bat
# puts 'copy shells...'
# [ File.join(srcroot, 'plato', 'plato.bat'),
#   File.join(srcroot, 'plato', 'plato.sh')
# ].each {|file|
#   _cp(file, File.join(instdir, File.basename(file)))
# }


# $PLATO/.plato/tools
#   prjmaker.rb
#   mrbwrite.exe
#   mrbc141.exe / mrbc141
#   mrbc200.exe / mrbc200
puts 'copy tools...'
_plato_dir = File.join(instdir, '.plato')
tools_dir = File.join(_plato_dir, 'tools')
FileUtils.rm_rf(tools_dir)
FileUtils.mkdir_p(tools_dir)
[
  File.join(srcroot, 'plato', 'tools', 'prjmaker', 'prjmaker.rb'),
  File.join(srcroot, 'plato', 'tools', 'utils', 'makebin.rb'),
  File.join(srcroot, 'plato', 'tools', 'bin', 'mrbwrite' + $exe),
  File.join(srcroot, 'plato', 'tools', 'bin', 'mrbc141' + $exe),
  File.join(srcroot, 'plato', 'tools', 'bin', 'mrbc200' + $exe)
].each {|file|
  _cp(file, File.join(tools_dir, File.basename(file)))
}
# tools/mgemlist
# _cp(File.join(srcroot, 'plato', 'tools', 'boxmgem', 'mgemlist'), File.join(tools_dir, 'mgemlist'))


# $PLATO/.plato/prjbase
#   Rakefile
#   *.erb
#   user_build_config.rb
puts 'copy skelton files...'
prjbase_src = File.join(srcroot, 'plato', 'tools', 'prjmaker', 'prjbase')
FileUtils.rm_rf(File.join(_plato_dir, 'prjbase'))
_cp(prjbase_src, _plato_dir)

# # $PLATO/mrbgems
# puts 'copy mrbgems...'
# mrbgem_dst = File.join(instdir, 'mrbgems')
# FileUtils.rm_rf(mrbgem_dst)
# _cp(File.join(srcroot, 'mrbgems'), mrbgem_dst)

# $PLATO/.plato/plato
puts 'copy Plato UI...'
case $platform
when :win
  ['plato2-win32-ia32']
when :mac
  ['plato2-darwin-x64']
when :linux
  ['plato2-linux-ia32']  # + ['plato-linux-x64']
end.each {|target|
  plato_src = File.join(srcroot, PLATO_UI, 'bin', target)
  $plato_dst = File.join(_plato_dir, target)
  FileUtils.rm_rf($plato_dst)
  _cp(plato_src, $plato_dst)
}

# # $HOME/.vscode/extensions
# puts 'copy VSCode extensions...'
# EXTNAME = 'mruby-plato'
# home_dir = ($platform == :win) ? ENV['USERPROFILE'] : Dir.home
# vscext_dst = File.join(home_dir, '.vscode', 'extensions', EXTNAME)
# vscext_src = File.join(srcroot, 'plato', 'tools', 'vscode-extension', EXTNAME)
# FileUtils.rm_rf(vscext_dst)
# `make -C #{vscext_src}`
# FileUtils.mkdir_p(File.join(vscext_dst, 'out', 'src'))
# _cp(File.join(vscext_src, 'package.json'), vscext_dst)
# _cp(File.join(vscext_src, 'out', 'src', 'extension.js'), File.join(vscext_dst, 'out', 'src'))
# # _cp(File.join(vscext_src, 'images'), vscext_dst)

# Create shortcut
case $platform
when :win
  `wscript #{File.join(File.dirname($0), 'shortcut.vbs')} #{instdir}`
when :mac
  `ln -s #{File.join($plato_dst, 'plato.app')} #{File.join('~/Applications', 'Plato\ IDE.app')}`
end

puts $0 + ' completed.'
