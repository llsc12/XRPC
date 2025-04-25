# XRPC
An Xcode Rich Presence utility app. 

## Why
There's already a few other RPC apps out there. But they come with a few caveats, namely that they rely on AppleScript to poll Xcode.

XRPC instead uses Accessibility APIs which work better and also i think applescript launches xcode a lot out of nowhere lol

this bug in other rich presence apps happens because it checks if xcode is open in one instant but then it could be closed after the check happens, but its too late and an applescript snippet to check xcode was run already, which will open xcode if its not already open to check its status.

