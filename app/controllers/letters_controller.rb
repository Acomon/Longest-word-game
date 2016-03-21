require 'open-uri'
require 'json'

class LettersController < ApplicationController
	def game
		@start_time = Time.now
		@grid = generate_grid
	end

	def score
		@grid = params[:grid].split("")
		@start_time = Time.parse(params[:start_time])
		@end_time = Time.now
		@attempt = params[:attempt]
		@result = run_game(@attempt, @grid, @start_time, @end_time)
	end



	private




	def generate_grid
		random = []
		9.times { random << ("a".."z").to_a.sample }
		random
	end

	def run_game(attempt, grid, start_time, end_time)
		results = {}
		results[:time] = end_time - start_time

		in_grid = in_grid(attempt, grid)

		results[:translation] = translation(attempt)

		if results[:translation].nil?
			results = not_english_word(results)
		elsif in_grid.include? "false"
			results = not_in_grid(results)
		else
			results[:score] = (attempt.size / results[:time]) * 10
			results[:message] = "well done"
		end
		results
	end

	def translation(attempt)
		api_url = "http://api.wordreference.com/0.8/80143/json/enfr/#{attempt}"
		open(api_url) do |stream|
			translation = JSON.parse(stream.read)

			unless translation["term0"].nil?
				if translation["term0"]["PrincipalTranslations"]["0"]["FirstTranslation"]["term"].nil?
					translation["term0"]["entries"]["0"]["FirstTranslation"]["term"]
				else
					translation["term0"]["PrincipalTranslations"]["0"]["FirstTranslation"]["term"]
				end
			end
		end
	end

	def in_grid(attempt, grid)
		attempt = attempt.downcase
		grid = grid.map(&:downcase)
		in_grid = ""
		other_grid = []
		attempt.split("").each do |letter|
			in_grid << "false" unless grid.include? letter
			in_grid << "false" if other_grid.include? letter
			other_grid << letter if grid.include? letter
		end
		in_grid
	end

	def not_in_grid(results)
		results[:score] = 0
		results[:message] = "not in the grid"
		results[:translation] = nil
		results
	end

	def not_english_word(results)
		results[:score] = 0
		results[:message] = "not an english word"
		results
	end


end
