<?php
if(!$excel){
  getdbmass("BARS_ITM($doc_id)", $mass2);
  echo "<tr><td colspan=61><table><tr>";
  while(getrow($mass2, $row2)){
    $npic='';
    //$aa='1234567R1';
    //bar($row2['BARCODE'],$npic,1,$row2['RESULT_ABBR'],1);
    bar($row2['BARCODE'],$npic,1,$row2['BARCODE'],1);
    //bar($aa,$npic,1,$row2['RESULT_ABBR'],1);
    echo "<td style='vertical-align: text-top;' valign=top>$npic</td>";
  }
  echo "</tr></table></td></tr>";
}
?>
