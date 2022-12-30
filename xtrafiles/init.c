/*
 * This program acts as init at the earliest booting stage.
 * It tries to determine the type of the root filesystem mount.
 * If it is squashfs then it takes a special action to provide
 * the writable overlay layer. Otherwise it just proceeds
 * to systemd.
*/

#include <stdio.h>
#include <unistd.h>
#include <sys/vfs.h>
#include <linux/magic.h>

int main(int argc, char **argv) {
  struct statfs stfs;
  int rc = statfs("/", &stfs);
  if(rc != 0) return rc;
  if(stfs.f_type == SQUASHFS_MAGIC) {
/*
 * If root is a squashfs then execute the special script to create the writable tmpfs overlay
*/
    rc = execl("/bin/sh", "/bin/sh", "/usr/bin/overlay", NULL);
    if(rc != 0) return rc;
  } else {
/*
 * If root is anything else just execute systemd 
*/
    rc = execl("/bin/systemd", "/bin/systemd", NULL);
    if(rc != 0) return rc;
  }
  return 0;
}

