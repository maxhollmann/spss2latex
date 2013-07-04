require 'sinatra'
require './spss2latex'


get '/' do
  erb :index
end

post '/' do
  @latex = SPSS2Latex.convert(params[:tables])
  erb :convert
end
