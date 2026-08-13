<?php
  $s = "style='border:.5pt solid black;vertical-align:top;'";
  $sem=0;
  getdbmass("REP_STUDSEMACAD_LST({$_SESSION['co_student']},1,$kurs)", $mass);
  while(getrow($mass, $row)){
    if($sem != $row['SEMESTR']){
      $sem = $row['SEMESTR'];
    echo "
     <tr>
      <td></td>
      <td colspan=76 $s style='font-size:12pt;'><b>семестр $sem</b></td>
      <td></td>
     </tr>
    ";
    }
     
    echo "
     <tr>
      <td></td>
      <td colspan=31 $s>{$row['SUBJ_NAME']}</td>
      <td colspan=4 $s>{$row['VOLUME']}</td>
      <td colspan=6 $s>{$row['CONTROL_ABBR']}</td>
      <td colspan=14 $s>{$row['RESULT_NAME']}</td>
      <td colspan=8 $s>{$row['DOCUMENT_INDATE']}</td>
      <td colspan=13 $s>&nbsp;</td>
      <td></td>
     </tr>
    ";
  }
?>