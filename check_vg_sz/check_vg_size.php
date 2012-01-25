<?php
$opt[1] = "--title \"Free Space VG on $hostname / $servicedesc\" -l0";

$def[1] = "DEF:size_mb=$RRDFILE[1]:$DS[1]:AVERAGE ";
$def[1] .= "CDEF:size=size_mb,1024,/ ";
$def[1] .= "AREA:size#078ae8:\"$NAME[1]\t\" ";
$def[1] .= "GPRINT:size:LAST:\"%2.1lf%s current\" ";
?>
