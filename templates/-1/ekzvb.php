<?php
if(!$excel){
  getdbmass("BARS_ITM($doc_id)", $mass2);
  echo "<tr><td colspan=78><table><tr>";
  while(getrow($mass2, $row2)){
    $npic='';
    bar($row2['BARCODE'],$npic,1,$row2['RESULT_ABBR'],1);
    echo "<td style='vertical-align: text-top;' valign=top>$npic</td>";
  }
  echo "</tr></table></td></tr>";
}
?>
