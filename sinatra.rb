require 'rubygems'
require 'sinatra'
require 'statsmix'

require './config/statsmix'
require './spss2latex'

get '/' do
  StatsMix.track('Page views on SPSS2LaTeX', 1, {:meta => {"page" => "index"}}) if StatsMix.api_key
  erb :index
end

post '/' do
  StatsMix.track('Page views on SPSS2LaTeX', 1, {:meta => {"page" => "convert"}}) if StatsMix.api_key
  begin
    @latex = SPSS2Latex.convert(params[:tables])
  rescue Exception => e
    StatsMix.track('Exceptions on SPSS2LaTeX', 1, {:meta => {"page" => "convert", "input" => params[:tables], "message" => e.message}}) if StatsMix.api_key
    @latex = "Sorry, I couldn't convert your table."
  end
  erb :convert
end
