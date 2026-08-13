<?php

if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"vipiska.xls\";");

include "global.php";
sst('student.php');
getp('type');

$numc = 5;
$MAIN .= "<table id=t_mprog>";
//$MAIN .= "<table id=id=tabotchet>";
$MAIN .= "<tr><td id=width1></td><td colspan=2 id=width13></td><td id=width1></td><td id=width3></td></tr>";

getdbrow("STUDENT_ITM({$_SESSION['co_student']})", $row);

$MAIN .= "<tr><td id=big colspan=$numc>{$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}</td></tr>";
$MAIN .= "<tr><td id=big colspan=$numc>За время обучения сдал(а) зачеты, промежуточные и итоговые экзамены по следующим дисциплинам:</td></tr>";
getdbmass("REP_STUDACAD_LST({$_SESSION['co_student']})", $mass);
$MAIN .= "<tr id=head>";
$MAIN .= "<td>№</td>";
$MAIN .= "<td colspan=2>Наименование дисциплины</td>";
$MAIN .= "<td>Общее кол-во часов</td>";
$MAIN .= "<td>Итоговая оценка</td>";
$MAIN .= "</tr>";

$n = 0;
$s = 0;
while(getrow($mass, $row))
{
  $n++;
  $MAIN .= "<tr>";
  $MAIN .= "<td>$n</td>";
  $MAIN .= "<td colspan=2>{$row['SUBJ_NAME']}</td>";
  $MAIN .= "<td>{$row['VOLUME']}</td>";
  $s += $row['VOLUME'];
  $MAIN .= "<td>{$row['RESULT_NAME']}</td>";
  $MAIN .= "</tr>";
}
$MAIN .= "<tr>";
$MAIN .= "<td colspan=3><b>Всего</b></td>";
$MAIN .= "<td>$s</td>";
$MAIN .= "<td></td>";
$MAIN .= "</tr>";

getdbmass("REP_STUDKR_LST({$_SESSION['co_student']})", $mass);
if($mass->num_rows){
  $MAIN .= "<tr><td id=big colspan=$numc><br>За время обучения защитил(а) следующие курсовые проекты (работы):</td></tr>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td>";
  $MAIN .= "<td>Дисциплина</td>";
  $MAIN .= "<td>Тема</td>";
  $MAIN .= "<td>Часов</td>";
  $MAIN .= "<td>Итоговая оценка</td>";
  $MAIN .= "</tr>";

  $n = 0;
  $s = 0;
  while(getrow($mass, $row))
  {
    $n++;
    $MAIN .= "<tr>";
    $MAIN .= "<td>$n</td>";
    $MAIN .= "<td>{$row['SUBJ_NAME']}</td>";
    $MAIN .= "<td>{$row['PERSNAME_NAME']}</td>";
    $MAIN .= "<td>{$row['VOLUME']}</td>";
    $s += $row['VOLUME'];
    $MAIN .= "<td>{$row['RESULT_NAME']}</td>";
    $MAIN .= "</tr>";
  }
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=3><b>Всего</b></td>";
  $MAIN .= "<td>$s</td>";
  $MAIN .= "<td></td>";
  $MAIN .= "</tr>";
}

$MAIN .= "</table>";

sst('student.php');
echo $MAIN;
echo $DEBUG;
?>
</body> 
</html>