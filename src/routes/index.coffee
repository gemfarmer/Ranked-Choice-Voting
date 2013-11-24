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

		chocolate = new Chocolate(vote)
		chocolate.save (err,data) ->
			console.log("sent to database:",data)
	tabulate: (req,res) ->
		console.log("made it to routes.tabulate")
		Chocolate.find (err, votes) ->
			if(err)
				console.log('ERROR')
			else
				allVotes = _.map votes, (vote) ->
					return (vote)

			
				# collects votes. Takes votes (array of {firstChoice:, secondChoice:, thirdChoice: votes: []})
				collectVotes = (votes) ->
					
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
							message = "winner"
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

				# Find Votes to Remove. 
				# Takes object {firstChoice:"", secondChoice:"", thirdChoice:"", votes:[], percentage:Num, message:""}
				# Returns Object {droppedChoices, remainingChoices}
				findVotesToRemove = (prevRoundResults) ->
					fewestVotes = prevRoundResults[0].votes
					
					fewestVotesArray = _.where(prevRoundResults, {votes: prevRoundResults[0].votes})
					
					remainingChoices = prevRoundResults.slice(fewestVotesArray.length, prevRoundResults.length)
					

					if (remainingChoices[0].votes + fewestVotes) < remainingChoices[1].votes
						console.log("remove next")
						fewestVotesArray.push(_.where(prevRoundResults, {votes: remainingChoices[0].votes}))
					
					droppedChoices = _.map fewestVotesArray, (choice) ->
						return choice.firstChoice
					return {droppedChoices: droppedChoices, remainingChoices: remainingChoices}
				

				# Returns a list of votes that can be added to previous totals
				reallocateVotes = (AllVotes, losersList, winnersList) ->
					#Loop through Losers array. Perform action on loser
					matchedVotes = _.map losersList, (loser) ->
						findSecondVotes = _.where AllVotes, {firstChoice: loser}

						return secondVotes = _.map findSecondVotes, (choice) ->
							

							found = _.where winnersList, {firstChoice: choice.secondChoice} 
							
							if found[0]
								return choice.secondChoice
							else
								thirdVotes = _.map findSecondVotes, (nextChoice) ->
									foundAgain = _.where winnersList, {firstChoice: nextChoice.thirdChoice}

									if foundAgain[0]
										return nextChoice.thirdChoice
									else
										return null


					flattenedMatchedVotes = _.flatten(matchedVotes)
					rejectNullVotes = _.reject flattenedMatchedVotes, (vote) ->
						return vote == null
				

					voteCount = rejectNullVotes.reduce (acc, curr) ->
							if (typeof acc[curr] == 'undefined')
								acc[curr] = 1;
							else
								acc[curr] += 1;
							return acc;
						, {}
					console.log("voteCount", voteCount)

					#updates votes and percentage
					addVotes = (winnersList, voteCount) ->
						totalVotes = 0
						for choice in winnersList 
							for vote of voteCount
								
								if choice.firstChoice == vote
									choice.votes = choice.votes + voteCount[vote]

						#define Choices
						currentChoices = _.map winnersList, (choice) ->
							return choice.firstChoice

						for choice in winnersList 
							totalVotes += choice.votes
						for choice in winnersList 
							choice.percentage = (choice.votes*100)/totalVotes
							if choice.percentage > 50
								choice.message = "winner"
						console.log("winnersList", winnersList)

						return winnersList

						
					# produces an object winnersList with updated votes total
					return addVotes(winnersList, voteCount)

				
				# Collect initial votes
				collectVotes(allVotes)

				# initialize object that will be rendered in the DOM
				tabulatedObjectToRender = {
					title: "Tabulated Results", 
					list : "Chocolate"
					firstRoundResults: collectVotes(allVotes).reverse()
				}

				next = true
				roundStatus = 1

				#update next
				for choice in findVotesToRemove(collectVotes(allVotes)).remainingChoices

					if choice.message == "winner"
						next = false
				

				# tallies second round
				secondRound = () ->

					# Define Winners and Losers
					firstRoundLosers = findVotesToRemove(collectVotes(allVotes)).droppedChoices
					firstRoundWinners = findVotesToRemove(collectVotes(allVotes)).remainingChoices


					reallocated = reallocateVotes(allVotes, firstRoundLosers, firstRoundWinners).sort().reverse()
					return reallocated
				
				followingRounds = () ->
					# Define Winners and Losers. Votes do not need "collectVotes" after first round
					roundResults = findVotesToRemove(secondRound().reverse())
					# console.log("roundResults",roundResults)
					roundLosers = findVotesToRemove(secondRound().reverse()).droppedChoices
					# console.log("roundLosers",roundLosers)
					roundWinners = findVotesToRemove(secondRound().reverse()).remainingChoices
					# console.log("roundWinners",roundWinners)

					reallocated = _.sortBy reallocateVotes(allVotes, roundLosers, roundWinners), (obj) ->
						return obj.votes
					return reallocated.reverse()
		
				# check for winner in first round
				if next
					roundStatus++
					tabulatedObjectToRender.secondRoundResults = secondRound()
					for choice in secondRound()
						console.log(choice)
						if choice.message == "winner"
							console.log("no winner")
							next = false
							if next
								console.log("no_winner")
						else
							roundStatus++
							# app.get '/nextRound', (req,res) ->
							# 	res.send({next: true})
							tabulatedObjectToRender.nextRoundResults = followingRounds()
					# secondRound()
					# console.log("tabulated", tabulatedObjectToRender)

					# console.log "following", following
					

						
						# 		followingRounds()
				console.log 'tabulate', tabulatedObjectToRender
				
				res.render('tabulate', tabulatedObjectToRender);	
}