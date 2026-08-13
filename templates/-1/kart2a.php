<?php
  $s = "style='border:.5pt solid black;vertical-align:top;'";
  $sem=0;
  getdbmass("REP_STUDSEMACAD_LST({$_SESSION['co_student']},3,NULL)", $mass);
  while(getrow($mass, $row)){

    echo "
     <tr>
      <td></td>
      <td colspan=27 $s>{$row['SUBJ_NAME']}</td>
      <td colspan=8 $s>&nbsp;</td>
      <td colspan=6 align=center $s>{$row['SEMESTR']}</td>
      <td colspan=15 $s>{$row['RESULT_NAME']}</td>
      <td colspan=9 $s>{$row['DOCUMENT_INDATE']}</td>
      <td colspan=11 $s>&nbsp;</td>
      <td></td>
     </tr>
    ";
  }
?>