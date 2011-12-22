<?php
$colors=array("4096EE","008C00","4096EE","FFFF88","73880A","FF7400","008C00","C79810","6BBA70","336699","3366CC","3366FF","33CC33","33CC66","609978","922A99","997D6D","174099","1E9920","E88854","AFC5E8","57FA44","FA6FF6","008080","D77038","272B26","70E0D9","0A19EB","E5E29D","930526","26FF4A","ABC2FF","E2A3FF","808000","000000","00FAFA","E5FA79","F8A6FF","FF36CA","B8FFE7","CD36FF");

foreach($DS as $i => $VAL){
# Graph for tablespace percentage
    if(preg_match('/^total*/',$NAME[$i], $matches)){
        $ds_name[1] = "Total io stat";
        $short_name = $NAME[$i];
        #$short_name = substr($short_name, 4,-10);
        $opt[1] = "--vertical-label \"Kb\" --slope-mode --title \"Total mb for sas\" ";
        if(!isset($def[1])){
            $def[1] = "";
        }
        $def[1] .= "DEF:var$i=$RRDFILE[$i]:$DS[$i]:AVERAGE " ;
	$def[1] .= "CDEF:cvar$i=var$i,512,* ";
        $def[1] .= "LINE2:cvar$i#".$colors[$i].":\"$short_name\" " ;
        $def[1] .= "GPRINT:cvar$i:LAST:\"%6.0lf Mb LAST \" ";
        $def[1] .= "GPRINT:cvar$i:MAX:\"%6.0lf Mb MAX \" ";
        $def[1] .= "GPRINT:cvar$i:AVERAGE:\"%6.2lf Mb AVERAGE \\n\" ";
    }
    # Graph for tablespace size
    if(preg_match('/^read/',$NAME[$i], $matches)){
        $ds_name[2] = "Read stat for disks";
        #$short_name = $matches[0];
	$short_name = $NAME[$i];
        #$short_name = substr($short_name, 4,-6);
        $opt[2] = " --vertical-label \"Mb\" --title \"Read $servicedesc\" ";
        if(!isset($def[2])){
            $def[2] = "";
        }
        $def[2] .= "DEF:var$i=$RRDFILE[$i]:$DS[$i]:AVERAGE " ;
	$def[2] .= "CDEF:cvar$i=var$i,512,* ";
        $def[2] .= "AREA:cvar$i#".$colors[$i].":\"$short_name\":STACK " ;
        $def[2] .= "GPRINT:cvar$i:LAST:\"%6.0lf $UNIT[$i] LAST \" ";
        $def[2] .= "GPRINT:cvar$i:MAX:\"%6.0lf  $UNIT[$i] MAX \" ";
        $def[2] .= "GPRINT:cvar$i:AVERAGE:\"%6.2lf  $UNIT[$i] AVERAGE \\n\" ";
    }
    if(preg_match('/^write/',$NAME[$i], $matches)){
        $ds_name[3] = "Write stat for disks";
        #$short_name = $matches[0];
	$short_name = $NAME[$i];
        #$short_name = substr($short_name, 4,-6);
        $opt[3] = " --vertical-label \"Mb\" --title \"Write $servicedesc\" ";
	if(!isset($def[3])){
            $def[3] = "";
        }
        $def[3] .= "DEF:var$i=$RRDFILE[$i]:$DS[$i]:AVERAGE " ;
        $def[3]	.= "CDEF:cvar$i=var$i,512,* ";
        $def[3] .= "AREA:cvar$i#".$colors[$i].":\"$short_name\":STACK " ;
        $def[3] .= "GPRINT:cvar$i:LAST:\"%6.0lf $UNIT[$i] LAST \" ";
        $def[3] .= "GPRINT:cvar$i:MAX:\"%6.0lf  $UNIT[$i] MAX \" ";
        $def[3] .= "GPRINT:cvar$i:AVERAGE:\"%6.2lf  $UNIT[$i] AVERAGE \\n\" ";
    }
}
?>