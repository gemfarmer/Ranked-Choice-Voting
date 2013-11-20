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
		console.log("vote::::",vote)
		chocolate = new Chocolate(vote)
		chocolate.save (err,data) ->
			console.log("sent to database:",data)
	tabulate: (req,res) ->
		console.log("made it to routes.tabulate")
		Chocolate.find (err, votes) ->
			if(err)
				console.log('ERROR')
			else
				console.log('votes', votes);

				mappedVotes = _.map votes, (vote) ->
					return (vote.firstChoice)
				console.log("mappedVotes",mappedVotes.sort())
				# mappedTwice = _.map mappedChoices, (choice) ->
				# 	return 

				# for choice in choices
				# 	console.log("vote::",choice.type)
				# 	_.first(choice.type)
				res.render('tabulate', {title: "Tabulated Results", choice : "chocolate"});
		
}