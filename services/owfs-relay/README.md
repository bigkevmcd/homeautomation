You will need OWFS configured correctly on the machine for a host device.

Then something like:

  $ sudo owfs --allow_other /dev/usbdev1.4 /mnt/one-wire/

Specify the mount-point in the creation of the OWFSRelay.

OWFS does not provide inotify (otherwise we could use fs.watch).
