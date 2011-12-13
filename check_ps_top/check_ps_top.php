<?php

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

#   PNP Template for check_ps.sh
#   Author: Mike Adolphs (http://www.matejunkie.com/

$opt[1] = "--vertical-label \"percent\" -u 100 -l 0 -r --title \"CPU/Memory Usage for $hostname / $servicedesc\" ";
$opt[2] = "--vertical-label \"minutes\" -u 100 -l 0 -r --title \"cputime for $hostname / $servicedesc\" ";

$def[1] =  "DEF:cpu=$rrdfile:$DS[1]:AVERAGE " ;
$def[1] .=  "DEF:memory=$rrdfile:$DS[2]:AVERAGE " ;
$def[2] .=  "DEF:cputime=$rrdfile:$DS[3]:AVERAGE " ;

$def[1] .= "COMMENT:\"\\t\\t\\tLAST\\t\\t\\tAVERAGE\\t\\t\\tMAX\\n\" " ;
$def[2] .= "COMMENT:\"\\t\\t\\tLAST\\t\\t\\tAVERAGE\\t\\t\\tMAX\\n\" " ;

$def[1] .= "LINE2:cpu#E80C3E:\"CPU\\t\\t\" " ;
$def[1] .= "GPRINT:cpu:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:cpu:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:cpu:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "LINE2:memory#008000:\"Memory\\t\" " ;
$def[1] .= "GPRINT:memory:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:memory:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:memory:MAX:\"%6.2lf \\n\" " ;

$def[2] .= "AREA:cputime#E80C3E:\"CPUTime\\t\" " ;
$def[2] .= "GPRINT:cputime:LAST:\"%6.2lf min\\t\\t\" " ;
$def[2] .= "GPRINT:cputime:AVERAGE:\"%6.2lf min\\t\\t\" " ;
$def[2] .= "GPRINT:cputime:MAX:\"%6.2lf min\\n\" " ;
?>
