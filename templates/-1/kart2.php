<?php
  getdbmass("STUDCONT_LST({$_SESSION['co_student']})", $mass);
  $s = "style='border:.5pt solid black;vertical-align:top;'";
  while(getrow($mass, $row))
  {
    b2d($row['DOCUMENT_INDATE']);
    b2d($row['CONTINGENT_DATE']);
    $s .= "приказ № {$row['DOCUMENT_NO']} дата {$row['DOCUMENT_INDATE']}";
    echo "
     <tr>
      <td></td>
      <td colspan=38 $s>{$row['STUDSTATUS_NAME']}</td>
      <td colspan=27 $s>№{$row['DOCUMENT_NO']} от {$row['DOCUMENT_INDATE']}</td>
      <td colspan=11 $s'>с {$row['CONTINGENT_DATE']}</td>
      <td></td>
     </tr>
    ";
  }
?>