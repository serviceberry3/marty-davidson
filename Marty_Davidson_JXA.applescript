ObjC.import('stdlib');

//define globals
var app = Application.currentApplication(),
sa = (app.includeStandardAdditions = true, app),

buddies = Application('Messages').services["E:nssw088@gmail.com"].buddies,

//function shortcut for getting string with contents of a file
fileStr = function(path) {
	return $.NSString.stringWithContentsOfFile(path).js
	},

topPath = "/Users/nodog/Documents/Scripts/JavaMarty",

//load up the current release, intro, goodBye, valenText, scheduleInstr, reinitialize strings
currentRelease = fileStr(Path(topPath + '/currentRelease.txt').toString()),
intro = fileStr(Path(topPath + '/intro.txt').toString()),
goodBye = fileStr(Path(topPath + '/goodBye.txt').toString()),
valenText = fileStr(Path(topPath + '/valenText.txt').toString()),
scheduleInstr = fileStr(Path(topPath + '/scheduleInstr.txt').toString()),
reinitialize = fileStr(Path(topPath + '/reinitialize.txt').toString()),

//path for buddyList
buddyPath = topPath + '/Buddies.json';


class buddy {
	constructor(name, number, state) {
		this.name=name;
		this.number=number;
		this.state=state;
		this.timer=0;
	}
	
	setState(state) {
		this.state=state;
	}
}

//function to run a command on command line
function exec(program, args) {
	var command = program + " " + args.map(q).join("")
	console.log(command)
	$.system(command)
	
	function q(s) {
		return " '" + s.replace("'", "'\\''") + "' "
	}
}

function closeMessages() {
	exec("osascript", [topPath + '/closeMessages.scpt']);
}

//Handler calls this function upon receiving message in iMessage
function messageReceived(theMessage, eventDescription) {
	//find the Buddy
	var theBuddy = buddies[eventDescription.from.handle()];
	
	//get the buddy list from the JSON
	var buddyList = getBuddyList();
	if (!buddyList) {
		buddyList = [];
	}
	
	//function for searching array
	function searchForBuddy(buddy) {
		return (buddy.number.toString().localeCompare(this.handle())==0);
	}
	
	//search the list to see if the offending buddy is in it
	var inList = buddyList.find(searchForBuddy, theBuddy);
	
	
	//check if the user is attempting to opt in
	if (!theMessage.localeCompare("Opt in")) {
		if (inList) {
			//send buddy error message, already opted in
			sa.send("It looks like you already opted in. " + currentRelease, {to: theBuddy});
		}
		//if so, run an addBuddy
		else if (addBuddy(buddyList, theBuddy)<0) {
			return -1;
		}
		else {
			//send the intro text to the buddy
			sa.send(intro, {to: theBuddy});
		}

		closeMessages();
	}
	
	//if the buddy is in the list, pass to auxiliary function to parse request
	if (inList) {
		if (parseBuddyRequest(theMessage, buddyList, theBuddy)<0) {
			return -1;
		}
	}
	
	//update json and return
	var ret = $.NSString.alloc.initWithUTF8String(JSON.stringify(buddyList)).writeToFileAtomically(buddyPath, true);
	if (!ret) {
		genericError(Buddy);
		return -1;
	}
	return 0;
}

function parseBuddyRequest(theMessage, theList, theBuddy) {
	if (!theMessage.localeCompare("Opt out")) {
		//remove buddy from the list
		return removeBuddy(theList, theBuddy);
	}
}

function genericError(theBuddy) {
	sa.send("An error has occurrred. Please try again.", {to: theBuddy});
	//close messages window and return
	closeMessages();
	return 0;
}

//add new buddy to the list
function addBuddy(buddyList, Buddy) {
	//make a new buddy object to add to list
	var toAdd = new buddy(Buddy.name(), Buddy.handle(), "initial");

	//push new buddy onto the array
	buddyList.push(toAdd);
	
	//close messages window and return
	return 0;
}

//remove a specific buddy from the list
function removeBuddy(buddyList, Buddy){
	for (var i=0; i<buddyList.length; i++) {
		if (!buddyList[i].number.toString().localeCompare(Buddy.handle())) {
		//remove this buddy from the list
			buddyList.splice(i, 1);
			sa.send('Thanks, '+Buddy.name()+goodBye, {to: Buddy});
			closeMessages();
			return 0;
		}
	}
}

function getBuddyList() {
	//lets get the buddy list, if there is one already, or we'll initialize with default
	strPath = Path(buddyPath).toString();
	
	//initialize with recovered value or default of null
	var rawList = fileStr(strPath) || null;
	
	//return parsed buddyList or null if doesn't exist
	return JSON.parse(rawList) || null;
}

//helper function
function processMessage(message, fromWho, forWho) {
	var app=Application.currentApplication();
	app.includeStandardAdditions=true;
	app.displayDialog(fromWho.name());
}


//handle everything to avoid errors
function messageSent(message, event) {
}

function chatRoomMessageReceived(event) {
}

function activeChatMessageReceived(message, event) {
}

function addressedMessageReceived(message, b, c, event) {
}

function receivedTextInvitation(e) {
}

function receivedAudioInvitation(m, b, c, e) {
}

function receivedVideoInvitation(m, b, c, e) {
}

function receivedLocalScreenSharingInvitation(b, c, e) {
}

function buddyAuthorizationRequested(e) {
}

function addressedChatRoomMessageReceived(e) {
}

function receivedRemoteScreenSharingInvitation(e) {
}

function loginFinished(e) {
}

function logoutFinished(e) {
}

function buddyBecameAvailable(e) {
}

function buddyBecameUnavailable(e) {
}

function receivedFileTransferInvitation(e) {
}

function avChatStarted(e) {
}

function avChatEnded(e) {
}

function completedFileTransfer(e) {
}



