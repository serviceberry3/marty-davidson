JsOsaDAS1.001.00bplist00�Vscript_rfunction run(argv) {
	var Calendar = Application('Calendar');
	app = Application.currentApplication();

	app.includeStandardAdditions=true;

	var eventStart = new Date(argv[0]);
	eventStart.setHours(eventStart.getHours() + 4);
	
	var eventEnd = new Date(eventStart);
	eventEnd.setHours(eventEnd.getHours()+1);


	var martyCal = Calendar.calendars.whose({name:"martyishuge@gmail.com"}),

	event = Calendar.Event({summary: "Meeting with Marty", startDate: eventStart, endDate: eventEnd}),
	attendee = Calendar.Attendee({email: argv[1]});
	

	martyCal=martyCal[0];
	martyCal.events.push(event);
	event.attendees.push(attendee);
}                              �jscr  ��ޭ