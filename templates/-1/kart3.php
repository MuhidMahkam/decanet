<?php
  $s = "style='border:.5pt solid black;vertical-align:top;'";
  getdbmass("REP_STUDSEMACAD_LST({$_SESSION['co_student']},2,NULL)", $mass);
  while(getrow($mass, $row))
    echo "
     <tr>
      <td></td>
      <td colspan=17 $s'>{$row['SUBJ_NAME']}</td>
      <td colspan=18 $s>{$row['PERSNAME_NAME']}</td>
      <td colspan=5 align=center $s>{$row['SEMESTR']}</td>
      <td colspan=14 $s>{$row['RESULT_NAME']}</td>
      <td colspan=8 align=center $s>{$row['DOCUMENT_INDATE']}</td>
      <td colspan=14 $s>&nbsp;</td>
      <td></td>
     </tr>
    ";
?>