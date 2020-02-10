### Set Tmp File Path

This should be on the disk you want to test:

    export TMPFILE=/tank/michael/bench/tmpfile


### Write Test

    dd if=/dev/zero of=$TMPFILE bs=1M count=1024 conv=fdatasync,notrunc status=progress

This will give you write speed.


### Clear Caches

    sudo bash -c 'echo 3 > /proc/sys/vm/drop_caches'


## Read Test

    dd if=$TMPFILE of=/dev/null bs=1M count=1024 status=progress

This will give you uncached read performance.

Re-run the same command for cached read performance:

    dd if=$TMPFILE of=/dev/null bs=1M count=1024 status=progress
