require 'rubygems'
require 'bundler'
ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)


require 'sinatra'
require 'ipaddr'


DATA_FOLDER = "assg_data"

GITHUB_ADDRS = %w{
	192.30.252.0/22
	2620:112:3000::/44
}.map{|addr| IPAddr.new addr}


def render_header?
	! request.path_info.start_with? "/view/"
end

def sanitize_path(path)
	return path.strip.split(/[\\\/]/).collect do |filename|
		# Strip out the non-ascii character
		filename.gsub!(/[^0-9A-Za-z.\-]/, '_')

		filename.start_with?(".") ? nil : filename
	end.join("/")
end

def get_filelist(path)
	Dir.entries(path).delete_if{|e| e.start_with? "."}
end

def validate_github
	GITHUB_ADDRS.any? {|block| block.include? request.ip}
end



get "/" do
	@files = get_filelist(DATA_FOLDER)
	slim :index
end

get "/about" do
	slim :about
end

get "/admin" do
	slim :admin
end

get "/view" do
	redirect_to "/"
end

get "/view/*" do |path|
	@path = sanitize_path(path)
	path = "#{DATA_FOLDER}/#{@path}"
	if File.directory? path
		@files = get_filelist path
		slim :view_list
	else
		if ENV['RACK_ENV'] == 'production'
			headers "X-Accel-Redirect" => "/#{path}"
		else
			File.open(path, "rb"){|f| f.read}
		end
	end
end



post "/github-webhook" do
	halt 403, 'Github Only!' unless validate_github
	EM.system('git -C #{DATA_FOLDER} pull') if env['HTTP_X_GITHUB_EVENT'] == "push"
end

=begin
# Testing wwwwww
get "/uploader" do
	slim :uploader
end

post "/uploader" do 
  File.open('upload/' + params['myfile'][:filename], "w") do |f|
    f.write(params['myfile'][:tempfile].read)
  end
  return "The file was successfully uploaded!"
end
=end
