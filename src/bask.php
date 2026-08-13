<?php
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
  if($fl)
    dcgoto('student.php');
}


  getp('newdoc');
  getp('doc_name');
  getp('doc_desc');
  getp('doc_id');
  getp('stat_id');
  getp('fp');
  getdt('gfp_x','fp');



if(isset($_GET['zachisl'])){
  $MAIN = '';

  if(isset($_SESSION['zach_st']))
    $stat_id = $_SESSION['zach_st'];
  if(isset($_SESSION['zach_dt']))
    $fp = $_SESSION['zach_dt'];
  if($newdoc){
    head('Создание проекта приказа по личному составу');
    newdoc('&zachisl=1');
  }
  if(!$doc_id){
    head('Выбор проекта приказа по личному составу');
    getdoc('&zachisl=1');
  }
  head('Зачисление студента');
  if($cancel)
    dcgoto("{$__routedurlpage__}");
  if($ok){
    $_SESSION['zach_st'] = $stat_id;
    $_SESSION['zach_dt'] = $fp;
    i2b($doc_id);
    i2b($stat_id);
    d2b($fp);
    getdbrow('BASKET_INIT()',$row);
    $cid = $row['CONN_ID'];
    foreach($_SESSION['bask'] as $k=>$n)
      if($k)
        getdbrow("BASKET_ADD($cid,$n)",$row);

    getdbrow("BASKET_STUDZACH({$_SESSION['co_sgroup']},$doc_id, $stat_id, $fp)", $row);
    if($row['RES'] == 1){
//          $_SESSION['sgrm1'] = 1;  //неактивные студенты
      $mess = urlencode('Студенты включены в приказ по личному составу.');
      if(isset($_POST['clb'])){
        $_SESSION['bask'] = array();
        $_SESSION['bask'][] = 0;
        $_SESSION['baskc'] = 0;
      }
      dcgoto("{$__routedurlpage__}?mess=$mess");
    }
  }
  else{
    $MAIN .= "<table><form method=post>";
    $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
    $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
    pole('Причина','stat_id',20,'STUDSTATUS_LST(1)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
    pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
    $clb = 1;
    pole("Сбросить корзину",'clb',1);
    $MAIN .= "<tr><td align=right><input type=submit name=ok value='Принять'> </td>";
    $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
    $MAIN .= "</tr></form></table>";
    mainpaint();
  }
}

if(isset($_GET['otchisl'])){
  $MAIN = '';

  if(isset($_SESSION['otch_st']))
    $stat_id = $_SESSION['otch_st'];
  if(isset($_SESSION['otch_dt']))
    $fp = $_SESSION['otch_dt'];
  if($newdoc){
    head('Создание проекта приказа по личному составу');
    newdoc('&otchisl=1');
  }
  if(!$doc_id){
    head('Выбор проекта приказа по личному составу');
    getdoc('&otchisl=1');
  }
  head('Отчисление студента');
  if($cancel)
    dcgoto("{$__routedurlpage__}");
  if($ok){
    $_SESSION['otch_st'] = $stat_id;
    $_SESSION['otch_dt'] = $fp;
    i2b($doc_id);
    i2b($stat_id);
    d2b($fp);
    getdbrow('BASKET_INIT()',$row);
    $cid = $row['CONN_ID'];
    foreach($_SESSION['bask'] as $k=>$n)
      if($k)
        getdbrow("BASKET_ADD($cid,$n)",$row);

    getdbrow("BASKET_STUDOTCH($doc_id, $stat_id, $fp)", $row);
    if($row['RES'] == 1){
//          $_SESSION['sgrm1'] = 1;  //неактивные студенты
      $mess = urlencode('Студенты включены в приказ по личному составу.');
      if(isset($_POST['clb'])){
        $_SESSION['bask'] = array();
        $_SESSION['bask'][] = 0;
        $_SESSION['baskc'] = 0;
      }
      dcgoto("{$__routedurlpage__}?mess=$mess");
    }
  }
  else{
    $MAIN .= "<table><form method=post>";
    $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
    $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
    pole('Причина','stat_id',20,'STUDSTATUS_LST(0)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
    pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
    $clb = 1;
    pole("Сбросить корзину",'clb',1);
    $MAIN .= "<tr><td align=right><input type=submit name=ok value='Принять'> </td>";
    $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
    $MAIN .= "</tr></form></table>";
    mainpaint();
  }
}



if(isset($_GET['perevod'])){
  getdbrow('BASKET_INIT()',$row);
  $cid = $row['CONN_ID'];
  foreach($_SESSION['bask'] as $k=>$n)
    if($k)
      getdbrow("BASKET_ADD($cid,$n)",$row);
  getdbrow("BASKET_STUDGROUP_CNG_TEST()", $row);
  if(isset($row['RES']) && $row['RES'] == 1){
    getp('sgr_id');
    if(!$sgr_id){
      head('Выбор группы для перевода:');
      getdbmass("STUDGROUP_LST({$_SESSION['bask'][1]})", $mass);
      $n=0;
      $r=0;
      $mcol=3;
      $width = floor(100 / $mcol);
      $MAIN .= "<table width=100%>";
      while(getrow($mass,$row)){
        $n++;
        if(!(($n-1)%$mcol)){
          $r++;
          $MAIN .= '<tr>';
        }
        $rcolor = "id=col2";
        if($r%2)
          $rcolor = "id=col1";
        $MAIN .= "<td width=1% $rcolor>$n</td>";
        $MAIN .= "<td $rcolor width=$width%><a href='{$__routedurlpage__}?perevod=1&sgr_id={$row['SGROUP_ID']}'>{$row['SGROUPAUTONAME']} ({$row['SGROUP_PERIOD']})</a></td>";
        if(!($n%$mcol))
          $MAIN .= '</tr>';
      }
      while($n%$mcol){
        $MAIN .= "<td width=1% $rcolor></td>";
        $MAIN .= "<td width=$width% $rcolor></td>";
        $n++;
      }
      $MAIN .= '</table>';
      mainpaint();
    }
    i2b($sgr_id);
    getdbrow("BASKET_STUDGROUP_CNG($sgr_id)", $row);
    if($row['RES'] == 1){
      $mess = urlencode('Студенты успешно переведены.');
      dcgoto("{$__routedurlpage__}?mess=$mess");
    }
    else {
      $mess = urlencode('Ошибка! Студенты не переведены.');
      dcgoto("{$__routedurlpage__}?ermess=$mess");
    }
  }
  else{
    $mess = urlencode('Студенты из разных потоков не могут быть переведены.');
    dcgoto("{$__routedurlpage__}?ermess=$mess");
  }
}


if(isset($_GET['delbask'])){
  $key = array_search($_GET['delbask'], $_SESSION['bask']);
  if($key)
    unset($_SESSION['bask'][$key]);
//  foreach($_SESSION['bask'] as $k=>$n)
//    echo "$k>$n<br>";
}

if(isset($_GET['clearbask'])){
  $_SESSION['bask'] = array();
  $_SESSION['bask'][] = 0;
  $_SESSION['baskc'] = 0;
}

getdbrow('BASKET_INIT()',$row);
$cid = $row['CONN_ID'];
foreach($_SESSION['bask'] as $k=>$n)
  if($k)
    getdbrow("BASKET_ADD($cid,$n)",$row);
head('Корзина');
getdbmass("BASKET_LST($cid)",$mass);
messall($mass);
$MAIN .= "<table width=100%>";
$MAIN .= "<tr id=head>";
$MAIN .= "<td>№</td><td>ФИО</td><td>Отделение</td><td>Группа</td><td><img $P_DELT alt='удалить'></td>";
$MAIN .= "</tr>";
$n=0;
while(getrow($mass,$row)){
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
  $MAIN .= "<td><a href='bask.php?goto=1&country={$row['COUNTRY_ID']}";
  $MAIN .= "&region={$row['REGION_ID']}&city={$row['CITY_ID']}";
  $MAIN .= "&school={$row['SCHOOL_ID']}&facultet={$row['FACULTET_ID']}";
  $MAIN .= "&division={$row['DIVISION_ID']}&sgroup={$row['SGROUP_ID']}";
  $MAIN .= "&student={$row['STUDSGRP_ID']}'>";
  $MAIN .= "    {$row['STUDENT_LNAME']}
                {$row['STUDENT_FNAME']}
                {$row['STUDENT_MNAME']}</a></td>";
  $MAIN .= "<td>{$row['DIVISION_ABBR']}</td>";
  $MAIN .= "<td>{$row['SGROUP_AUTONAME']} ({$row['SGROUP_PERIOD']})</td>";
  $MAIN .= "<td><a href='{$__routedurlpage__}?delbask={$row['STUDSGRP_ID']}'><img $P_DEL alt='удалить'></a></td>";
  $MAIN .= "</tr>";
  if(($n >= $MAXREC) && (!isset($_GET['allview'])))
    break;
}
$MAIN .= "</table><br>";
if($_SESSION['baskc']){
  $MENU .= "<a href='{$__routedurlpage__}?clearbask=1'>Сброс</a><br>";
  $MENU .= "<a href='{$__routedurlpage__}?zachisl=1'>Зачислить</a><br>";
  $MENU .= "<a href='{$__routedurlpage__}?otchisl=1'>Отчислить</a><br>";
  $MENU .= "<a href='{$__routedurlpage__}?perevod=1'>Группа</a><br>";
}
mainpaint();
?>