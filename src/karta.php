<?php

if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"karta.xls\";");

include "global.php";
sst('student.php');
getp('type');

if($type == 1){
  getdbrow("SGROUPSEM_CNT({$_SESSION['co_sgroup']})", $row);
  $maxsem = $row['MAXSEM'];
  $lob = $maxsem / 2;
  if($lob<5)
    $lobs = "$lob годa";
  else
    $lobs = "$lob лет";
  if($lob==1)
    $lobs = '1 год';
  getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);
  $fobuch = $row['EDUTYPE_ABBR'];
  getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row);
  $gtn = $row['GOSTITLE_NAME'];
  $ssn = $row['SUBSPEC_NAME'];
  getdbrow("STUDADD_ITM({$_SESSION['co_student']})", $row);
  if($row['STUDENT_PHOTOPATH'])
    $sfp = "<img src='{$row['STUDENT_PHOTOPATH']}'>";
  else
    $sfp = 'фото<br>обучаемого';
  b2d($row['STUDENT_BIRTHDAY']);


/*
  $numc = 5;
  $MAIN .= "<table border id=t_mprog>";
  $MAIN .= "<tr><td id=width1></td><td id=width2></td><td id=width2></td>
    <td id=width8></td><td id=width4></td></tr>";

  getdbrow("STUDADD_ITM({$_SESSION['co_student']})", $row);
  $MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}</td></tr>";
  $MAIN .= "<tr><td id=left colspan=$numc>";
  $MAIN .= "Факультет: {$row['FACULTET_NAME']}<br>";
  $MAIN .= "Отделение: {$row['DIVISION_NAME']}<br>";
  $MAIN .= "Группа: {$row['SGROUP_AUTONAME']}<br>";
  $MAIN .= "</td></tr>";
  $MAIN .= "<tr><td id=big colspan=$numc>УЧЕБНАЯ КАРТОЧКА СТУДЕНТА</td></tr>";
  $MAIN .= "<tr><td id=left colspan=$numc>";
  $MAIN .= "Личное дело _________________<br>";
  getdbrow("STUDADD_ITM({$_SESSION['co_student']})", $row);
  $MAIN .= "Зачетная книжка №: {$row['STUDENT_ZACHNO']}<br>";
  $MAIN .= "Номер: {$row['STUDENT_PERSNO']}<br>";
  $MAIN .= "№ страховой книжки: {$row['STUDENT_STRAHNO']}<br>";
  $MAIN .= "№ паспорта: {$row['STUDENT_PASSPNO']}<br>";
  $MAIN .= "Фамилия: {$row['STUDENT_LNAME']}<br>";
  $MAIN .= "Имя: {$row['STUDENT_FNAME']}<br>";
  $MAIN .= "Отчество: {$row['STUDENT_MNAME']}<br>";
  b2d($row['STUDENT_BIRTHDAY']);
  $MAIN .= "Пол: {$row['STUDENT_SEX']} Дата рождения: {$row['STUDENT_BIRTHDAY']}<br>";
  $MAIN .= "Семейное положение: {$row['STUDENT_FAMSTATE']}<br>";
  $adr = '';
  if($row['STUDENT_POSTINDEX'])
   $adr = $row['STUDENT_POSTINDEX'].' ';
  if($row['COUNTRY_ID']){
    getdbrow("COUNTRY_ITM({$row['COUNTRY_ID']})", $row1);
    if($row1['COUNTRY_SNAME'])
      $adr .= $row1['COUNTRY_SNAME'].' ';
  }
  if($row['CITY_ID']){
    getdbrow("CITY_ITM({$row['CITY_ID']})", $row1);
    if($row1['CITY_NAME'])
      $adr .= 'г. '.$row1['CITY_NAME'].' ';
  }
  if($row['STUDENT_NPUNKT'])
    $adr .= $row['STUDENT_NPUNKT'].' ';
  if($row['STUDENT_STREET'])
    $adr .= 'ул. '.$row['STUDENT_STREET'].' ';
  if($row['STUDENT_BLDNO'])
    $adr .= 'д. '.$row['STUDENT_BLDNO'].' ';
  if($row['STUDENT_FLATNO'])
    $adr .= 'кв. '.$row['STUDENT_FLATNO'];
  $MAIN .= "Адрес: $adr<br>";

  $MAIN .="Форма обучения: {$row['EDUFORM_NAME']}<br>";
  $MAIN .="Приказы по личному составу:<br>";

  getdbmass("STUDCONT_LST({$_SESSION['co_student']})", $mass);
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td>";
  $MAIN .= "<td>Номер</td>";
  $MAIN .= "<td>Дата</td>";
  $MAIN .= "<td>Статус</td>";
  $MAIN .= "<td>Значение</td>";
  $MAIN .= "</tr>";

  $n = 0;
  while(getrow($mass, $row))
  {
    $n++;
    $MAIN .= "<tr>";
    $MAIN .= "<td>$n</td>";
    $MAIN .= "<td>{$row['DOCUMENT_NO']}</td>";
    b2d($row['DOCUMENT_INDATE']);
    $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
    $MAIN .= "<td>{$row['STUDSTATUS_NAME']}</td>";
    $MAIN .= "<td>{$row['STUDSTATUS_VALUE']}</td>";
    $MAIN .= "</tr>";
  }
  $MAIN .= "</table>";
//  $MAIN .= "<p id=brpage><p>";
*/
}

if($type == 4){
  getdbrow("SGROUPSEM_CNT({$_SESSION['co_sgroup']})", $row);
  $fillsem = $row['FILLSEM'];
  $maxsem = $row['MAXSEM'];
  $semestr=1;
  $kurs=1;
  $kurs1=1;
  $incf = gtempl("kart{$type}.htm");
  if($incf)
    while($semestr <= $fillsem){
      if($semestr >= ($maxsem - 1))
        $kurs1 = '';
      else
        $kurs1 = $kurs + 1;
      getdbrow("DSESSION_ITM({$_SESSION['co_division']}, {$_SESSION['mpyear']}, $semestr)", $row);
      $year = $row['UYEAR'];
      $incf = gtempl("kart{$type}.htm");
      include $incf;
      $semestr = $semestr + 2;
      $kurs++;

    }
  exit;
}

$incf = gtempl("kart{$type}.htm");
if($incf)
  include $incf;

/*
if($type == 5){
  $numc = 7;
  $MAIN .= "<table id=t_mprog>";
  $MAIN .= "<tr><td id=width1></td><td id=width8></td><td id=width2></td>
    <td id=width4></td><td id=width1></td><td id=width15></td><td id=width2></td></tr>";

  getdbrow("STUDENT_ITM({$_SESSION['co_student']})", $row);
  $MAIN .= "<tr><td id=left colspan=$numc>УЧЕБНАЯ КАРТОЧКА  {$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}</td></tr>";

  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td><td>Название дисциплины</td><td>Часов</td><td>Оценка</td><td>Док</td><td>№</td><td>Дата</td>";
  $MAIN .= "</tr>";
  getdbmass("REP_STUDSEMACAD_LST({$_SESSION['co_student']})", $mass);
  $n = 0;
  $semestr = 0;
  $contr='';
  while(getrow($mass, $row))
  {
    $n++;
    if($semestr != $row['SEMESTR']){
      $semestr = $row['SEMESTR'];
      $MAIN .= "<tr><td id=podch colspan=$numc>Семестр: $semestr</td></tr>";
    }
    if($contr != $row['CONTROL_NAME']){
      $contr = $row['CONTROL_NAME'];
      $MAIN .= "<tr><td colspan=$numc>КОНТРОЛЬНОЕ МЕРОПРИЯТИЕ: $contr</td></tr>";
    }

    $bold = '';
    if(!$row['RESULT_PASSFLAG'])
      $bold = 'id=col3';
    $MAIN .= "<tr $bold>";
    $MAIN .= "<td>$n</td>";
    $MAIN .= "<td>{$row['SUBJ_NAME']}</td>";
    $MAIN .= "<td>{$row['VOLUME']}</td>";
    $MAIN .= "<td>{$row['RESULT_NAME']}</td>";
    $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
    $MAIN .= "<td>{$row['DOCUMENT_NO']}</td>";
    $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
    $MAIN .= "</tr>";
  }
  $MAIN .= "</table>";
}

sst('student.php');
echo $MAIN;
echo $DEBUG;
*/
?>
</body> 
</html>