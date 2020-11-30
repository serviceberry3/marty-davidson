//
//  Parser.swift
//  MartyDavidson
//
//  Created by Noah Weiner on 29/11/2020.
//  Copyright © 2020 Noah Weiner. All rights reserved.
//

import Foundation



class Parser {
    
    var ourMarty: RavenSender?
    init(ourMarty: RavenSender?) {
        guard let martyReceived = ourMarty else {
            return
        }
        
        self.ourMarty = martyReceived
        
    }
    
    deinit {
        
    }
    
    func parse(message: Scroll?) {
        print((message?.body as? TextBody)!.message)
        
        
        ourMarty?.send(message!)
    }
    
    
    //load up the current release, intro, goodBye, valenText, scheduleInstr, reinitialize strings
    var currentRelease = MartyConstants.currentRelease
    var intro = MartyConstants.intro
    var goodBye = MartyConstants.goodBye
    var valenText = MartyConstants.valenText
    var scheduleInstr = MartyConstants.scheduleInstr
    var reinitialize = MartyConstants.reinitialize
    var valenError = MartyConstants.valenError
    
    
    /*
    //path for buddyList
    buddyPath = topPath + '/Buddies.json';
    datePath = topPath+ '/Date.json';
    
    
    
    
    
    //function to run a command on command line
    function exec(program, args) {
    //var command = program + " " + args.map(q).join("")
    var command = program + " " + args;
    console.log(command)
    $.system(command)
    
    function q(s) {
    return " '" + s.replace("'", "'\\''") + "' "
    }
    }
    
    function closeMessages() {
    exec("osascript", [topPath + '/closeMessages.scpt']);
    }
    
    function secondsAfterMidnight() {
    var today = new Date(),
    hours=today.getHours(),
    minutes=today.getMinutes(),
    seconds=today.getSeconds();
    return hours*360 + minutes*60 + seconds;
    }
    
    //Handler calls this function upon receiving message in iMessage
    function messageReceived(theMessage, eventDescription) {
    
    //find the Buddy
    var theBuddy = buddies[eventDescription.from.handle()],
    
    //convert messages text to lowercase for locale comparing
    theMessage = theMessage.toLowerCase(),
    
    //get the buddy list from the JSON
    buddyList = getBuddyList();
    
    if (!buddyList) {
    buddyList = [];
    }
    
    //function for searching array
    function searchForBuddy(buddy) {
    return (buddy.number.toString()==this.handle());
    }
    
    //search the list to see if the offending buddy is in it
    var buddyInList = buddyList.find(searchForBuddy, theBuddy);
    
    
    //check if the user is attempting to opt in
    if (theMessage=="opt in") {
    if (buddyInList!=undefined) {
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
    if (buddyInList!=undefined) {
    if (parseBuddyRequest(theMessage, buddyList, theBuddy, buddyInList)<0) {
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
    
    function parseBuddyRequest(theMessage, theList, theOgBuddy, theHomemadeBuddy) {
    if (theMessage=="opt out") {
    //remove buddy from the list
    return removeBuddy(theList, theOgBuddy);
    }
    else if (theMessage=="marty") {
    theHomemadeBuddy.state="marty";
    theHomemadeBuddy.timer=secondsAfterMidnight();
    sa.send(currentRelease, {to: theOgBuddy});
    closeMessages();
    }
    else if (theHomemadeBuddy.state=="marty") {
    if (theMessage=="urgent") {
    urgentHandle(theOgBuddy, theHomemadeBuddy);
    }
    else if (theMessage=="minions") {
    minionHandle(theOgBuddy, theList);
    }
    else if (theMessage=="valentine") {
    valenHandle(theOgBuddy, theHomemadeBuddy);
    }
    else if (theMessage=="cita") {
    enterScheduler(theOgBuddy, theHomemadeBuddy);
    }
    }
    else if ((theHomemadeBuddy.state=="cita" || theHomemadeBuddy.state=="citamail") && theMessage=="exit") {
    theHomemadeBuddy.state="initial";
    sa.send(reinitialize, {to: theOgBuddy});
    closeMessages();
    }
    else if (theHomemadeBuddy.state=="cita") {
    dateCheck(theMessage, theOgBuddy, theHomemadeBuddy);
    }
    else if (theHomemadeBuddy.state=="citamail") {
    terminarCita(theMessage, theOgBuddy, theHomemadeBuddy);
    }
    }
    
    function terminarCita(theMessage, theOgBuddy, theHomemadeBuddy) {
    //sa.displayDialog(storeDate);
    var start = fileStr(datePath),
    
    end = start,
    Calendar = SystemEvents.processes['Calendar'],
    CalendarApp=Application('Calendar');
    
    var strin = topPath + '/calendar.scpt'+" "+start+" "+'"'+theMessage+'"';
    exec("osascript", [strin]);
    
    sa.send("Great, "+theHomemadeBuddy.name+". I've scheduled a one-hour appointment with you for " +start+ ". You should receive an email about it shortly. Seeya then! You should dress in formal attire and be punctual.", {to: theOgBuddy});
    closeMessages();
    theHomemadeBuddy.state="marty";
    return 0;
    }
    
    function dateReceived(theOgBuddy, theHomemadeBuddy) {
    sa.send("Got it. Next, please enter your email address.", {to: theOgBuddy});
    theHomemadeBuddy.state="citamail";
    closeMessages();
    return 0;
    }
    
    function dateCheck(theMessage, theOgBuddy, theHomemadeBuddy) {
    theMessage=theMessage.toUpperCase();
    storeDate = new Date(theMessage);
    if (storeDate=='Invalid Date') {
    sa.send("I can't accept that format. Please try again, or type \"exit\" to exit the scheduler.", {to: theOgBuddy});
    closeMessages();
    return -1;
    }
    storeDate = storeDate.toString();
    $.NSString.alloc.initWithUTF8String(JSON.stringify(storeDate)).writeToFileAtomically(datePath, true);
    return dateReceived(theOgBuddy, theHomemadeBuddy);
    }
    
    function enterScheduler(theOgBuddy, theHomemadeBuddy) {
    sa.send(scheduleInstr, {to: theOgBuddy});
    theHomemadeBuddy.state="cita";
    closeMessages();
    return 0;
    }
    
    function valenHandle(theOgBuddy, theHomemadeBuddy) {
    Facetime = SystemEvents.processes['FaceTime'],
    FacetimeApp = Application('Facetime'),
    phone_num = theHomemadeBuddy.number,
    mesg_text = "Hello, "+ theHomemadeBuddy.name + valenText;
    
    try {
    closeMessages();
    exec("open facetime://" + phone_num, []);
    FacetimeApp.activate();
    
    //wait until window loads
    while (!Facetime.windows[0].buttons["Cancel"].exists()) {
    ;
    }
    
    //call the buddy
    Facetime.windows[0].buttons["Call"].click();
    delay(1);
    if (Facetime.windows[0].buttons["Cancel"].exists()) {
    //invalid number, so error out
    sa.send(valenError, {to: theOgBuddy});
    closeMessages();
    return -1;
    }
    
    //we assume buddy will pick up call
    
    delay(16);
    
    /*
     //wait for connection
     while (!Facetime.windows[0].buttons["End"].exists()) {
     ;
     }
     */
    
    exec("say",[mesg_text]);
    delay(1);
    Facetime.windows[0].buttons["End"].click();
    }
    catch (err) {
    sa.send(valenError, {to: theOgBuddy});
    closeMessages();
    return -1;
    }
    closeMessages();
    return 0;
    }
    
    function minionHandle(theOgBuddy, theList) {
    sa.send("Here is my current list of contacts:", {to: theOgBuddy});
    for (var i=0; i<theList.length; i++) {
    sa.send(theList[i].name, {to: theOgBuddy});
    }
    closeMessages();
    return;
    }
    
    function urgentHandle(theOgBuddy, theHomemadeBuddy) {
    var name = theHomemadeBuddy.name;
    if (secondsAfterMidnight() < theHomemadeBuddy.timer+60) {
    sa.send("You've angered me, " + name + "!", {to: theOgBuddy});
    closeMessages();
    return;
    }
    sa.send("My patience for your urgency has run out, "+ name + ". I have reinitialized. You'll have to summon me again.", {to: theOgBuddy});
    theHomemadeBuddy.state="initial";
    closeMessages();
    return;
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
    if (buddyList[i].number==Buddy.handle()) {
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

    */
    
}
