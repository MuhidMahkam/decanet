<?php
getdbmass("EKZVED_LST($doc_id)", $mass);
$n=0;
while(getrow($mass, $row)){
  $n++;
  $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
  $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);

  echo "
    <tr style='height:5mm;'>
     <td colspan=5 style='border:.5pt solid black;text-align:center'>$n</td>
     <td colspan=19 style='border:.5pt solid black;padding-left:2mm;'>{$row['STUDENT_LNAME']} $fn.$mn.</td>
     <td colspan=6 style='border:.5pt solid black;'>{$row['STUDENT_ZACHNO']}</td>
     <td colspan=48 style='border:.5pt solid black;'>&nbsp</td>
    </tr>
  ";

}
?>
