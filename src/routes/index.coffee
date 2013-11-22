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
				mappedVotes = _.map votes, (vote) ->
					return (vote)
				# console.log('votes', votes);
				collectVotes = (votes, additionalVotes) ->
					
					# console.log("votes",votes)
					totalVotes = votes.length

					# First Round Tabulation
					histogram = _.groupBy(votes, 'firstChoice')
					# console.log("histogram", histogram)

					# Outputs Results
					mappedGram = _.map histogram, (grouping) ->
						# console.log("grouping", grouping)

						percentage = (100*grouping.length)/totalVotes
						if percentage > 50
							message = "Winner!"
						else
							message = ""

						return {
							firstChoice: grouping[0].firstChoice
							secondChoice: grouping[0].secondChoice
							thirdChoice: grouping[0].thirdChoice
							votes: grouping.length
							percentage: percentage
							message: message
						}
					# Sorts results from last to first
					return sortedMappedGram = _.sortBy mappedGram, (vote) ->
						return vote.votes

				# console.log("sorted", sortedMappedGram)
				# console.log(",MappedGram:::",mappedGram)

				# Find Votes to Remove. Returns Object {droppedChoices, remainingChoices}
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
					
					droppedChoices = _.map fewestVotesArray, (choice) ->
						return choice.firstChoice
					return {droppedChoices: droppedChoices, remainingChoices: remainingChoices}
				console.log("findVotesToRemove",findVotesToRemove(collectVotes(mappedVotes)))

				#Call Functions
				firstRoundLosers = findVotesToRemove(collectVotes(mappedVotes)).droppedChoices
				firstRoundWinners = findVotesToRemove(collectVotes(mappedVotes)).remainingChoices

				#returns a list of votes that can be added to previous totals
				realocateVotes = (AllVotes, firstRoundLosers, firstRoundWinners) ->
					#Loop through Losers array. Perform action on loser
					console.log("firstRoundWinners", firstRoundWinners)

					matchedVotes = _.map firstRoundLosers, (loser) ->
						findSecondVotes = _.where AllVotes, {firstChoice: loser}
						# console.log("findSecondVotes", findSecondVotes)
						return secondVotes = _.map findSecondVotes, (choice) ->
							# console.log("choice:::loser", choice, ":::",loser)

							found = _.where firstRoundWinners, {firstChoice: choice.secondChoice} 
							# console.log("where:", {firstChoice: choice.secondChoice})
							# console.log("found", found)
							if found[0]
								# console.log("matched:", choice.secondChoice)
								return choice.secondChoice
							else
								# console.log("not matched. find third loser", loser)
								thirdVotes = _.map findSecondVotes, (nextChoice) ->
									foundAgain = _.where firstRoundWinners, {firstChoice: nextChoice.thirdChoice}
									# console.log("whereAgain:", {firstChoice: nextChoice.thirdChoice})
									# console.log("foundAgain", foundAgain)
									if foundAgain[0]
										# console.log("matchedAgain:", nextChoice.thirdChoice)
										return nextChoice.thirdChoice
									else
										# console.log("out of votes")
										return null


						# console.log("secondVotes",secondVotes)
						


					# console.log("matchedVotes",matchedVotes)
					flattenedMatchedVotes = _.flatten(matchedVotes)
					rejectNullVotes = _.reject flattenedMatchedVotes, (vote) ->
						return vote == null

					console.log(flattenedMatchedVotes, "rejects",rejectNullVotes)
				

					voteCount = {
						votes : rejectNullVotes.reduce (acc, curr) ->
							if (typeof acc[curr] == 'undefined')
								acc[curr] = 1;
							else
								acc[curr] += 1;
							return acc;
						, {}
					}

					console.log("voteCount", voteCount)
					


					
					


				realocateVotes(mappedVotes, firstRoundLosers, firstRoundWinners)

				collectVotes(mappedVotes)

				tabulatedObjectToRender = {
					title: "Tabulated Results", 
					list : "Chocolate"
					firstRoundResults: collectVotes(mappedVotes).reverse()
					secondRoundResults: collectVotes(mappedVotes).reverse()
				}
				
				res.render('tabulate', tabulatedObjectToRender);
		
}