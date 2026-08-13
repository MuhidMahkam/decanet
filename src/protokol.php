<?php
if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"prot.xls\";");

include "global.php";
sst('sgroup.php');

getdbrow("SFLST_INIT()",$row);
$conn_id = $row['CONN_ID'];

foreach($_POST as $k=>$n)
  if($k[0] == 's')
    getdbrow("SFLST_ADD($conn_id, $n)",$row);


$MAIN .= "<table id=t_mprog>";
getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
$fy = $row['STREAM_FROMYEAR'];
$cs = $_SESSION['cursem'] + 1;
$csr = a2r($cs);

$numc = 13;
$MAIN .= "<tr><td id=width1></td><td id=width15></td><td id=width4></td>";
for($i=0; $i<6; $i++)
  $MAIN .= "<td id=width1></td>";
$MAIN .= "<td id=width1></td><td id=width1></td><td id=width2></td>";
$MAIN .= "</tr>";

getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
$MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
$MAIN .= "<tr><td id=big colspan=$numc>П Р О Т О К О Л</td></tr>";
$MAIN .= "<tr><td align=center colspan=$numc>заседания  стипендиальной комиссии по назначению стипендии</td></tr>";
getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);
getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row1);
$MAIN .= "<tr><td id=left colspan=$numc>факультет: {$row['FACULTET_NAME']}&nbsp;&nbsp;&nbsp;&nbsp;отделение: {$row1['DIVISION_NAME']}</td></tr>";
getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
$fy = $row['STREAM_FROMYEAR'];
$MAIN .= "<tr><td id=left colspan=$numc>группа {$row['SGROUP_AUTONAME']} семестр: $csr&nbsp;&nbsp;&nbsp;&nbsp;год поступления: $fy</td></tr>";

$MAIN .= "<tr id=head>";
$MAIN .= "<td id=tright>№ п/п</td>";
$MAIN .= "<td id=tcenter>Лич.номер</td>";
$MAIN .= "<td id=tleft>ФИО</td>";
$MAIN .= "<td id=tleft>Не сдано</td>";
$MAIN .= "<td id=tleft>Не зачет</td>";
$MAIN .= "<td id=tleft>Неуд</td>";
$MAIN .= "<td id=tleft>Зачет</td>";
$MAIN .= "<td id=tleft>Удовл</td>";
$MAIN .= "<td id=tleft>Хор</td>";
$MAIN .= "<td id=tleft>Отл</td>";
$MAIN .= "<td id=tleft>Ср. балл</td>";
$MAIN .= "<td id=tleft>Решение</td>";
$MAIN .= "<td id=tleft>Прим.</td>";
$MAIN .= "</tr>";

getdbmass("STIPPROT_LST($conn_id,{$_SESSION['co_sgroup']},$cs)", $mass);
$n=0;
$catn = '';
while(getrow($mass, $row)){
  $n++;
  if($catn != $row['CATNAME']){
    $catn = $row['CATNAME'];
    $MAIN .= "<tr><td id=podch colspan=$numc>$catn</td></tr>";
  }
  $MAIN .= "<tr>";
  $MAIN .= "<td id=tright>$n</td>";
  $MAIN .= "<td id=tcenter>{$row['STUDENT_PERSNO']}</td>";
  $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
  $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);

  $MAIN .= "<td id=tleft>{$row['STUDENT_LNAME']} $fn $mn</td>";
  getdbmass("STIPPROT_ITM($conn_id,{$row['STUDSGRP_ID']},$cs)", $mass1);
  while(getrow($mass1,$row1)){
    $rcnt = $row1['RCNT'];
    if(!$rcnt)
      $rcnt = 0;
    $MAIN .= "<td id=tleft>$rcnt</td>";
  }
  if($row['AVGBALL'])
    $avgb = number_format($row['AVGBALL'], 1, ',', '');
  else
    $avgb = '';
  
  $MAIN .= "<td id=tleft>$avgb</td>";
  $MAIN .= "<td id=tleft>{$row['DECIGION']}</td>";
  $MAIN .= "<td id=tleft>{$row['SGBOSS']}</td>";
  $MAIN .= "</tr>";
}
$MAIN .= "</table><br>";
$MAIN .= "Председатель комиссии ________________________________________________________________<br><br>";
$MAIN .= "Члены комиссии ______________________________________________________________________";

sst('sgroup.php');
echo $MAIN;
echo $DEBUG;
?>
</body> 
</html>