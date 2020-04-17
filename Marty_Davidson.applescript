(*Marty Davidson, a state-machine-based iMessage auto-reply robot. ©2020 Noah Weiner. This is free software, and its distribution, replication,
and modification is permitted.*)

use AppleScript version "2.4"
use scripting additions

(*current capability information*)
set currentRelease to "Many more features are coming soon! For now, try texting me a message containing \"urgent\" within the next 60 seconds to ignite me! Or text me a message containing \"minions\" to fetch a list of all of the contacts on my list, along with their phone numbers. You can text a message containing \"cita\" to start scheduling an appointment with me, or text a message containing \"valentine\" for a special surprise. Text a message containing \"lights\" to control the lights in Noah's room!"

set intro to "Hi! I'm Marty, Noah's iMessage auto-reply bot. It appears as though either we've never met, or my software has been updated since we last talked. I've just added you to my list of contacts. To remove yourself from my list at any time, text me any message containing \"opt out\". To opt back in after opting out, text me any message containing \"opt in\". Try texting me a message containing \"marty\" to get started! And if I ever seem idle, just send any message containing \"marty\" to wake me back up!"

set goodBye to "! I have removed you from my list. Remember, to opt back in at any time, just text me any message containing \"opt in\". Seeya around!"

set valenText to ". Happy Valentine's Day! Marty hopes that you have a wonderful day. The call will be ended momentarily."

set scheduleInstr to "To schedule an appointment with me, please start by sending me a text with your desired appointment date and time in the format MM DD YY HH:MM:SS XM. You can omit seconds if they are unimportant to you."


using terms from application "Messages"
	(*This function essentially creats a subscript for each "buddy" (contact) that's added to Marty's list. It's basically
	like a class in Java. The "class" has three properties: the contact info, the contact's current state in the state machine,
	and a timer which can be reset but is useful for things like urgent timeout.*)
	
	on createBuddy(theBuddy, initialState)
		script makeBuddy
			property info : null
			property myname : null
			property state : null
			property timer : null
			property addy : null
			
			(*Get the contact's info, which contains an ID containing the contact's name and full phone number formatted +xxxxxxxxxxx*)
			on getInfo()
				return info
			end getInfo
			
			on getName()
				return myname
			end getName
			
			on getAddy()
				return addy
			end getAddy
			
			(*Get the current state that the contact is in in Marty's state machine.*)
			on getState()
				return state
			end getState
			
			(*The following three functions in a Buddy script are similar to constructor helper functions in Java and set up the Buddy's
			information. They could potentially be combined into one function, but I separated them for convenience. They exist
			so that the contact's info, state, and timer can be modified at any time, not just upon the contact's creation.*)
			on setInfo(theBuddy)
				set info to theBuddy
			end setInfo
			
			on setName(requestedName)
				set myname to requestedName
			end setName
			
			(*Here we have functions to set a contact's state and timer.*)
			on setState(requestedState)
				set state to requestedState
			end setState
			
			on setTimer(requestedTime)
				set timer to requestedTime
			end setTimer
			
			on setAddy(requestedAddy)
				set addy to requestedAddy
			end setAddy
			
			(*Here we have functions to get a contact's timer or get it's state or name as strings.*)
			on getTimer()
				return timer
			end getTimer
			
			on getStringState()
				return state as string
			end getStringState
			
			on getStringName()
				return info's name as string
			end getStringName
		end script
		
		(*This "talks" to the script (class) and invokes the construction process, i.e., if Buddy were a class in Java,
		this would be the equivalent of completing new Buddy(buddy's info, initial state). So this is essentially the
		constructor*)
		tell makeBuddy
			setInfo(theBuddy)
			try
				setAddy(theBuddy's handle as string)
			on error
				setAddy(text -12 thru -1 of (theBuddy's id as string))
			end try
			setState(initialState)
			#display dialog (theBuddy's first name as string)
			if theBuddy's first name as string = "missing value" then
				setName("UNKNOWN CONTACT")
			else
				setName(theBuddy's first name as string)
			end if
		end tell
		
		(*Finishes making the "new" buddy and returns the entire buddy object from the function.*)
		return makeBuddy
	end createBuddy
	
	(*This is a PROPERTY of this entire AppleScript, meaning it has a lifetime that is tied to this entire
	script. I.e., the buddyList will only die and be reset upon recompilation of the script. This is very useful,
	and this script's buddyList can even be extracted by other scripts for different purposes.*)
	property buddyList : {}
	
	(*We'll use this property to temporarily store dates.*)
	property storeDate : "mercredi 12 décembre 2012 à 00:00:00"
	
	(*A generic message sender for convenience: inputs are the buddy (whole thing) and the text to send*)
	on reply1(name, parameter)
		send parameter to name
		tell application "Messages" to close windows
	end reply1
	
	
	(*This handler assumes state is initial, and tells the buddy object to go to urgent. The "normal"
	version handles any text that's a response in the initial state, while the "non-normal" version
	handles a duplicate opt-in.*)
	on handler1(theBuddy, version, theScript)
		tell theScript
			setState("urgent")
			setTimer(time of (current date))
		end tell
		if version = "normal" then
			send "Hey again! It's Marty." & currentRelease to theBuddy
		else
			send "It looks like you already opted in." & currentRelease to theBuddy
		end if
		tell application "Messages" to close windows
	end handler1
	
	(*Displays text after adding a new member to the buddyList.*)
	on newMember(theBuddy)
		send intro to theBuddy
		tell application "Messages" to close windows
	end newMember
	
	(*Removes a member from the buddyList and then closes up the list. Worst-case (big-O) runtime is unknown, but 
	I will say that, after a removal, it just merges the first and second pieces of the list together/patches list up.*)
	on removeMember(theBuddy)
		repeat with a from 1 to length of buddyList
			set current to item a of buddyList
			set check to current's getStringName()
			if check = theBuddy's name as string then
				if length of buddyList = 1 then
					set buddyList to {}
					send "Thanks, " & current's getName() & goodBye to theBuddy
				else if a = 1 then
					set buddyList to rest of buddyList
					send "Thanks, " & current's getName() & goodBye to theBuddy
				else if a = length of buddyList then
					set buddyList to reverse of rest of reverse of buddyList
					send "Thanks, " & current's getName() & goodBye to theBuddy
				else
					set buddyList to items 1 thru (a - 1) of buddyList & items (a + 1) thru -1 of buddyList
					send "Thanks, " & current's getName() & goodBye to theBuddy
				end if
			end if
		end repeat
		tell application "Messages" to close windows
	end removeMember
	
	(*In the urgent state, this handler prints output, including a special one if 60 seconds have
	passed, and then sets state back to initial.*)
	on urgentHandle(theBuddy, theScript)
		if time of (current date) < (theScript's getTimer()) + 60 then
			send ("You've angered me, " & theScript's getName()) & "!" to theBuddy
			tell theScript
				setState("urgent")
			end tell
		else
			send ("My patience for your urgency has run out, " & theScript's getName()) & ". I have reinitialized. You'll have to summon me again." to theBuddy
			tell theScript
				setState("initial")
			end tell
		end if
		tell application "Messages" to close windows
	end urgentHandle
	
	(*As requested, this handler goes through the buddyList and prints out each contact's name and number.
	Still haven't figured out how to extract that number without just indexing part of the buddy's ID.*)
	on minionHandle(theBuddy, theScript)
		send ("Here is my current list of contacts:") to theBuddy
		delay 1.5
		repeat with a from 1 to length of buddyList
			set current to item a of buddyList
			send current's getName() & ": " & current's getAddy() to theBuddy
		end repeat
		tell application "Messages" to close windows
	end minionHandle
	
	(*Special Valentine's Day feature! From the initial state menu, user can type "valentine"
	and then they are FaceTimed, Marty recites his sweet little ode, and then ends call.*)
	on valenHandle(theBuddy, theScript)
		try
			tell application "Messages" to close windows
			set phone_num to theScript's getAddy()
			do shell script "open facetime://" & quoted form of phone_num
			tell application "System Events" to tell process "FaceTime"
				set frontmost to true
				tell window 1
					repeat while not (button "Call" exists)
						delay 1
					end repeat
					if button "Call" exists then
						click button "Call"
					end if
					delay 1
					if button "Cancel" exists then
						valenError(theBuddy)
					end if
				end tell
			end tell
			set mesg_text to ("Hello, " & theBuddy's name as string) & valenText
			delay 18
			do shell script "say " & quoted form of mesg_text
			delay 1
			tell application "System Events" to tell process "FaceTime"
				tell window 1
					if button "End" exists then
						click button "End"
					end if
				end tell
			end tell
			
			(*Check for errors with the valentine*)
		on error
			valenError(theBuddy)
		end try
		tell application "Messages" to close windows
	end valenHandle
	
	(*valentine error out*)
	on valenError(theBuddy)
		send "An error has ocurred with your valentine. Please try again. Please pick up my FaceTime call right away." to theBuddy
	end valenError
	
	(*enter the scheduling function*)
	on enterScheduler(theBuddy, theScript)
		send scheduleInstr to theBuddy
		tell theScript
			setState("cita")
		end tell
		tell application "Messages" to close windows
	end enterScheduler
	
	(*received correctly formatted meeting date/time*)
	on dateReceived(theBuddy, theScript)
		send "Got it. Next, please enter your email address." to theBuddy
		tell theScript
			setState("citamail")
		end tell
		tell application "Messages" to close windows
	end dateReceived
	
	
	(*A handler for the appointment creator.*)
	on terminarCita(theBuddy, theScript, theEmail)
		set theStartDate to storeDate
		set theEndDate to theStartDate + 3600
		tell application "Calendar"
			tell calendar "martyishuge@gmail.com"
				set theEvent to make new event with properties {summary:"Meeting with Marty", start date:theStartDate, end date:theEndDate}
				tell theEvent
					make new attendee at end of attendees with properties {email:theEmail}
				end tell
			end tell
		end tell
		send "Great, " & theScript's getName() & ". I've scheduled a one-hour appoinment with you for " & (storeDate as string) & ". You should receive an email about it shortly. Seeya then! You should dress in formal attire and be punctual." to theBuddy
		tell theScript
			setState("urgent")
		end tell
		tell application "Messages" to close windows
	end terminarCita
	
	on lightOptions(theBuddy, theScript)
		send "You can change the lights in Noah's room! The current options are \"blackout\" (off), \"red\", \"rainbow\", \"blue\", and \"green\". Send me a message containing any of these words to change the lights!" to theBuddy
	end lightOptions
	
	
	(*This is the "main" function: it examines ALL incoming messages and routes them to the
	appropriate handler functions. It also adds member to buddyList on opting in.*)
	on message received theMessage from theBuddy for theChat with theMessageText
		#display dialog handle of theBuddy as string
		set found to false
		set verified to false
		repeat with a from 1 to length of buddyList
			set current to item a of buddyList
			set check to current's getStringName()
			if check = theBuddy's name as string then
				set found to true
				
				if theMessageText contains "opt out" then
					removeMember(theBuddy)
					exit repeat
				else if theMessageText contains "opt in" then
					handler1(theBuddy, "mistake", current)
					exit repeat
				else if current's getStringState() = "urgent" and theMessageText contains "urgent" then
					urgentHandle(theBuddy, current)
					exit repeat
				else if current's getStringState() = "urgent" and theMessageText contains "minions" then
					minionHandle(theBuddy, current)
					exit repeat
				else if current's getStringState() = "urgent" and theMessageText contains "valentine" then
					valenHandle(theBuddy, current)
					exit repeat
				else if current's getStringState() = "urgent" and theMessageText contains "cita" then
					enterScheduler(theBuddy, current)
					exit repeat
				else if current's getStringState() = "urgent" and theMessageText contains "lights" then
					lightOptions(theBuddy, current)
					exit repeat
				else if current's getStringState() = "cita" and theMessageText contains "exit" then
					tell current
						setState("initial")
					end tell
					send "I have reinitialized. Summon me again for a good time." to theBuddy
					tell application "Messages" to close windows
					exit repeat
				else if current's getStringState() = "cita" then
					#display dialog theMessageText
					try
						set storeDate to (date theMessageText)
						tell application "Messages" to close windows
						dateReceived(theBuddy, current)
					on error
						send "I can't accept that format. Please try again, or type \"exit\" to exit the scheduler." to theBuddy
						tell application "Messages" to close windows
					end try
					exit repeat
				else if current's getStringState() = "citamail" and theMessageText contains "exit" then
					tell current
						setState("initial")
					end tell
					send "I have reinitialized. Summon me again for a good time." to theBuddy
					exit repeat
				else if current's getStringState() = "citamail" then
					terminarCita(theBuddy, current, theMessageText)
					exit repeat
				else if (current's getStringState() = "initial" or current's getStringState() = "urgent") and theMessageText contains "marty" then
					handler1(theBuddy, "normal", current)
					exit repeat
					
				else if theMessageText contains "rainbow" then
					send "Please wait..." to theBuddy
					try
						do shell script "/Users/nodog/Downloads/arduino-cli upload -p /dev/cu.usbmodem621 --fqbn arduino:avr:mega ~/Documents/Arduino/NoahColorPalette"
					on error
						send "An error occurred. Please try again." to theBuddy
					end try
					send "I changed the lights in Noah's room to rainbow." to theBuddy
					tell application "Messages" to close windows
				else if theMessageText contains "blackout" then
					send "Please wait..." to theBuddy
					try
						do shell script "/Users/nodog/Downloads/arduino-cli upload -p /dev/cu.usbmodem621 --fqbn arduino:avr:mega ~/Documents/Arduino/BlackOut"
					on error
						send "An error occurred. Please try again." to theBuddy
					end try
					send "I changed the lights in Noah's room to blackout." to theBuddy
					tell application "Messages" to close windows
				else if (length of theMessageText ≥ 3) and theMessageText contains " red" or (text 1 of theMessageText contains "r" and text 2 of theMessageText contains "e" and text 3 of theMessageText contains "d") then
					send "Please wait..." to theBuddy
					try
						do shell script "/Users/nodog/Downloads/arduino-cli upload -p /dev/cu.usbmodem621 --fqbn arduino:avr:mega ~/Documents/Arduino/Red"
					on error
						send "An error occurred. Please try again." to theBuddy
					end try
					send "I changed the lights in Noah's room to red." to theBuddy
					tell application "Messages" to close windows
				else if theMessageText contains "green" then
					send "Please wait..." to theBuddy
					try
						do shell script "/Users/nodog/Downloads/arduino-cli upload -p /dev/cu.usbmodem621 --fqbn arduino:avr:mega ~/Documents/Arduino/Green"
					on error
						send "An error occurred. Please try again." to theBuddy
					end try
					send "I changed the lights in Noah's room to green." to theBuddy
					tell application "Messages" to close windows
				else if theMessageText contains "blue" then
					send "Please wait..." to theBuddy
					try
						do shell script "/Users/nodog/Downloads/arduino-cli upload -p /dev/cu.usbmodem621 --fqbn arduino:avr:mega ~/Documents/Arduino/Blue"
					on error
						send "An error occurred. Please try again." to theBuddy
					end try
					send "I changed the lights in Noah's room to blue." to theBuddy
					tell application "Messages" to close windows
				end if
			end if
		end repeat
		
		(*If the buddy isn't in the list yet, we need to add it*)
		if not (found) and theMessageText contains "opt in" then
			set end of buddyList to createBuddy(theBuddy, "initial")
			if buddyList = {} then
				send "I'm sorry, I couldn't add you to the list because an error occurred. Please try again." to theBuddy
			else
				set justAdded to (item -1 of buddyList)'s getStringName()
				if justAdded ≠ (theBuddy's name as string) then
					send "I'm sorry, I couldn't add you to the list because an error occurred. Please try again." to theBuddy
				else
					newMember(theBuddy)
				end if
			end if
		end if
	end message received
	
	
	(*Avoid errors from different types of input coming in to iMessage.*)
	on received text invitation theMessage from theBuddy for theChat
	end received text invitation
	
	on received audio invitation theText from theBuddy for theChat
	end received audio invitation
	
	on received video invitation theText from theBuddy for theChat
	end received video invitation
	
	on received file transfer invitation theFileTransfer
	end received file transfer invitation
	
	on buddy authorization requested theRequest
	end buddy authorization requested
	
	on message sent theMessage for theChat
	end message sent
	
	on chat room message received theMessage from theBuddy for theChat
	end chat room message received
	
	on active chat message received theMessage
	end active chat message received
	
	on addressed chat room message received theMessage from theBuddy for theChat
	end addressed chat room message received
	
	on addressed message received theMessage from theBuddy for theChat
	end addressed message received
	
	on av chat started
	end av chat started
	
	on av chat ended
	end av chat ended
	
	on login finished for theService
	end login finished
	
	on buddy became available theBuddy
	end buddy became available
	
	on buddy became unavailable theBuddy
	end buddy became unavailable
	
	on completed file transfer
	end completed file transfer
	
end using terms from

