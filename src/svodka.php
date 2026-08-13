<?php
if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"svodka.xls\";");
//$body = '<style>#landscape{size:landscape;}</style><body id=landscape>';
include "global.php";
getp('setka');
if($setka)
  echo "
  <style>
    #bord, #bord_tbrl, #bord_tb, #bord_tb_tbrl, #bord_all,
    #bord_t, #bord_b, #bord_r, #bord_l,
    #bord_lr, #bord_ltb, #bord_tr, #bord_br, #bord_tbrl, #bord_tb_tbrl
      {border-width:1px; border-style:solid; border-color:black;}
  </style>
  ";
getp('sfase');
getp('vs');
getp('itogi');
getp('blank');
sst('sgroup.php?svodka=1');
$MAIN .= "<table id=svodka width=100%>";
getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
$fy = $row['STREAM_FROMYEAR'];
$cs = $_SESSION['cursem'] + 1;
$csr = a2r($cs);
$numc = 0;

getdbrow("VSAI_INIT()",$row);
$cid = $row['CONN_ID'];
if($vs){
  $_SESSION['MPL'] = array(); // очищаем старое
  $_SESSION['MPL'][] = 0;
  foreach($_POST as $k => $v)
    if(($k[0] == 'm') && ($k[1] == 'p')){
      getdbrow("VSAI_ADD($cid,$v)",$row);
      $_SESSION['MPL'][] = $v;
    }
}
else
  getdbrow("VSAI_PHASEADD($cid,{$_SESSION['co_sgroup']},$cs,$sfase)",$row);
getdbrow("VSAI_MP_CNT($cid)", $row);

$numc = $row['CNT'];
$numc+=4;

/*
$MAIN .= "<tr><td width=3%></td><td width=10%></td><td width=3%></td>";
for($i=0; $i<($numc - 3); $i++)
  $MAIN .= "<td width=2%></td>";
$MAIN .= "</tr>";
*/

getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
$MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
$MAIN .= "<tr><td id=med colspan=$numc>Сводная ведомость</td></tr>";

getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);
getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row1);
$MAIN .= "<tr><td id=left colspan=$numc>факультет: {$row['FACULTET_ABBR']}&nbsp;&nbsp;&nbsp;&nbsp;отделение: {$row1['DIVISION_NAME']}";
getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
$fy = $row['SGROUP_PERIOD'];
if(!$vs)
  $MAIN .= "&nbsp;&nbsp;&nbsp;семестр: $csr";
$MAIN .= "&nbsp;&nbsp;&nbsp;&nbsp;Поток: $fy";

$MAIN .= "&nbsp;&nbsp;&nbsp;Группа:{$row['SGROUP_AUTONAME']}</td></tr>";
//$MAIN .= "<tr><td id=med colspan=$numc>Сводная ведомость результатов сдачи контрольных мероприятий</td></tr>";

getdbmass("VSAI_MP_LST($cid)",$mass);
$MAIN .= "<tr><td id=bord>№</td><td id=bord>ФИО студента</td><td id=bord>№ зач.<br>книжки</td>";
while(getrow($mass, $row)){
  $ses = a2r($row['SEMESTR']);
  if(isset($_GET['excel']))
    $MAIN .= "<td id=bord_tb>$ses-{$row['SUBJ_ABBR']}<br>({$row['CONTROL_ABBR']})</td>";
  else
    $MAIN .= "<td id=bord_tb_tbrl>$ses-{$row['SUBJ_ABBR']}({$row['CONTROL_ABBR']})</td>";
}
if(isset($_GET['excel']))
  $MAIN .= "<td id=bord>Инд.ср.балл</td></tr>";
else
  $MAIN .= "<td id=bord_tbrl>Инд.ср.балл</td></tr>";
getdbmass("VSAI_STUD_LST($cid,{$_SESSION['co_sgroup']})", $mass);
$n=0;
while(getrow($mass, $row)){
  $n++;
  $MAIN .= "<tr>";
  $MAIN .= "<td id=bord_lr>$n</td>";
  $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
  $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);
  $MAIN .= "<td id=bord_lr>{$row['STUDENT_LNAME']} $fn.$mn.</td>";
  $MAIN .= "<td id=bord_lr>{$row['STUDENT_ZACHNO']}</td>";
  getdbmass("VSAI_RES_LST($cid,{$row['STUDSGRP_ID']})", $mass1);
  while(getrow($mass1,$row1))
    if($blank)
      $MAIN .= "<td id=bord_all align=center>.</td>";
    else
      $MAIN .= "<td id=bord_all align=center>{$row1['RESULT_ABBR']}</td>";
  if(!$row['FAILFLAG']){
    $avg = str_replace(".", ",", $row['AVGBALL']);
    if($blank)
      $MAIN .= "<td id=bord_lr align=center>.</td>";
    else
      $MAIN .= "<td id=bord_lr align=center>$avg</td>";
  }
  else
    $MAIN .= "<td id=bord_lr></td>";
  $MAIN .= "</tr>";
}

if($itogi && !$blank){
  getdbmass("VSAI_MPITOG_LST($cid,{$_SESSION['co_sgroup']})",$mass);
  $MAIN .= "<tr>";
  if(isset($_GET['excel']))
    $MAIN .= "<td id=bord rowspan=7></td>";
  else
    $MAIN .= "<td id=bord_tbrl align=center rowspan=7>по дисциплине</td>";

  $MAIN .= "<td id=bord_t colspan=2>Средний балл</td>";
  while(getrow($mass, $row)){
    $avg = str_replace(".", ",", $row['AVGBALL']);
    $MAIN .= "<td id=bord_t align=center>$avg</td>";
  }
  $MAIN .= "<td id=bord_tr></td></tr>";
  $mass->data_seek(0);
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=2>Повышенных оценок, %</td>";
  while(getrow($mass, $row)){
    if($row['AVGBALL'])
      $kusp = str_replace(".", ",", $row['KUSP']);
    else
      $kusp = '';
    $MAIN .= "<td align=center>$kusp</td>";
  }
  $MAIN .= "<td id=bord_r></td></tr>";
  $mass->data_seek(0);
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=2>Неаттестованных, чел</td>";
  while(getrow($mass, $row))
    $MAIN .= "<td align=center>{$row['CNTNEG']}</td>";
  $MAIN .= "<td id=bord_r></td></tr>";
  $mass->data_seek(0);
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=2>Сдавших на \"5\", чел</td>";
  while(getrow($mass, $row)){
    if($row['AVGBALL'])
      $cnt = $row['CNT5'];
    else
      $cnt = '';
    $MAIN .= "<td align=center>$cnt</td>";
  }
  $MAIN .= "<td id=bord_r></td></tr>";
  $mass->data_seek(0);
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=2>Сдавших на \"4\", чел</td>";
  while(getrow($mass, $row)){
    if($row['AVGBALL'])
      $cnt = $row['CNT4'];
    else
      $cnt = '';
    $MAIN .= "<td align=center>$cnt</td>";
  }
  $MAIN .= "<td id=bord_r></td></tr>";
  $mass->data_seek(0);
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=2>Сдавших на \"3\", чел</td>";
  while(getrow($mass, $row)){
    if($row['AVGBALL'])
      $cnt = $row['CNT3'];
    else
      $cnt = '';
    $MAIN .= "<td align=center>$cnt</td>";
  }
  $MAIN .= "<td id=bord_r></td></tr>";
  $mass->data_seek(0);
  $MAIN .= "<tr>";
  $MAIN .= "<td id=bord_b colspan=2>Не сдавших (\"2\", \"-\"), чел</td>";
  while(getrow($mass, $row))
    $MAIN .= "<td id=bord_b align=center>{$row['CNT2']}</td>";
  $MAIN .= "<td id=bord_br></td></tr>";

  getdbrow("VSAI_SGRP_LST($cid,{$_SESSION['co_sgroup']})",$row);
  $MAIN .= "<tr>";
  if(isset($_GET['excel']))
    $MAIN .= "<td id=bord rowspan=6></td>";
  else
    $MAIN .= "<td id=bord_tbrl align=center rowspan=6>по группе</td>";

  $numc1 = $numc - 2;
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=$numc1>Средний балл</td>";
  $avg = str_replace(".", ",", $row['AVGBALL']);
  $MAIN .= "<td id=bord_r align=center>$avg</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=$numc1>Повышенных оценок, %</td>";
  $kups = str_replace(".", ",", $row['KUSP']);
  $MAIN .= "<td id=bord_r align=center>$kusp</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=$numc1>Сдавших на 4 и 5, чел</td>";
  $MAIN .= "<td id=bord_r align=center>{$row['SUM45']}</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=$numc1>Неатестованных, чел</td>";
  $MAIN .= "<td id=bord_r align=center>{$row['SUMNEG']}</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  $MAIN .= "<td id=bord_b colspan=$numc1>Общ. успеваемость, %</td>";
  $gusp = str_replace(".", ",", $row['GUSP']);
  $MAIN .= "<td id=bord_br align=center>$gusp</td>";
  $MAIN .= "</tr>";
}

$MAIN .= "</table>";
sst('sgroup.php?svodka=1');

getdbrow("VSAI_DONE()",$row);
echo $MAIN;
echo $DEBUG;
//echo $_SESSION['error'];
?>
</body> 
</html>