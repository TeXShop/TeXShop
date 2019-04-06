on open location texteditURL
	set {theScheme, theRest} to my split(texteditURL, "://")
	set {thePath, theLine, m, n} to my split(theRest, ":")
	tell application "TeXShop"
		activate
		open thePath
		goto front document line (theLine as integer)
	end tell
end open location

on split(theText, theDelim)
	set {tid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, theDelim}
	set theResult to the text items of theText
	set AppleScript's text item delimiters to tid
	return theResult
end split