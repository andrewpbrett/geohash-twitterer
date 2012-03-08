require 'rubygems'
require 'json'
require 'twitter'
require 'net/https'
require 'digest/md5'

keys = YAML::load( File.open( 'config.yml' ) )

def hexFracToDecFrac(hexFracPart)
	fracLen = hexFracPart.length
	fracPortion = hexFracPart[0..(fracLen-1)]
	fracLen = fracPortion.length
	myLen = (fracLen - 1)
	sum = 0	
	for i in (0 .. myLen)
		numSixteenths = fracPortion[i..i].to_i(16)
		conversionFactor = (16.**(i+1)).to_f
		conversionFactor = 1./conversionFactor
		sum = sum + ((numSixteenths) * conversionFactor)
	end
	return sum.to_s[2..8]
end

date  = Date.today
dow   = Net::HTTP.get "carabiner.peeron.com", "/xkcd/map/data/#{date.strftime "%Y/%m/%d"}"
md5   = Digest::MD5.hexdigest "#{date.strftime "%Y-%m-%d-"}" + dow
md51  = md5[0, 16]
md52  = md5[16, 31]

lat   = keys['lat']  + "." + hexFracToDecFrac(md51)
long  = keys['long'] + "." + hexFracToDecFrac(md52)

https = Net::HTTP.new('maps.googleapis.com', 443)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
path = "/maps/api/place/search/json?location=#{lat},#{long}&radius=5000&sensor=false&key=AIzaSyBf6VsyAL-Kp78H-OVvZbTGGSZwO-x0KLI"
response = https.request_get(path)

json = JSON[response.read_body]
vicinity  = json['results'][0]['vicinity']
name      = json['results'][0]['name']

tweet = "Today's geohash: #{lat}, #{long} - near #{name} in #{vicinity}: http://maps.google.com/maps?q=#{lat},#{long}"

Twitter.configure do |config|
  config.consumer_key       = keys['consumer_key']
  config.consumer_secret    = keys['consumer_secret']
  config.oauth_token        = keys['oauth_token']
  config.oauth_token_secret = keys['oauth_token_secret']
end
puts tweet
# Twitter.update tweet