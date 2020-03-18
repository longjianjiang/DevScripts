require_relative 'generateAPIManagerHeader'
require_relative 'generateAPIManagerSource'


def get_method_type(method)
  if method.upcase == "GET"
    return "JXNetworkingRequestTypeGet"
  elsif method.upcase == "POST"
    return "JXNetworkingRequestTypePost"
  elsif method.upcase == "PUT"
    return "JXNetworkingRequestTypePut"
  elsif method.upcase == "DELETE"
    return "JXNetworkingRequestTypeDelete"
  else
    return "JXNetworkingRequestTypePost"
  end
end

puts 'enter api manager name'
api_manager_name = gets.chomp

puts 'enter api manager path'
api_manager_path = gets.chomp

puts 'enter api manager method'
api_manager_method = get_method_type(gets.chomp) 

createHeader(api_manager_name)
createSource(api_manager_name, api_manager_path, api_manager_method)
