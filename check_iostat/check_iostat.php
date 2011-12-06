<?php
$opt[1] = "--title \"Speed IO operation on $hostname / $servicedesc\" -l0";

$def[1] = "DEF:read_kb=$RRDFILE[1]:$DS[1]:LAST ";
$def[1] .= "CDEF:read=read_kb,1024,* ";
$def[1] .= "LINE2:read#078ae8:\"$NAME[1]\t\" ";
$def[1] .= "GPRINT:read:LAST:\"%2.1lf%s Last\" ";
$def[1] .= "GPRINT:read:MAX:\"%2.1lf%s Max\" ";
$def[1] .= "GPRINT:read:AVERAGE:\"%2.1lf%s Average\\n" ";
$def[1] .= "DEF:write_kb=$RRDFILE[1]:$DS[2]:AVERAGE ";
$def[1] .= "CDEF:write=write_kb,1024,* ";
$def[1] .= "LINE2:write#06cc17:\"$NAME[2]\t\" ";
$def[1] .= "GPRINT:write:LAST:\"%2.1lf%s Last\" ";
$def[1] .= "GPRINT:write:MAX:\"%2.1lf%s Max\" ";
$def[1] .= "GPRINT:write:AVERAGE:\"%2.1lf%s Average\\n" ";

?>
