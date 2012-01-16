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

$opt[1] = "--vertical-label \"count\" -r --title \"Nginx Status Connection and Request $hostname / $servicedesc\" ";
$opt[2] = "--vertical-label \"count\" -l 0 -r --title \"cputime for $hostname / $servicedesc\" ";

$def[1] =  "DEF:reqpsec=$rrdfile:$DS[1]:AVERAGE " ;
$def[1] .=  "DEF:conpsec=$rrdfile:$DS[2]:AVERAGE " ;

$def[1] .= "COMMENT:\"\\t\\t\\tLAST\\t\\t\\tAVERAGE\\t\\t\\tMAX\\n\" " ;

$def[1] .= "LINE2:reqpsec#E80C3E:\"reqpsec\\t\\t\" " ;
$def[1] .= "GPRINT:reqpsec:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:reqpsec:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:reqpsec:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "LINE2:conpsec#008000:\"conpsec\\t\" " ;
$def[1] .= "GPRINT:conpsec:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:conpsec:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:conpsec:MAX:\"%6.2lf \\n\" " ;

$def[2] = "DEF:read=$rrdfile:$DS[3]:AVERAGE " ;
$def[2] .= "DEF:write=$rrdfile:$DS[4]:AVERAGE ";
$def[2] .= "DEF:wait=$rrdfile:$DS[5]:AVERAGE ";
$def[2] .= "AREA:read#356AA0::STACK " ;
$def[2] .= "AREA:write#4096EE::STACK " ;
$def[2] .= "AREA:wait#C3D9FF::STACK " ;
$def[2] .= "GPRINT:read:LAST:\"%6.0lf read LAST \" ";
$def[2] .= "GPRINT:write:LAST:\"%6.0lf write LAST \" ";
$def[2] .= "GPRINT:wait:LAST:\"%6.2lf wait LAST \\n\" ";

?>