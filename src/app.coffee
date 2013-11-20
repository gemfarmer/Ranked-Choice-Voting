
###
 # Module dependencies.
###
console.log("fire app.js")
express = require('express');
routes = require('./routes');
http = require('http');
path = require('path');
mongoose = require('mongoose')
socketio = require 'socket.io'

app = express();

# all environments
app.set('port', process.env.PORT or 3000);
app.set('views', __dirname + '/../views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, '/../public')));

# development only
if ('development' == app.get('env'))
	app.use(express.errorHandler());

# Define Server
server = http.createServer(app);

#Start the web socket server
io = socketio.listen(server);

# Connect Mongo DB
mongoURI = process.env.MONGOHQ_URL or 'mongodb://localhost/rankedvoting'
mongoose.connect(mongoURI)



app.get('/', routes.index);
app.post '/submitdata', (req,res) ->
	submitedInfo = req.body
	console.log("submitedInfo", submitedInfo)
	
	return
app.get '/chocolate', routes.chocolate 
app.get '/tabulate', routes.tabulate


server.listen(app.get('port'), () ->
	console.log('Express server listening on port ' + app.get('port'));
	return
);
