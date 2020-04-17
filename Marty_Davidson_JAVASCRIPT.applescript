//Handler calls this function upon receiving message in iMessage
function messageReceived(theMessage, eventDescription) {
	processMessage("message received", theMessage, eventDescription.from, eventDescription.for);
}


//helper function
function processMessage(message, event) {
	var app=Application.currentApplication();
	app.includeStandardAdditions=true;
	app.displayDialog("Hello World");
}

