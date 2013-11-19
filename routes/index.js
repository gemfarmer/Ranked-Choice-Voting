
/*
 * GET home page.
 */
toRender = {
	pageInfo: { title: 'Ranked Choice Voting' , subtitle: 'A Case Study'},
	candidates: ["Milk Chocolate", "Dark Chocolate", "White Chocolate", "Snickers", "Twix", "Cadbury", "Milky Way", "Hershey's"]
}
module.exports = function(io){
	index : function(req, res){
		io.sockets.on('connection', function(socket){
			console.log("index.js connected to sockets")
		})
		
		res.render('index', toRender);
	};
}