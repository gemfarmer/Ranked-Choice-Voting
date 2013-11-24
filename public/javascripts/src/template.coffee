$ ->

	source = $("#search-results-template").html();
	dataTemplate = Handlebars.compile(source);
	$results = $('#template-results')
	# $.get 'nextRound', (data) ->
	# 	if data.next
	$results.html(dataTemplate(output))
