source = $("#search-results-template").html();
dataTemplate = Handlebars.compile(source);
$results = $('#template-results')