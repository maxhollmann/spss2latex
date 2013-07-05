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
  begin
    @latex = SPSS2Latex.convert(params[:tables])
  rescue Exception => e
    StatsMix.track('Exceptions on SPSS2LaTeX', 1, {:meta => {"page" => "convert", "input" => params[:tables], "message" => e.message}})
    @latex = "Sorry, I couldn't convert your table."
  end
  erb :convert
end
