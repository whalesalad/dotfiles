### Mount Manually

Ensure NFS permissions are set on [Valhalla](https://valhalla.ws.internal), then:

    sudo mount -t nfs -o vers=3 valhalla.ws.internal:/volume3/lab /mnt/lab
    sudo mount -t nfs -o vers=3 valhalla.ws.internal:/volume2/Whalesalad /mnt/whalesalad/


### In /etc/fstab

```
<file system>                               <mount point>   <type>  <options>   <dump>  <pass>
valhalla.ws.internal:/volume3/lab           /mnt/lab        nfs     vers=3      0       0
valhalla.ws.internal:/volume2/whalesalad    /mnt/whalesalad nfs     vers=3      0       0
```
