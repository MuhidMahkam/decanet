<?php
getdbmass("EKZVED_LST($doc_id)", $mass);
$n=0;
while(getrow($mass, $row)){
  $n++;
  $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
  $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);

  echo "
    <tr style='height:5mm;'>
     <td colspan=4 style='border:.5pt solid black;text-align:center'>$n</td>
     <td colspan=5 style='border:.5pt solid black;text-align:center'>{$row['SUBJ_ABBR']}</td>
     <td colspan=15 style='border:.5pt solid black;padding-left:2mm;'>{$row['STUDENT_LNAME']} $fn.$mn.</td>
     <td colspan=6 style='border:.5pt solid black;'>{$row['STUDENT_ZACHNO']}</td>
     <td colspan=4 style='border:.5pt solid black;'>{$row['RESULT_ABBR']}</td>
     <td colspan=5 style='border:.5pt solid black;'>{$row['DOCTYPE_ABBR']}</td>
     <td colspan=5 style='border:.5pt solid black;'>{$row['DOCUMENT_NO']}</td>
     <td colspan=8 style='border:.5pt solid black;'>{$row['DOCUMENT_INDATE']}</td>
     <td colspan=6 style='border:.5pt solid black;'>&nbsp</td>
     <td colspan=9 style='border:.5pt solid black;'>&nbsp</td>
     <td colspan=11 style='border:.5pt solid black;'>&nbsp</td>
    </tr>
  ";

}
?>
