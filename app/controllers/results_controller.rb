class ResultsController < ApplicationController
  def index
    @results = Results.all
  end
end