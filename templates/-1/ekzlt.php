<?php
if($row['CONTROL_NAMED']){
  $pnn = 'Тема: ';
  $pnn .= '________________________________________________________________';
  if($row['PERSNAME_NAME'])
    $pnn .= $row['PERSNAME_NAME'];
  echo "<tr><td colspan=61>$pnn</td></tr>";
}
?>
