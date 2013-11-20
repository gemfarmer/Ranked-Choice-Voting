console.log("fire index.js")
mongoose = require 'mongoose'
_ = require 'underscore'
toRender = {
	pageInfo: { title: 'Ranked Choice Voting' , subtitle: 'A Case Study'},
	chocolates: ["Milk Chocolate", "Dark Chocolate", "White Chocolate", "Snickers", "Twix", "Cadbury", "Milky Way", "Hershey's"]
	cakes: ["Chocolate", "Red Velvet", "Ice Cream", "Hot Milk", "Birthday", "Wedding", "Angel Food", "Cakelette"]
	fruits: ["Banana", "Lemon", "Grape", "Kiwi", "Watermelon", "Apple", "Orange", "Dragonfruit"]

}

# Set up Schema
Chocolate = mongoose.model 'Chocolate', {
	firstChoice: String
	secondChoice: String
	thirdChoice: String
	choices: Array or String
}

module.exports = {
	index: (req, res) ->
		# io.sockets.on 'connection', (socket) ->
		# 	console.log("index.js connected to sockets")
		
		
		res.render('index', toRender);
	chocolate: (req,res) ->
		data = req.query
		console.log("data:::",data)
		# data::: { type: [ 'Cadbury', 'Snickers', 'Milky Way' ] }
		vote = {
			firstChoice: data.type[0]
			secondChoice: data.type[1]
			thirdChoice: data.type[2]
			choices: toRender.chocolates
		} 
		# console.log("vote::::",vote)
		chocolate = new Chocolate(vote)
		chocolate.save (err,data) ->
			console.log("sent to database:",data)
	tabulate: (req,res) ->
		console.log("made it to routes.tabulate")
		Chocolate.find (err, votes) ->
			if(err)
				console.log('ERROR')
			else
				# console.log('votes', votes);

				mappedVotes = _.map votes, (vote) ->
					return (vote)
				# console.log("mappedVotes",mappedVotes)
				totalVotes = mappedVotes.length

				# First Round Tabulation
				histogram = _.groupBy(mappedVotes, 'firstChoice')
				# console.log("histogram", histogram)

				# Outputs Results
				mappedGram = _.map histogram, (grouping) ->
					# console.log("grouping", grouping)
					firstChoice = grouping[0].firstChoice
					secondChoice = grouping[0].secondChoice
					thirdChoice = grouping[0].thirdChoice
					percentage = (100*grouping.length)/totalVotes
					if percentage > 50
						message = "Winner!"
					else
						message = ""

					return {
						firstChoice: firstChoice
						secondChoice: secondChoice
						thirdChoice: thirdChoice
						votes: grouping.length
						percentage: percentage
						message: message
					}
				# Sorts results from last to first
				sortedMappedGram = _.sortBy mappedGram, (vote) ->
					return vote.votes

				# console.log("sorted", sortedMappedGram)
				# console.log(",MappedGram:::",mappedGram)

				# Find Votes to Remove. Returns Array of Choices to be removed
				findVotesToRemove = (prevRoundResults) ->
					fewestVotes = prevRoundResults[0].votes
					# console.log("fewest votes::",fewestVotes, fewestChoice)
					fewestVotesArray = _.where(prevRoundResults, {votes: prevRoundResults[0].votes})
					# console.log("fewestVotesArray", fewestVotesArray)
					remainingChoices = prevRoundResults.slice(fewestVotesArray.length, prevRoundResults.length)
					# console.log("remainingChoices",remainingChoices)

					if (remainingChoices[0].votes + fewestVotes) < remainingChoices[1].votes
						console.log("remove next")
						fewestVotesArray.push(_.where(prevRoundResults, {votes: remainingChoices[0].votes}))
					
					choicesToDrop = _.map fewestVotesArray, (choice) ->
						return choice.firstChoice
					return {choicesToDrop: choicesToDrop, remainingChoices: remainingChoices}
				console.log("findVotesToRemove",findVotesToRemove(sortedMappedGram))

				#Call Functions
				firstRoundLosers = findVotesToRemove(sortedMappedGram).choicesToDrop
				firstRoundWinners = findVotesToRemove(sortedMappedGram).remainingChoices

				realocateVotes = (AllVotes, firstRoundLosers, firstRoundWinners) ->

					matchedVotes = _.map firstRoundLosers, (vote) ->
						findSecondVotes = _.where AllVotes, {firstChoice: vote}
						console.log("findSecondVotes", findSecondVotes)
						secondVotes = _.each findSecondVotes, (choice) ->
							console.log("choice:::vote", choice, ":::",vote)
							if _.where firstRoundWinners, {firstChoice: vote}
								# console.log("matched", choice.secondChoice)
								return choice.secondChoice
							else
								thirdVotes = _.each findSecondVotes, (nextChoice) ->
									if _.where firstRoundWinners, {firstChoice: vote}
										return vote

								console.log("not matched. find third vote", vote)

					console.log("matchedVotes",matchedVotes)
					


				realocateVotes(mappedVotes, firstRoundLosers, firstRoundWinners)
				# Start Second Round Tabulation

				


				tabulatedObjectToRender = {
					title: "Tabulated Results", 
					choice : "chocolate"
					firstRoundResults: sortedMappedGram.reverse()
					secondRoundResults: "second round results"
				}
				# histogram = _.map mappedVotes[0].choices, (choice) ->
				# 	console.log "choice", choice
				# 	return _.where mappedVotes, {firstChoice: choice}
				# console.log("histogram",histogram)


				# mappedTwice = _.map mappedChoices, (choice) ->
				# 	return 

				# for choice in choices
				# 	console.log("vote::",choice.type)
				# 	_.first(choice.type)
				res.render('tabulate', tabulatedObjectToRender);
		
}