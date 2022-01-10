# 判断当前分支，判断工作区是否为空，否则不允许操作；
# 当前路径，查找是否存在podspec；
# 读取到version，打印出来；
# 输入新到version；
# 更改podspec，提交，打tag，推送；

require 'tempfile'

class Color
    def self.red
        31
    end
    def self.green
        32
    end
    def self.white
        37
    end
end

def color_text(text, color = Color.natural)
    if color == 0
        return text
    end
    return "\033[#{color}m#{text}\033[0m"
end

# 1
current_branch = `git rev-parse --abbrev-ref HEAD`.strip
target_branchs = ["master", "main"]
if target_branchs.include?(current_branch) == false
  error_msg = "Error: Current branch is not #{target_branchs.inspect}."
  puts color_text(error_msg, Color.red)
  exit
end

# 2
git_status_output = `git status --porcelain`
if git_status_output.length > 0 
  error_msg = "Error: Changes not staged for commit."
  puts color_text(error_msg, Color.red)
  exit
end

`git fetch`
behind_count = `git rev-list --count HEAD..@{u}`.to_i
ahead_count = `git rev-list --count @{u}..HEAD`.to_i
if behind_count > 0 or ahead_count > 0
  error_msg = "Error: #{current_branch} is not up to date."
  puts color_text(error_msg, Color.red)
  exit
end

# 3
accepted_files = [".podspec"]
podspec_dir = Dir.pwd
podspec_file_name = ""
for file_name in Dir.children(podspec_dir) do
  if accepted_files.include?(File.extname(file_name)) 
    podspec_file_name = file_name
    break
  end
end
if podspec_file_name.length == 0 
  error_msg = "Error: Not found podspec file."
  puts color_text(error_msg, Color.red)
  exit
end

# 4
podspec_file_path = File.join(podspec_dir, podspec_file_name)
current_version = ""
podspec_file = File.open(podspec_file_path)
podspec_file_data = podspec_file.read
podspec_file_data.each_line do |line|
  key_value = line.split('=')
  if (key_value.length == 2)
    key = key_value.first.to_s.gsub("\n", '').gsub(' ','').gsub("\t",'')
    if key == "s.version"
      value = key_value.last.to_s.gsub("\n", '').gsub(' ','').gsub("\t",'')
      current_version = value
      break
    end
  end
end
if current_version.length == 0
  error_msg = "Error: Not found prev version."
  puts color_text(error_msg, Color.red)
  exit
end

# 5
puts color_text("Current version is #{current_version}", Color.white)
puts "Enter new version: "
new_version = gets.chomp

puts current_version
puts new_version
if Gem::Version.new(new_version) <= Gem::Version.new(current_version)
  error_msg = "Error: invalid version."
  puts color_text(error_msg, Color.red)
  exit
end

# 6
temp_podspec_file_name = "temp.podspec"
temp_podspec_file = Tempfile.new(temp_podspec_file_name)
begin
  podspec_file_data.each_line do |line|
      to_write_line = line
      key_value = line.split('=')
      if (key_value.length == 2)
        original_key = key_value.first.to_s
        key = key_value.first.to_s.gsub("\n", '').gsub(' ','').gsub("\t",'')
        if key == "s.version"
          to_write_line = original_key + "= #{new_version}"
        end
      end

      temp_podspec_file.puts to_write_line 
  end
  temp_podspec_file.close
  FileUtils.mv(temp_podspec_file.path, podspec_file_path)
ensure
  temp_podspec_file.close
  temp_podspec_file.unlink
end
podspec_file.close

# 7
add_command = "git add #{podspec_file_name}"
commit_msg = "new version #{new_version}"
commit_command = "git commit -m '#{commit_msg}'"
tag_command = "git tag '#{new_version}' "

`#{add_command}`
`#{commit_command}`
`#{tag_command}`

remote_name = `git remote`.strip
if remote_name.length > 0 
  push_command = "git push #{remote_name} #{current_branch}"
  push_tag_command = "git push #{remote_name} #{new_version}"
  `#{push_command}`
  `#{push_tag_command}`
end

puts color_text("Success.", Color.green)
