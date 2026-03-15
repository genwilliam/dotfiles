Vacuum Mail Index
The AppleScript code below will quit Mail, vacuum the SQLite index, then re-open Mail. On a large email database that hasn't been optimized for a while, this can provide significant improvements in responsiveness and speed.
```shell
(*
Speed up Mail.app by vacuuming the Envelope Index
Code from: http://web.archive.org/web/20071008123746/http://www.hawkwings.net/2007/03/03/scripts-to-automate-the-mailapp-envelope-speed-trick/
Originally by "pmbuko" with modifications by Romulo
Updated by Brett Terpstra 2012
Updated by Mathias Törnblom 2015 to support V3 in El Capitan and still keep backwards compatibility
Updated by Andrei Miclaus 2017 to support V4 in Sierra
*)

tell application "Mail" to quit
set os_version to do shell script "sw_vers -productVersion"
set mail_version to "V2"
considering numeric strings
    if "10.10" <= os_version then set mail_version to "V3"
    if "10.12" <= os_version then set mail_version to "V4"
    if "10.13" <= os_version then set mail_version to "V5"
    if "10.14" <= os_version then set mail_version to "V6"
    if "10.15" <= os_version then set mail_version to "V7"
    if "11" <= os_version then set mail_version to "V8"
end considering

set sizeBefore to do shell script "ls -lnah ~/Library/Mail/" & mail_version & "/MailData | grep -E 'Envelope Index$' | awk {'print $5'}"
do shell script "/usr/bin/sqlite3 ~/Library/Mail/" & mail_version & "/MailData/Envelope\\ Index vacuum"

set sizeAfter to do shell script "ls -lnah ~/Library/Mail/" & mail_version & "/MailData | grep -E 'Envelope Index$' | awk {'print $5'}"

display dialog ("Mail index before: " & sizeBefore & return & "Mail index after: " & sizeAfter & return & return & "Enjoy the new speed!")

tell application "Mail" to activate
```
Since the above AppleScript mainly uses shell commands anyway, here's a shell script version of the same functionality. It's usable from Big Sur onwards. Feel free to send a patch for newer systems. I currently don't have the money for a machine capable of running macOS 12+.
#!/bin/zsh

```bash
#
# Speed up Mail.app by vacuuming the Envelope Index
# Written by Marcel Bischoff
# AppleScript original by "pmbuko" with modifications by Romulo
#

OS_VERSION=$(sw_vers -productVersion | cut -d. -f 1,2)
MAIL_RUNNING=$(ps aux | grep -v grep | grep -c "Mail\$")
MAIL_VERSION="V2"

if [ $MAIL_RUNNING -gt 0 ]; then osascript -e 'tell application "Mail" to quit'; fi

if [ 1 -eq "$(echo "11 <= ${OS_VERSION}" | bc)" ]; then MAIL_VERSION="V8"; fi

SIZE_BEFORE=$(ls -lnah ~/Library/Mail/${MAIL_VERSION}/MailData | grep -E 'Envelope Index$' | awk {'print $5'})
/usr/bin/sqlite3 ~/Library/Mail/${MAIL_VERSION}/MailData/Envelope\ Index vacuum
SIZE_AFTER=$(ls -lnah ~/Library/Mail/${MAIL_VERSION}/MailData | grep -E 'Envelope Index$' | awk {'print $5'})

printf "Mail index before: %s\nMail index after: %s\n" $SIZE_BEFORE $SIZE_AFTER
```
