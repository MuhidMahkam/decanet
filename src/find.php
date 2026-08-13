<?php

if(isset($_REQUEST['addbask']))
  $baskc;
include "global.php";

if(isset($_GET['goto'])){
  foreach ($OBJ as $v)
    if(isset($_GET[$v]))
      $$v = $_GET[$v];
    else
      $$v = 0;
  $fl = true;
  foreach ($OBJ as $v){
    if(isset($_SESSION["du_$v"]))
      if($_SESSION["du_$v"] != $$v){
        head('Доступ к выбранному студенту запрещен');
        $fl = false;
        break;
      }
    $_SESSION["co_$v"] = $$v;
  }
  if($fl){
    getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
    $_SESSION['mpyear'] = $row['STREAM_FROMYEAR'];
    dcgoto('student.php');
  }
}

$fm = array('Поиск:','студента','контингента','документа');
$MAIN .= menu('fm');


getp('sfy');
getp('sgr_an');
getp('pno');
getp('lname');
getp('fname');
getp('mname');
getp('stat');
getp('allview');
getp('sel');
getp('afac_id');
getp('adiv_id');
getp('ss_id');
getp('fp');
getdt('gfp_x','fp');
getp('tp');
getdt('gtp_x','tp');

getp('dtype');
getp('dno');
getp('dtflag');
getp('ddate');
getdt('gfp_x','ddate');
getp('dname');
getp('ddesc');
getp('doc');
getp('excel');
getp('ret');


if($ok && $_SESSION['fm'] == 0){
  if($sel)
    $chek = 'checked';
  else
    $chek = '';
     
  $add = '';
  if($afac_id)
    $add .= "&afac_id=$afac_id";
  if($afac_id)
    $add .= "&adiv_id=$adiv_id";
  if($sfy)
    $add .= "&sfy=$sfy";
  if($sgr_an){
    $sgr_an_e = urlencode($sgr_an);
    $add .= "&sgr_an=$sgr_an_e";
  }
  if($pno)
    $add .= "&pno=$pno";
  if($lname){
    $ln = urlencode($lname);
    $add .= "&lname=$ln";
  }
  if($fname){
    $fn = urlencode($fname);
    $add .= "&fname=$fn";
  }
  if($mname){
    $mn = urlencode($mname);
    $add .= "&mname=$mn";
  }
  if($stat)
    $add .= "&stat=$stat";

  if($allview)
    $add .= "&allview=1";

  i2b($afac_id);
  i2b($adiv_id);
  i2b($sfy);
  s2b($sgr_an);
  s2b($pno);
  s2b($lname);
  s2b($fname);
  s2b($mname);
  $statl = getTFN($stat);

  getdbmass("FND_STUD_LST($afac_id,$adiv_id,$sfy,$sgr_an,$pno,$fname,$mname,$lname,$statl)", $mass);
  messall($mass);
  $MAIN .= "<form method=post>";
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td><td>ФИО</td><td>ВУЗ</td><td>Факультет</td><td>Отделение</td><td>Группа</td>";
  $MAIN .= "<td><input type=submit name=addbask value='В корзину'></td>";
  $MAIN .= "</tr>";
  $n=0;
  while(getrow($mass, $row)){
    $n++;
    if($row['STUDENT_ACTIVE'] == 0){
      $rcolor = "id=col4";
      if($n%2)
        $rcolor = "id=col3";
    }
    else{
      $rcolor = "id=col2";
      if($n%2)
        $rcolor = "id=col1";
    }
    $MAIN .= "<tr $rcolor>";
    $MAIN .= "<td>$n</td>";
    $MAIN .= "<td><a href='find.php?goto=1&country={$row['COUNTRY_ID']}";
    $MAIN .= "&region={$row['REGION_ID']}&city={$row['CITY_ID']}";
    $MAIN .= "&school={$row['SCHOOL_ID']}&facultet={$row['FACULTET_ID']}";
    $MAIN .= "&division={$row['DIVISION_ID']}&sgroup={$row['SGROUP_ID']}";
    $MAIN .= "&student={$row['STUDSGRP_ID']}'>";
    $MAIN .= "    {$row['STUDENT_LNAME']}
                  {$row['STUDENT_FNAME']}
                  {$row['STUDENT_MNAME']}</a></td>";
    $MAIN .= "<td>{$row['SCHOOL_ABBR']}</td>";
    $MAIN .= "<td>{$row['FACULTET_ABBR']}</td>";
    $MAIN .= "<td>{$row['DIVISION_ABBR']}</td>";
    $MAIN .= "<td>{$row['SGROUP_AUTONAME']} ({$row['SGROUP_PERIOD']})</td>";
//    $MAIN .= "<td><a href='{$__routedurlpage__}?ok=1&addbask={$row['STUDSGRP_ID']}$add'><img $P_BASK alt='в корзину'></a></td>";
    $MAIN .= "<td align=center><input type=checkbox name=s{$row['STUDSGRP_ID']} value={$row['STUDSGRP_ID']} $chek></td>";
    $MAIN .= "</tr>";
    if(($n >= $MAXREC) && (!isset($_GET['allview'])))
      break;
  }
$MAIN .= "</table><br>";
$MAIN .= "</form>";
$MENU .= "<a href='{$__routedurlpage__}?sel=1&ok=1$add'>Пометить_все</a><br>";
$MENU .= "<a href='{$__routedurlpage__}?ok=1$add'>Сбросить_все</a><br>";
mainpaint();
}


if($ok && $_SESSION['fm'] == 1){

/*     
  $add = '';
  if($afac_id)
    $add .= "&afac_id=$afac_id";
  if($afac_id)
    $add .= "&adiv_id=$adiv_id";
  if($ss_id)
    $add .= "&ss_id=$ss_id";
  if($fp)
    $add .= "&fp=$fp";
  if($tp)
    $add .= "&tp=$tp";
  if($allview)
    $add .= "&allview=1";
*/

  i2b($afac_id);
  i2b($adiv_id);
  i2b($ss_id);
  d2b($fp);
  d2b($tp);

  getdbmass("FND_STUDCONT_LST($afac_id,$adiv_id,$ss_id,$fp,$tp)", $mass);
  messall($mass);
  $MAIN .= "<form method=post>";
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td><td>ФИО</td><td>ВУЗ</td><td>Факультет</td><td>Отделение</td><td>Группа</td>";
//  $MAIN .= "<td><input type=submit name=addbask value='В корзину'></td>";
  $MAIN .= "</tr>";
  $n=0;
  while(getrow($mass, $row)){
    $n++;
    if($row['STUDENT_ACTIVE'] == 0){
      $rcolor = "id=col4";
      if($n%2)
        $rcolor = "id=col3";
    }
    else{
      $rcolor = "id=col2";
      if($n%2)
        $rcolor = "id=col1";
    }
    $MAIN .= "<tr $rcolor>";
    $MAIN .= "<td>$n</td>";
    $MAIN .= "<td><a href='find.php?goto=1&country={$row['COUNTRY_ID']}";
    $MAIN .= "&region={$row['REGION_ID']}&city={$row['CITY_ID']}";
    $MAIN .= "&school={$row['SCHOOL_ID']}&facultet={$row['FACULTET_ID']}";
    $MAIN .= "&division={$row['DIVISION_ID']}&sgroup={$row['SGROUP_ID']}";
    $MAIN .= "&student={$row['STUDSGRP_ID']}'>";
    $MAIN .= "    {$row['STUDENT_LNAME']}
                  {$row['STUDENT_FNAME']}
                  {$row['STUDENT_MNAME']}</a></td>";
    $MAIN .= "<td>{$row['SCHOOL_ABBR']}</td>";
    $MAIN .= "<td>{$row['FACULTET_ABBR']}</td>";
    $MAIN .= "<td>{$row['DIVISION_ABBR']}</td>";
    $MAIN .= "<td>{$row['SGROUP_AUTONAME']} ({$row['SGROUP_PERIOD']})</td>";
//    $MAIN .= "<td><a href='{$__routedurlpage__}?ok=1&addbask={$row['STUDSGRP_ID']}$add'><img $P_BASK alt='в корзину'></a></td>";
//    $MAIN .= "<td align=center><input type=checkbox name=s{$row['STUDSGRP_ID']} value={$row['STUDSGRP_ID']} $chek></td>";
    $MAIN .= "</tr>";
    if(($n >= $MAXREC) && (!isset($_GET['allview'])))
      break;
  }
$MAIN .= "</table><br>";
$MAIN .= "</form>";
//$MENU .= "<a href='{$__routedurlpage__}?sel=1&ok=1$add'>Пометить_все</a><br>";
//$MENU .= "<a href='{$__routedurlpage__}?ok=1$add'>Сбросить_все</a><br>";
mainpaint();
}




getp('fid');

//доделать согласно правам пользователя !!!
$fid = $_SESSION['co_facultet'];

$dn = $dd = '';
if($dname)
  $dn = urlencode($dname);
if($ddesc)
  $dd = urlencode($ddesc);


if($ok && $_SESSION['fm'] == 2){ //документы
  i2b($fid);
  i2b($dtype);
  s2b($dno);
  unset($dtflag);
  getp('dtflag');
  $dtflag1 = getTFN($dtflag);
  d2b($ddate);
  s2b($dname);
  s2b($ddesc);
  getdbmass("FND_DOCUMENT_LST($fid,$dtype,$dno,$dtflag1,$ddate,$dname,$ddesc)",$mass);
  messall($mass);
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td>";
  $MAIN .= "<td>Тип</td>";
  $MAIN .= "<td>№ док-та</td>";
  $MAIN .= "<td>Издан</td>";
  $MAIN .= "<td>Завершен</td>";
  $MAIN .= "<td>Состояние</td>";
  $MAIN .= "<td>Название</td>";
  $MAIN .= "<td>Примечание</td>";
  $MAIN .= "</tr>";
  $n=0;
  while(getrow($mass,$row)){
    $n++;
    if($row['DOCUMENT_TEMPFLAG'] == 1){
      $rcolor = "id=col4";
      if($n%2)
        $rcolor = "id=col3";
    }
    else{
      $rcolor = "id=col2";
      if($n%2)
        $rcolor = "id=col1";
    }
    $MAIN .= "<tr $rcolor>";
    $MAIN .= "<td>$n</td>";
    $ret = "{$__routedurlpage__}?{$_SERVER['QUERY_STRING']}";
    $ret = urlencode($ret);
    $MAIN .= "<td>{$row['DOCTYPE_NAME']}</td>";
    $MAIN .= "<td><a href='doc.php?ret=$ret&doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
    $di = $row['DOCUMENT_INDATE'];
    $do = $row['DOCUMENT_OUTDATE'];
    b2d($di);
    b2d($do);
    $MAIN .= "<td>$do</td>";
    $MAIN .= "<td>$di</td>";
    $MAIN .= "<td>{$row['DOCUMENT_STATUS']}</td>";
    $MAIN .= "<td>{$row['DOCUMENT_NAME']}</td>";
    $MAIN .= "<td>{$row['DOCUMENT_DESC']}</td>";
    $MAIN .= "</tr>";
    if(($n >= $MAXREC) && (!isset($_GET['allview'])))
      break;
  }
  $MAIN .= "</table><br>";
  mainpaint();
}


$MAIN .= "<form method=get>";
$MAIN .= "<table width=100%>";
$MAIN .= "<tr><td width=40%></td><td width=60%></td></tr>";
$MAIN .= '<tr><td colspan=2 align=center><b>Введите параметры поиска:</b></td></tr>';
switch($_SESSION['fm']){
  case 0://студенты
    if($_SESSION['co_facultet'])
      $afac_id = $_SESSION['co_facultet'];
    pole('Факультет','afac_id',80,"FACULTET_LST({$_SESSION['co_school']})",'FACULTET_NAME','FACULTET_ID');
    if(isset($_SESSION['co_division']) && ($_SESSION['co_division']))
      $adiv_id = $_SESSION['co_division'];
    pole('Отделение','adiv_id',80,"DIVISION_LST({$_SESSION['co_facultet']}, NULL)",'DIVISION_NAME','DIVISION_ID');
    pole('Год поступления','sfy',10);
    pole('Группа','sgr_an',10);
    pole('Персональный №','pno',10);
    pole('Фамилия','lname',20);
    pole('Имя','fname',20);
    pole('Отчество','mname',20);
    $MAIN .="<tr><td align=center colspan=2>";
    $MAIN .="<span id=col4>Активные</span><input name=stat type=radio value=0 checked> ";
    $MAIN .="<span id=col4>Отчисленные</span><input name=stat type=radio value=1> ";
    $MAIN .="<span id=col4>Все</span><input name=stat type=radio value=2>";
    $MAIN .="</td></tr>";
    break;
  case 1://контингент
    if($_SESSION['co_facultet'])
      $afac_id = $_SESSION['co_facultet'];
    pole('Факультет','afac_id',80,"FACULTET_LST({$_SESSION['co_school']})",'FACULTET_NAME','FACULTET_ID');
    if(isset($_SESSION['co_division']) && ($_SESSION['co_division']))
      $adiv_id = $_SESSION['co_division'];
    pole('Отделение','adiv_id',80,"DIVISION_LST({$_SESSION['co_facultet']}, NULL)",'DIVISION_NAME','DIVISION_ID');
    pole('Статус','ss_id',80,"STUDSTATUS_LST(NULL)",'STUDSTATUS_NAME','STUDSTATUS_ID');
    pole("Начало",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
    pole("Окончание",'tp',10,'','','',true,true,true," <input type=image $P_CAL name=gtp>");
    break;
  case 2://документы
    pole('Тип','dtype',80,'DOCTYPE_LST()','DOCTYPE_NAME','DOCTYPE_ID');
    pole('Номер','dno',10);
    $MAIN .="<tr><td align=center colspan=2>";
    $MAIN .="<span id=col4>Проекты</span><input name=dtflag type=radio value=0> ";
    $MAIN .="<span id=col4>Завершенные</span><input name=dtflag type=radio value=1> ";
    $MAIN .="<span id=col4>Все</span><input name=dtflag type=radio value=2 checked>";
    $MAIN .="</td></tr>";

    pole("Дата после",'ddate',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");

    pole('Наименование','dname',80);
    pole('Примечание','ddesc',80);
    break;
}
$MAIN .= "<td align=right><input type=submit name=ok value='Поиск'></td>";
$MAIN .= "</tr></table></form>";
mainpaint();
?>