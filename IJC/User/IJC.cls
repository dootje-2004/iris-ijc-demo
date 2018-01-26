/// Class that implements interjob communication.<br/>See the 
/// <a href="https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GIOD_interproccomm#GIOD_ipc_cacheprocs">
/// documentation</a> for more information on this subject.
Class User.IJC [ Abstract ]
{

/// Opens a new terminal and returns an IJC device ID that allows writing to it.<br/>
/// A return value of 0 indicates failure to open an IJC connection. This allows code to proceed without error checking
/// and causes all WRITEs to be sent to the principal terminal.
ClassMethod OpenTerminal() As %Integer
{
	// Get the name of this Cache' instance.
	SET cacheName=##class(%SYS.System).GetInstanceName()
	// Get the location of the cterm command.
	SET command=$LISTBUILD($SYSTEM.Util.BinaryDirectory()_"cterm")
	// Compose the /console argument.
	SET command=command_$LISTBUILD("/console=cn_ap:"_cacheName_"["_$NAMESPACE_"]:##class("_$CLASSNAME()_").OpenIJCDevice()")
	// Compose the /pos argument.
	SET command=command_$LISTBUILD("/pos=(50,50)")
	// Execute the command.
	SET sc=$ZF(-2,$LISTTOSTRING(command," "))
	// Wait for OpenIJCDevice() to publish the device ID. Not a CPU-friendly solution, but it avoids an explicit time-out.
	WHILE '$DATA(^ijcdevice) { HANG 0.01 }
	SET device=^ijcdevice
	WRITE "Using IJC WRITE device ",device,!
	// Now that we have the device ID, we discard the global.
	KILL ^ijcdevice
	OPEN device::0
	QUIT:'$TEST 0
	QUIT device
}

/// Establishes an interjob connection for reading (with an even-numbered device ID).
/// The IJC device number is stored in the global ^ijcdevice, where it can be read by OpenTerminal().
/// If no IJC connection can be established, ^ijcdevice is set to 0, i.e. the default device of the principal terminal.
/// The device and the terminal are closed upon reception of a single escape character, $CHAR(27).
ClassMethod OpenIJCDevice() [ Internal ]
{
	WRITE "Terminal job ",$J,!
	// Find a free IJC connection among the first 16 device pairs. This is usually enough choice.
	FOR dev=224:2:254 {
		OPEN dev::0
		QUIT:$TEST
	}
	// Check for success.
	IF '$TEST {
		SET ^ijcdevice=0
		QUIT
	}
	WRITE "Using IJC READ device ",dev,!!
	// Publish the corresponding WRITE device ID.
	SET ^ijcdevice=dev+1
	// Wait for input. Close device and quit when we receive a single escape character.
	FOR {
		USE dev
		READ X
		QUIT:X=$CHAR(27)
		USE 0
		WRITE X
	}
}

/// Closes a terminal in which an interjob connection is running.<br/>
/// <var>deviceID</var> is the IJC device number returned by the OpenTerminal() call that opened the terminal.
ClassMethod CloseTerminal(deviceID As %Integer)
{
	// Get ownership of the device.
	OPEN deviceID::0
	// Quit on failure.
	QUIT:'$TEST
	USE deviceID
	// Signal the IJC process at the other end to quit by sending a single escape character.
	WRITE $CHAR(27)
	CLOSE deviceID
}

/// Demonstrates the OpenTerminal() method.<br/>
/// It writes 10,000 lines to the principal terminal, and one line to the secondary terminal every 1000 lines.<br/>
/// After completion there is a three-second pause before the second terminal closes, unless <var>keepOpen</var> is set to 1.
/// In that case you can issue CloseTerminal(<var>device ID</var>) to close it.<br/>
/// <b>Note:</b> It is best to write the bulk of your output to the principal terminal and the progress to the second one.
/// Every WRITE to the second device causes a back-and-forth switch between the two devices, which can be time-consuming.
ClassMethod Demo(keepOpen As %Boolean = 0)
{
	SET term=..OpenTerminal()
	IF 'term {
		WRITE "Could not open an IJC device",!
		QUIT
	}
	F i=1:1:10000 {
		USE 0
		WRITE "This is line ",i,!
		IF i#1000=0 {
			USE term
			WRITE "Progress: written ",i," lines",$CHAR(13)
		}
	}
	WRITE !!
	QUIT:keepOpen
	USE 0
	WRITE "Waiting for the other terminal to close..."
	USE term
	FOR i=3:-1:1 {
		WRITE "Wait ",i," seconds.",$CHAR(13)
		HANG 1
	}
	DO ..CloseTerminal(term)
	USE 0
	WRITE $CHAR(13),$CHAR(27),"[K","Done."
}

}

