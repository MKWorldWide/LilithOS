#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'LilithOS/LilithOS.xcodeproj'
sources_root = 'LilithOS/Sources'

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'LilithOS' }

# Remove all old Swift file references from the project
project.files.each do |file|
  if file.path&.end_with?('.swift')
    file.remove_from_project
  end
end

# Add all Swift files from the correct (flat) path, with correct relative path
Dir.glob(File.join(sources_root, '*', '*.swift')).each do |file|
  group_name = File.basename(File.dirname(file))
  group = project.main_group.find_subpath(["Sources", group_name], true)
  group.set_source_tree('SOURCE_ROOT')
  rel_path = File.join('Sources', group_name, File.basename(file))
  group.new_file(rel_path) unless group.files.find { |f| f.path == rel_path }
end

# Add files to the target's source build phase
if target
  target.source_build_phase.files.clear
  Dir.glob(File.join(sources_root, '*', '*.swift')).each do |file|
    rel_path = File.join('Sources', File.basename(File.dirname(file)), File.basename(file))
    file_ref = project.files.find { |f| f.path == rel_path }
    target.add_file_references([file_ref]) if file_ref
  end
end

project.save
puts '✅ Xcode project file references fully reset and updated (flat, correct paths)!' 