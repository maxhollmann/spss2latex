require 'sinatra'
require 'statsmix'

require './config/statsmix'
require './spss2latex'

get '/' do
  StatsMix.track('Page views on SPSS2LaTeX', 1, {:meta => {"page" => "index"}})
  erb :index
end

post '/' do
  StatsMix.track('Page views on SPSS2LaTeX', 1, {:meta => {"page" => "convert"}})
  @latex = SPSS2Latex.convert(params[:tables])
  erb :convert
end
