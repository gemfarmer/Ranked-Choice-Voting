console.log("fire main.js")
socket = io.connect();
$ ->
	socket.on 'connect', () ->
		console.log('document ready!')
		# socket.on 'connect', () ->
		# 	console.log('main.js connected to sockets')
			
		$('#chocButton').on 'click', (e) ->
			e.preventDefault()
			console.log("this",this)
			console.log("$this", $(this))
			val = $('#chocolateform').serialize()
			console.log(val)

			$.get '/chocolate', val, (data) ->
				console.log(data)
				res.send(data)

		$('#cakeform').on 'change', () ->
			console.log("this",this)
			console.log("$this", $(this))
			val = $(this).serialize()
			console.log(val)
		$('#fruitform').on 'change', () ->
			console.log("this",this)
			console.log("$this", $(this))
			val = $(this).serialize()
			console.log(val)
		
		$(document).on 'click', () ->
			console.log("click")


