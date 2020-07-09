## [crackhelperServer.exe] commands:
```
-port N           Listen port N for client connections
-range begin:end  Using range from begin to end
-dp N             Divide whole range into 2^N subranges
-out fileneame    Name of your log file where will be stored finded key
-address ADDR     Address that will be find with bitckrack app.
-map fileneame    Name of your map file where will be stored subranges key
Example: crackhelperServerX64.exe -range 8000000000:ffffffffff -dp 5 -map mmm.bin -address 1EeAxcprB2PpCnr34VfZdFrkUWuxyiNEFv
```

## [crackhelperClient.exe] commands:
```
-prog filename    The name of bitckrack app
-name  NAME       Instance name for stats on server
-pool host:port   Server host:port by default 127.0.0.1:8000
-d N              GPU device id
-t N              Number of threads
-b N              Number of blocks
-p N              Number of points per thread
Example: crackhelperClientX64.exe -prog cuBitCrack.exe -name 2080ti -d 0 -pool 127.0.0.1:8000 -t 256 -b 136 -p 512
```

Note! When you complile apps by yourself don`t forget in compile options:
<ul>
  <li>Uncheck > create unicode executable</li>
  <li>Check > Create threadsafe executable</li>
  <li>Executable format> console</li>
</ul>

Note! Bitcrack app sholud be put in the same folder as crackhelperClientX64.exe\
If you have few GPU on the same PC put each instance of crackhelperClientX64.exe to new folder(and Bitcrack app)\
How to correct set -dp:\
Job timeout is 1 day. If client do not submit job in 1 day, job will be deleted.\
So the width of the subrange should be such that it can be solved in 1 day maximum by 1 instance client.\
For ex your gpu can calculate 2^30 keys/s \
In this case for 2.5h  gpu can calculate 2^43keys\
If your whole range is 2^63 than devide 2^63 / 2^43 = 2^20\
So -dp 20, mean devide whole range into 1048576(2^20) subranges and width of each subrange is 2^43.\

## [merger.exe] is needed to combine the results of work from crackhelperServerX64.

The same ranges and addresses are required in both map files!\
You can combine files with the same -dp\

But you can also combine files with different -dp, for ex -dp 20 with -dp 22\
But here it should be remembered that in the saved file dp will be the greatest!\
If you are merge -dp 20 with -dp 22 then merger logic will be:
<ul>
  <li>copy file with -dp 22 to savingmap file</li>
  <li>copy all scanned subranges from file with -dp 20 to savingmap file</li>
  <li>totaly you will have savingmap file with -dp 22 where already put scanned ranges from file with -dp 20</li>
</ul>
example of usage > merger.exe mmm.bin mmmmerge.bin mmmsave.bin
