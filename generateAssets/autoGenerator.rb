require 'json'
require 'pathname'
require 'fileutils'

# 1> 按文件名分组（scale和dark）；
# 2> 新建文件名.imageset 文件夹，移动图片到文件夹，生产Contents.json

class AssetGroup
  attr_accessor :name, :assets

  def initialize(name)
    @name = name
    @assets = []
  end

  def group_dir 
    dir_name = name + '.imageset'
    File.join($assets_path, dir_name)
  end

  def content_json_path
    File.join(group_dir, 'Contents.json')
  end
end

class AssetItem
  attr_accessor :has_appearance, :file_name, :scale

  def initialize(file_name, scale, has_appearance)
    @file_name = file_name
    @scale = scale 
    @has_appearance = has_appearance 
  end

  def img_name
    if has_appearance
      return "#{@file_name}_dark@#{@scale}x.png"
    else
      return "#{@file_name}@#{@scale}x.png"
    end
  end

  def dict_info
    dict = Hash.new
    dict["idiom"] = "universal"
    dict["filename"] = img_name 
    dict["scale"] = "#{@scale}x"
    if has_appearance
      dark_item = {"appearance" => "luminosity", "value" => "dark"}
      arr = [dark_item]
      dict["appearances"] = arr
    end
    return dict #dict.to_json
  end
end

def is_group_exist(name)
  $asset_group_list.each do |item|
    if item.name == name
      return item
    end
  end

  return nil
end

#####################Script Start##################### 

if ARGV.length != 2 
  puts "Not Pass enough params!"
  exit
end

$image_path = ARGV[0]
if File.exist?($image_path) == false 
  puts "Images Dir #{$image_path} not exist!"
  exit
end

$assets_path = ARGV[1]
if File.exist?($assets_path) == false
  puts "Assets Dir #{$assets_path} not exist!"
  exit
end

$dark_image_pattern = Regexp.new('([\w\s]+)_dark@(\d)x.png')
$image_pattern = Regexp.new('([\w\s]+)@(\d)x.png')
$asset_group_list = []

for file_name in Dir.children($image_path).sort do
  dip_matchData = $dark_image_pattern.match(file_name)
  ip_matchData = $image_pattern.match(file_name)

  if dip_matchData
    dip_match_res = dip_matchData.captures
    file_name = dip_match_res[0]
    scale = dip_match_res[1]
    group = is_group_exist(file_name)
    if group.nil?
      group = AssetGroup.new(file_name)
      $asset_group_list.push(group)
    end

    item = AssetItem.new(file_name, scale, true)
    group.assets.push(item)
  else
    if ip_matchData
      ip_match_res = ip_matchData.captures
      file_name = ip_match_res[0]
      scale = ip_match_res[1]
      group = is_group_exist(file_name)
      if group.nil?
        group = AssetGroup.new(file_name)
        $asset_group_list.push(group)
      end

      item = AssetItem.new(file_name, scale, false)
      group.assets.push(item)
    end
  end
end

$asset_group_list.each do |group|
  if File.exist?(group.group_dir) == false 
    puts "create group directory #{group.name}"
    Dir.mkdir(group.group_dir)
  end

  if File.exist?(group.content_json_path) == false 
    puts "create Contents.json"
    f_cj = File.new(group.content_json_path, 'w+')
    f_cj.close
  end

  if File.size?(group.content_json_path).nil?
    dict = Hash.new
    dict['images'] = Array.new
    dict["info"] = {'version' => 1, 'author' => 'xcode'}
    File.write(group.content_json_path, JSON.pretty_generate(dict))
  end

  cj_dict = JSON.parse(File.read(group.content_json_path))
  cj_img_cnt = cj_dict['images'].length
  group.assets.each do |item|
    group_img_path = File.join(group.group_dir, item.img_name)
    original_img_path = File.join($image_path, item.img_name)

    if File.exist?(group_img_path) == false
      FileUtils.cp(original_img_path, group.group_dir)
      cj_dict['images'].push(item.dict_info)
    else
      original_img_mtime = File.new(original_img_path).mtime.to_i
      group_img_mtime = File.new(group_img_path).mtime.to_i
      if original_img_mtime > group_img_mtime
        FileUtils.rm(group_img_path)
        FileUtils.cp(original_img_path, group.group_dir)
      end
    end
  end

  next if cj_img_cnt == cj_dict['images'].length
  File.write(group.content_json_path, JSON.pretty_generate(cj_dict))
end
