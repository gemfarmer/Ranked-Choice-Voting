console.log("main.js fired")

//connect to socket server
socket = io.connect();

$(function(){
	console.log('document ready!')
	socket.on('connect', function(){
		console.log('main.js connected to sockets')
		

		$('#chocolateform').on('change', function(){
			console.log("this",this)
			console.log("$this", $(this))
			val = $(this).serialize()
			console.log(val)
		})
		$(document).on('click', function(){
			console.log("click")
		})
	})
});