MANIFEST = FileList["Manifest.txt", "Rakefile", "README.txt", "LICENSE.txt", "lib/**/*", "samples/*","test/**/*"]

file "Manifest.txt" => :manifest
task :manifest do
  File.open("Manifest.txt", "w") {|f| MANIFEST.each {|n| f << "#{n}\n"} }
end
Rake::Task['manifest'].invoke # Always regen manifest, so Hoe has up-to-date list of files

$LOAD_PATH << 'lib'
require 'jmx/version'
begin
  require 'hoe'
  Hoe.new("jmxjr", JMX::VERSION) do |p|
    p.rubyforge_name = "kenai"
    p.url = "http://kenai.com/projects/jmxjr"
    p.author = "Thomas Enebo & Jay McGaffigan"
    p.email = "enebo@acm.org"
    p.summary = "Package for interacting/creating Java Management Extensions"
    p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
    p.description = "Install this gem and require 'jmx' to load the library."
  end.spec.dependencies.delete_if { |dep| dep.name == "hoe" }
rescue LoadError
  puts "You need Hoe installed to be able to package this gem"
rescue => e
  p e.backtrace
  puts "ignoring error while loading hoe: #{e.to_s}"
end
