# ijc
Caché ObjectScript interjob communication demo.

## Description
Interjob communication is a way by which two Caché processes can pass data to each other. 
The class IJC demonstrates its use by opening a second terminal while a process is running in the first.

The IJC class has the following methods:
- **OpenTerminal()** opens a terminal and returns its device ID. It has optional arguments for window position and size.
- **CloseTerminal()** closes a device.
- **Demo()** shows hows the two terminal methods work together.

## Installation
Clone the class into your Atelier project through GitHub, or download the file and import it. Open a terminal in the project's namespace and run
```
Do ##class(User.IJC).Demo()
```

This class has been shown to work on Caché versions 2016.2 and later, but it should run on many older versions as well.

## References
- [Caché interjob comunication](https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GIOD_interproccomm#GIOD_ipc_cacheprocs)
- [The cterm command](http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GTER_batch#GTER_B173367)
