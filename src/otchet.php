<?php
if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"agrp.xls\";");
include "global.php";
getp('mp_id');
getp('tem');
$sgr = getTFN($_SESSION['sgrm1']);
sst("sgroup.php?mp_id=$mp_id");
if($tem)
  $numc = 3;
else
  $numc = 6;
getdbmass("GRPSEMMPROGITEM_LST($mp_id)", $mass);
$abbr = false;
$disc = 'Дисциплина';
$predm = $hpredm = '';
getrow($mass,$row);
$ssn = $row['SUBJ_NAME'];
$cname = $row['CONTROL_NAME'];
$vol = $row['VOLUME'];
$first = true;
while(getrow($mass,$row)){
  $ssn .= ', '.$row['SUBJ_NAME'];
  if($first){
    $predm = '<td id=tleft>Дисципл.</td>';
    $disc .= " по выбору";
    $first = false;
  }
  $abbr = true;
  $numc++;
  $hpredm = "<td id=width2></td>";
}
$disc .= ': ';
$disc .= $ssn;
$disc .= " ($cname) ";
$disc .= "часов: $vol<br>";
$MAIN .= "<table id=tabotchet>";
if($tem)
  $MAIN .= "<tr><td id=width1></td><td id=width4></td>$hpredm<td id=width8></td></tr>";
else
  $MAIN .= "<tr><td id=width1></td><td id=width8></td>$hpredm<td id=width15></td>
    <td id=width15></td><td id=width2></td><td id=width2></td></tr>";

getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
$MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);
getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row1);
$MAIN .= "<tr><td id=left colspan=$numc>факультет: {$row['FACULTET_NAME']}&nbsp;&nbsp;&nbsp;&nbsp;отделение: {$row1['DIVISION_NAME']}</td></tr>";
getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
$sem = a2r($_SESSION['cursem'] + 1);
$MAIN .= "<tr><td id=left colspan=$numc>группа: {$row['SGROUP_AUTONAME']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;семестр: $sem</td></tr>";
$MAIN .= "<tr><td id=left colspan=$numc>$disc</td></tr>";
if($tem)
  $MAIN .= "<tr><td id=med colspan=$numc>Темы работ по дисциплине</td></tr>";
else
  $MAIN .= "<tr><td id=med colspan=$numc>Академическая успеваемость группы по дисциплине</td></tr>";
if($tem)
  $MAIN .= "<tr id=head><td id=tcenter>№</td><td id=tleft>ФИО студента</td>$predm<td id=tleft>Тема</td></tr>";
else
  $MAIN .= "<tr id=head><td id=tcenter>№</td><td id=tleft>ФИО студента</td>$predm<td id=tleft>Оценка</td><td id=tleft>Док</td><td id=tleft>№</td><td id=tleft>Дата</td></tr>";
getdbmass("GRPACADMPROG_LST({$_SESSION['co_sgroup']},$mp_id,$sgr)", $mass);
$n = $sid = 0;
while(getrow($mass, $row))
{
  $bold = '';
  if(!$row['RESULT_PASSFLAG'])
    $bold = 'id=col3';
  if($tem && $row['STUDSGRP_ID'] == $sid)
    continue;
  $MAIN .= "<tr $bold>";
  if($row['STUDSGRP_ID'] != $sid){
    $sid = $row['STUDSGRP_ID'];
    $n++;
    $MAIN .= "<td id=tcenter>$n</td>";
    $MAIN .= "<td id=tleft>{$row['STUDENT_LNAME']} ";
    if($tem)
      $MAIN .= mb_substr($row['STUDENT_FNAME'], 0, 1).'.'.mb_substr($row['STUDENT_MNAME'], 0, 1).'.';
    else
      $MAIN .= $row['STUDENT_FNAME'].' '.$row['STUDENT_MNAME'];
    $MAIN .= "</td>";
  }
  else
    $MAIN .="<td id=tcenter></td><td id=tleft></td>";
  if($abbr)
    $MAIN .= "  <td id=tleft>{$row['SUBJ_ABBR']}</td>";
  if($tem)
    $MAIN .= "<td id=tleft>{$row['PERSNAME_NAME']}</td>";
  else{
    $MAIN .= "<td id=tleft>{$row['RESULT_ABBR']}</td>";
    $MAIN .= "<td id=tleft>{$row['DOCTYPE_ABBR']}</td>";
    $MAIN .= "<td id=tleft>{$row['DOCUMENT_NO']}</td>";
    $MAIN .= "<td id=tleft>{$row['DOCUMENT_INDATE']}</td>";
  }
  $MAIN .= "</tr>";
}
$MAIN .= "</table>";
sst("sgroup.php?mp_id=$mp_id");
echo $MAIN;
echo $DEBUG;
?>
</body> 
</html>