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
				mappedVotes = _.map votes, (vote) ->
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
					console.log("fewest votes::",fewestVotes)
					fewestVotesArray = _.where(prevRoundResults, {votes: prevRoundResults[0].votes})
					
					remainingChoices = prevRoundResults.slice(fewestVotesArray.length, prevRoundResults.length)
					

					if (remainingChoices[0].votes + fewestVotes) < remainingChoices[1].votes
						console.log("remove next")
						fewestVotesArray.push(_.where(prevRoundResults, {votes: remainingChoices[0].votes}))
					
					droppedChoices = _.map fewestVotesArray, (choice) ->
						return choice.firstChoice
					return {droppedChoices: droppedChoices, remainingChoices: remainingChoices}
				

				# Returns a list of votes that can be added to previous totals
				reallocateVotes = (AllVotes, firstRoundLosers, firstRoundWinners) ->
					#Loop through Losers array. Perform action on loser

					matchedVotes = _.map firstRoundLosers, (loser) ->
						findSecondVotes = _.where AllVotes, {firstChoice: loser}

						return secondVotes = _.map findSecondVotes, (choice) ->
							

							found = _.where firstRoundWinners, {firstChoice: choice.secondChoice} 
							
							if found[0]
								return choice.secondChoice
							else
								thirdVotes = _.map findSecondVotes, (nextChoice) ->
									foundAgain = _.where firstRoundWinners, {firstChoice: nextChoice.thirdChoice}

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

					#updates votes and percentage
					addVotes = (firstRoundWinners, voteCount) ->
						totalVotes = 0
						for choice in firstRoundWinners 
							for vote of voteCount
								
								if choice.firstChoice == vote
									choice.votes = choice.votes + voteCount[vote]

						#define Choices
						currentChoices = _.map firstRoundWinners, (choice) ->
							return choice.firstChoice

						for choice in firstRoundWinners 
							totalVotes += choice.votes
						for choice in firstRoundWinners 
							choice.percentage = (choice.votes*100)/totalVotes
							if choice.percentage > 50
								choice.message = "winner"
						return firstRoundWinners
						
					# produces an object firstRoundWInners with updated votes total
					return addVotes(firstRoundWinners, voteCount)

				
				#collect initial votes
				collectVotes(mappedVotes)

				# initialize object that will be rendered in the DOM
				tabulatedObjectToRender = {
					title: "Tabulated Results", 
					list : "Chocolate"
					firstRoundResults: collectVotes(mappedVotes).reverse()
				}

				next = true
				roundStatus = 1

				#update next
				for choice in findVotesToRemove(collectVotes(mappedVotes)).remainingChoices

					if choice.message == "winner"
						next = false
				

				# tallies second round
				secondRound = () ->

					# Define Winners and Losers
					firstRoundLosers = findVotesToRemove(collectVotes(mappedVotes)).droppedChoices
					firstRoundWinners = findVotesToRemove(collectVotes(mappedVotes)).remainingChoices


					reallocated = reallocateVotes(mappedVotes, firstRoundLosers, firstRoundWinners).sort().reverse()
					tabulatedObjectToRender.secondRoundResults = reallocated
					return reallocated
				
				followingRounds = () ->
					# Define Winners and Losers. Votes do not need "collectVotes" after first round
					roundLosers = findVotesToRemove(secondRound().reverse()).droppedChoices
					console.log("roundLosers",roundLosers)
					roundWinners = findVotesToRemove(secondRound().reverse()).remainingChoices
					console.log("roundWinners",roundWinners)

					reallocated = reallocateVotes(secondRound(), roundLosers, roundWinners).sort().reverse()
					tabulatedObjectToRender.nextRoundResults = reallocated
					# console.log("reallocated",reallocated)
					return reallocated
		
				# check for winner in first round
				if next
					roundStatus++
					second = secondRound()
					console.log("second", second)
					following = followingRounds()
					console.log "following", following
					# for choice in findVotesToRemove(secondRound()).remainingChoices

						# if choice.message == "winner"
						# 	next = false
						# 	if next
						# 		roundStatus++
						# 		followingRounds()
				
				res.render('tabulate', tabulatedObjectToRender);	
}