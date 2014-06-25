#!/bin/bash
argument="$1"


# modified from: https://github.com/iFixit/pipe-to-graphite/blob/master/scripts/memcache-stats.sh

# Echo all the useful information from the `stats` memcache
# telnet command
#
# Output will resemble this:
#
# memcache.pid 17576
# memcache.uptime 1080764
# memcache.time 1344234823
# memcache.pointer_size 64
# memcache.rusage_user 51.160222
# memcache.rusage_system 157.221098
# memcache.curr_items 181059
# memcache.total_items 1948898
# memcache.bytes 62620267
#
# Output will include this if argument=='extended' (for each slab):
#
# memcache.slabs.5.chunk_size 280
# memcache.slabs.5.chunks_per_page 3744
# memcache.slabs.5.total_pages 3
# memcache.slabs.5.total_chunks 11232
# memcache.slabs.5.used_chunks 11226
# memcache.slabs.5.free_chunks 6
# memcache.slabs.5.free_chunks_end 1849
#

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

GRAPHITE_HOST=localhost
GRAPHITE_PORT=2003
GRAPHITE_PATH=path.to.carbon.$(hostname | cut -d '.' -f 1)
TIME=`date +%s`

for l in `
exec 3<>/dev/tcp/localhost/11211
(
    sleep 1
    [ "$argument" == "extended" ] && echo "stats slabs" && echo "stats items"
    echo "stats"
    sleep 1
    echo "quit"
) >&3
cat <&3 |
grep STAT |
grep -v version |
sed -re 's/STAT (items:)?([0-9]+):/memcache.slabs.\2./' \
     -e 's/STAT /memcache./'`
do
    echo $GRAPHITE_PATH.$l

    echo $GRAPHITE_PATH.$l $TIME > /dev/tcp/$GRAPHITE_HOST/$GRAPHITE_PORT

#    exec 3<>/dev/tcp/$GRAPHITE_HOST/$GRAPHITE_PORT
#    echo -e "$GRAPHITE_PATH.$l $TIME\n\n" >&3
#    cat <&3
done


IFS=$SAVEIFS

