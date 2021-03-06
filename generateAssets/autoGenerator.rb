require 'json'
require 'pathname'
require 'fileutils'

# 1> 按文件名分组（scale和dark）；
# 2> 新建文件名.imageset 文件夹，移动图片到文件夹，生产Contents.json；
# 3> 根据最新的UI文件夹中的图片，尝试删除.xcassets中的旧的imageset；

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
  attr_accessor :has_appearance, :file_name, :scale, :dir_path, :extension_name

  def initialize(dir_path, file_name, scale, has_appearance, extension_name)
    @dir_path = dir_path
    @file_name = file_name
    @scale = scale 
    @has_appearance = has_appearance 
    @extension_name = extension_name
  end

  def img_name
    if has_appearance
      return "#{@file_name}_dark@#{@scale}x.#{@extension_name}"
    else
      return "#{@file_name}@#{@scale}x.#{@extension_name}"
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

  def img_path
    return File.join(dir_path, img_name)
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

def remove_img_item_in_images_assets(name)
  if $images_xcassets_items.include?(name) == true
    $images_xcassets_items.delete(name)
  end
end

def search_group_from_directory(name)
  for file_name in Dir.children(name).sort do
    file_full_path = File.join($image_path, file_name)
    if File.directory?(file_full_path) == true 
      search_group_from_directory(file_full_path)
      next
    end

    dip_matchData = $dark_image_pattern.match(file_name)
    ip_matchData = $image_pattern.match(file_name)

    if dip_matchData
      dip_match_res = dip_matchData.captures
      file_name = dip_match_res[0]
      scale = dip_match_res[1]
      extension_name = dip_match_res[2]

      group = is_group_exist(file_name)
      if group.nil?
        group = AssetGroup.new(file_name)
        remove_img_item_in_images_assets(group.name)
        $asset_group_list.push(group)
      end

      item = AssetItem.new(name, file_name, scale, true, extension_name)
      group.assets.push(item)
    else
      if ip_matchData
        ip_match_res = ip_matchData.captures
        file_name = ip_match_res[0]
        scale = ip_match_res[1]
        extension_name = ip_match_res[2]

        group = is_group_exist(file_name)
        if group.nil?
          group = AssetGroup.new(file_name)
          remove_img_item_in_images_assets(group.name)
          $asset_group_list.push(group)
        end

        item = AssetItem.new(name, file_name, scale, false, extension_name)
        group.assets.push(item)
      end
    end
  end
end

def try_remove_old_image_assets
  for file_name in $images_xcassets_items do
    full_name = file_name + '.imageset'
    file_full_path = File.join($assets_path, full_name)
    if File.directory?(file_full_path) == true
      puts "remove old imageset #{file_name}"
      FileUtils.remove_dir(file_full_path)
    end
  end
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

$dark_image_pattern = Regexp.new('([\S\s]+)_dark@(\d)x.(.+)')
$image_pattern = Regexp.new('([\S\s]+)@(\d)x.(.+)')
$asset_group_list = []
$images_xcassets_items = Dir.children($assets_path).map { |file_name| file_name[0...file_name.index('.imageset')] }

search_group_from_directory($image_path)
try_remove_old_image_assets

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
    original_img_path = item.img_path

    if File.exist?(group_img_path) == false
      FileUtils.cp(original_img_path, group.group_dir)
      cj_dict['images'].push(item.dict_info)
    else
      f_oi = File.new(original_img_path)
      f_gi = File.new(group_img_path)
      original_img_mtime = f_oi.mtime.to_i
      group_img_mtime = f_gi.mtime.to_i
      if original_img_mtime > group_img_mtime
        FileUtils.rm(group_img_path)
        FileUtils.cp(original_img_path, group.group_dir)
      end
      f_oi.close
      f_gi.close
    end
  end

  next if cj_img_cnt == cj_dict['images'].length
  File.write(group.content_json_path, JSON.pretty_generate(cj_dict))
end
