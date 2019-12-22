# b-boot
## Ancient DOS boot sector source to boot from second floppy drive

This is the source to a custom boot sector intended for a floppy disk. It had a rather curious purpose (curious enough 
that I have to say I can't recall exactly what the problem was that I was solving). 

Functionally though, the idea was that this boot sector could be installed on a floppy disk and placed in the first drive
(A: drive). You could then place another disk in B: drive. When you rebooted the computer, it would read the boot sector
from A: drive, and this code would then swap the drives around so that the boot process would actually use the B: drive.

It also set up a replacement for interrupt 15 so that references to the A: drive would be swapped to the B: drive, thus 
allowing software on the disk to operate while thinking it was actually the first drive.
