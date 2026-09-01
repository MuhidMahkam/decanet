<?php
$GL_begintime = microtime(1);
echo '<html>';
echo '<head>';
echo '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">';
echo '</head>';
if(isset($body))
  echo "$body";
else
  echo '<body>';

// если роутер не работает
if(!isset($__routedurlpage__))
  $__routedurlpage__ = $_SERVER['PHP_SELF'];

//конфигурация
include('config.php');

//стандартные функции
include('stdfunc.php');

//vendor
require_once __DIR__ . '/../vendor/autoload.php';

//запуск проверки регистрации
nsd();

//echo "NSD DONE.";

//глобальные переменные
$DBN  = 'decanet';
$VERSION  = 'версия 1.5';
if(isset($_SESSION['db_ver']))
  $VERSION .= $_SESSION['db_ver'];
$LOGO = "<a href='http://softintech/decanet.htm'><img src=dnllogo.gif alt=Деканет></a>";
//$COPYRIGHT = "<a href='http://softintech/index.htm'><img src=linelogo.gif alt=СофтИнТэк></a>";
$COPYRIGHT = "<a href='http://saxoft/index.htm'>(c)Saxoft</a>";
$OBJ = array('country','region','city','school','facultet','division','sgroup','student'); 

if(isset($_SESSION['MESS'])){
  $MESS = $_SESSION['MESS'];
  unset($_SESSION['MESS']);
}

if(isset($_SESSION['ERMESS'])){
  $ERMESS = $_SESSION['ERMESS'];
  unset($_SESSION['ERMESS']);
}

getp('addbask');
if($addbask){
  foreach($_POST as $k=>$n)
    if($k[0] == 's')
      if(!array_search($n, $_SESSION['bask'])){
        $_SESSION['bask'][] = $n;
        $_SESSION['baskc']++;
      }
}

if(isset($_SESSION['baskc'])){
  if(isset($_GET['delbask']) && array_search($_GET['delbask'], $_SESSION['bask']))
    $_SESSION['baskc']--;
  if(isset($_REQUEST['clearbask']))
    $_SESSION['baskc'] = 0;

//  if(isset($_REQUEST['addbask']) && (!array_search($_GET['addbask'], $_SESSION['bask'])))
//    $_SESSION['baskc']++;
}
if(isset($_SESSION['baskc']))
  $baskc = $_SESSION['baskc'];
else
  $baskc = 0;

$baskm = "Корзина($baskc)";
$glm = array('',$baskm,'Объект','Документы','Поиск','Ввод оценки','Пользователи', 'Помощь', 'Выход');
$MENU = menu('glm','',VERTICAL)."<br><hr>";
if(isset($_REQUEST['mess']))
  $MESS = $_REQUEST['mess'];
if(isset($_REQUEST['ermess']))
  $ERMESS = $_REQUEST['ermess'];


//прием get параметов
for($i = 0; $i<8; $i++)
  if(isset($_GET["{$OBJ[$i]}_id"])){
    if(!isset($_SESSION["du_{$OBJ[$i]}"])){
      $_SESSION["co_{$OBJ[$i]}"] = $_GET["{$OBJ[$i]}_id"];
      if($i == 6 && ($_SESSION['co_sgroup'] != @$_SESSION['old_group'])){
        $_SESSION['old_group'] = $_SESSION['co_sgroup'];
        getdbrow("CURSEM_ITM({$_SESSION['co_sgroup']})", $row);
        $_SESSION['cursem'] = $row['CURSEM'] - 1;
      }
    }
    for($j=$i+1; $j<8; $j++)
      if(!isset($_SESSION["du_{$OBJ[$j]}"]))
        unset($_SESSION["co_{$OBJ[$j]}"]);
    break;
  }

setobject();

function setobject(){
  global $OBJ,$OBJECT;
  $OBJECT = "не выбран";
  for($i=0; $i<8; $i++){
    $np = strtoupper($OBJ[$i]);
    $par = $par1 = "";
    if(isset($_SESSION["co_{$OBJ[$i]}"])){
      if($i == 0)
        $OBJECT = '';
      if(($i == 7) or !isset($_SESSION["du_{$OBJ[$i+1]}"])){
        $par = "<a href={$OBJ[$i]}.php>";
        $par1 = "</a>";
      }
      if(isset($_SESSION['du_id']) && isset($_SESSION["co_{$OBJ[$i]}"])){
        $co = $_SESSION["co_{$OBJ[$i]}"];
        getdbrow("{$np}_ITM({$co})", $row);
        $OBJECT .= $par.name($i,$row,true).$par1.".";
      }
    }
  }
}
//вернуть имя объекта в листе
function name($i, &$row, $t=false)
{
  global $OBJ;
  $np = strtoupper($OBJ[$i]);
  $name = "";
  switch($i)
  {
    case 0://страна
      $name = $row["{$np}_SNAME"];
      break;
    case 1://область
    case 2://город
    case 3://заведение
    case 4://факультет
    case 5://отделение
      if($t && (($i == 3) || ($i == 4))) // вверху пишем аббревиатуры для 3 и 4
        $name = $row["{$np}_ABBR"];
      else
        $name = $row["{$np}_NAME"];
      break;
    case 6://группа
      $name = $row["{$np}_AUTONAME"]." (".
              $row["{$np}_PERIOD"].")";
      break;
    case 7://студент
      $name = $row["{$np}_LNAME"]." ".
              $row["{$np}_FNAME"]." ".
              $row["{$np}_MNAME"];
      break;
  }
  return $name;
}


//список объектов 
function listobj($i)
{
  global $MAXREC, $MAIN, $MESS, $ERMESS, $MCNT, $OBJ, $P_DEL;
  global $__routedurlpage__;

  $np = strtoupper($OBJ[$i]);
  $par = "1";
  $par2 = "";
  if($i>0){//это не страна
    $par = $_SESSION["co_{$OBJ[$i-1]}"];
    if(!isset($par))
      return;
  }
  if($i == 5)//отделение
    $par2 = ', '.getTFN($_SESSION['fac1m']);
  if($i == 6)//группа
    $par2 = ', '.getTFN($_SESSION['div1m']);
  if($i == 7)//студент
    $par2 = ', '.getTFN($_SESSION['sgrm1']);
  $mcol=1;  //по умолчанию одна колонка
  if($i==1) // регионы в 3 колонки
    $mcol = 3;
  if($i==6) // группы в 3 колонки
    $mcol = 3;
  if($i==7) // студенты в 2 колонки
    $mcol = 2;


  getdbmass("{$np}_LST($par$par2)", $mass);
  messall($mass);
  $MAIN .= "<table width=100%>";
  $n=0;
  $r=0;
  $width = floor(100 / $mcol);
  while(getrow($mass, $row))
  {
    $n++;
    $red = false;
    if(($i==5) && ($row['DIVISION_ACTIVE'] == 0)) // отделения красим
      $red = true;
    if(($i==6) && ($row['SGROUP_ACTIVE'] == 0)) // группы красим
      $red = true;
    if(($i==7) && ($row['STUDENT_ACTIVE'] == 0)) // студентов красим
      $red = true;

    if(!(($n-1)%$mcol)){
      $r++;
      $MAIN .= '<tr>';
    }

    if($red){
      $rcolor = "id=col4";
      if($r%2)
        $rcolor = "id=col3";
    }
    else{
      $rcolor = "id=col2";
      if($r%2)
        $rcolor = "id=col1";
    }
    $MAIN .= "<td width=1% $rcolor>$n</td>";
    $del = '';
    if(($i == 6) && ($row['SCNT'] == 0))
      $del .= " <a href='{$__routedurlpage__}?sgid_del={$row['SGROUP_ID']}'><img $P_DEL alt='Удалить'></a>";
    $np1 = $np;
    if($np1 == 'STUDENT')
      $np1 = 'STUDSGRP';
    $MAIN .= "<td $rcolor width=$width%><a href={$OBJ[$i]}.php?{$OBJ[$i]}_id=".$row["{$np1}_ID"].">".name($i, $row)."</a>$del</td>";
    if(($n >= $MAXREC) && (!isset($_GET['allview'])))
      break;
  }  
  while($n%$mcol){
    $MAIN .= "<td width=1% $rcolor></td>";
    $MAIN .= "<td width=$width% $rcolor></td>";
    $n++;
  }
  $MAIN .= "</tr></table>";
}

$typedoc = array('Документ:','последний','за_месяц','все');
function getdoc($add){
  global $MAIN, $MENU, $MCNT, $typedoc, $MAXREC, $P_ADD;
  $proc = '';
//  $typedoc = array('Документ:','последний','за месяц','все');
  $MAIN .= menu('typedoc', '', HORIZONTAL, $add);
  switch($_SESSION['typedoc']){
    case 0: // последний
      if(isset($_SESSION['lastdoc_id']))
        $proc = "DOCUMENT_ITM({$_SESSION['lastdoc_id']})";
      break;
    case 1: // за месяц
      $proc = "LSDOC_LST({$_SESSION['co_facultet']})";
      break;
    case 2: // все
      $proc = "LSDOCALL_LST({$_SESSION['co_facultet']})";
      break;
  }
  if($proc != ''){
    getdbmass($proc, $mass);
    messall($mass);
  }
  $MAIN .= "<table width=100%>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td><td>Номер</td><td>Дата выдачи</td><td>Дата ввода</td><td>Название</td><td>Состояние</td>";
  $MAIN .= "</tr>";
  $n = 0;
  if($proc != '')
    while(getrow($mass, $row)){
      $n++;
      $rcolor = "id=col2";
      if($n%2)
        $rcolor = "id=col1";
      b2d($row['DOCUMENT_OUTDATE']);
      b2d($row['DOCUMENT_INDATE']);
      $MAIN .= "<tr $rcolor>";
      $MAIN .= "<td>$n</td>";
      if(($_SESSION['typedoc'] == 0) && ($row['DOCUMENT_TEMPFLAG'] == 0) )
        $MAIN .= "<td>{$row['DOCUMENT_NO']}</td>";      
      else
        $MAIN .= "<td><a href='{$__routedurlpage__}?{$_SERVER['QUERY_STRING']}&doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
      $MAIN .= "<td>{$row['DOCUMENT_OUTDATE']}</td>";
      $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
      $MAIN .= "<td>{$row['DOCUMENT_NAME']}</td>";
      $MAIN .= "<td>{$row['DOCUMENT_STATUS']}</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }
  $MAIN .= "</table>";
  $MENU .= "<a href='{$__routedurlpage__}?{$_SERVER['QUERY_STRING']}&newdoc=1'><img $P_ADD alt='Добавить'> приказ</a>";
  mainpaint();
}


function newdoc($add){
  global $MAIN, $ok, $cancel, $doc_name, $doc_desc;

  if($cancel)
    dcgoto("{$__routedurlpage__}?$add");

  if($ok){
    s2b($doc_name);
    s2b($doc_desc);
    getdbrow("LSDOC_ADD({$_SESSION['co_facultet']}, $doc_name, $doc_desc)", $row);
    $_SESSION['lastdoc_id'] = $row['RES'];
    dcgoto("{$__routedurlpage__}?$add");
  }


//  head('Ввод нового документа');
  $MAIN .= "<table><form name=newdoc id=page method=post>";
  $MAIN .= "<tr><td width=30%></td><td width=70%></td></tr>";
  pole('Название','doc_name',80);
  pole('Примечание','doc_desc',80);
  $MAIN .= "<tr><td align=right><input type=submit name=ok value='Принять'> </td>";
  $MAIN .= "<td><input type=submit name=cancel value='Отменить'><td>";
  $MAIN .= "</tr></form></table>";
  mainpaint();
}


function selobj(){
  global $OBJ;
  if(!isset($_SESSION['co_country']))
    dcgoto("earth.php");
  else{  
    for($i = 1; $i<8; $i++)
      if(!isset($_SESSION["co_{$OBJ[$i]}"])){
        //echo "GOTO:" . "{$OBJ[$i-1]}.php";
        dcgoto("{$OBJ[$i-1]}.php");
        //break;
        exit;
      }
    dcgoto('student.php');
    }
}

function setcursem($add1=''){
  global $MAIN, $cursem;
  getdbrow("SGROUPSEM_CNT({$_SESSION['co_sgroup']})", $row);
  $maxsem = $row['MAXSEM'];
  $fillsem = $row['FILLSEM'];
  $cursem = array();
  $cursem[] = 'Семестр:';
  for($i=1; $i<=$fillsem; $i++)
    $cursem[] = a2r($i);
  $add = '';
  for($i=$fillsem+1; $i<=$maxsem; $i++){
    $ir = a2r($i);
    $add .= "$ir ";
  }
  if(!isset($_SESSION['cursem']) || ($_SESSION['cursem'] < 0))
    $_SESSION['cursem'] = 0;
  $MAIN .= menu('cursem', $add.$add1);
  if($_SESSION['cursem'] > $fillsem - 1)
    $_SESSION['cursem'] = $fillsem - 1;
}


//обработка главного меню
if(isset($_GET['glm']))
  switch($_GET['glm']){
    case 0: //Корзина
      dcgoto("bask.php");
      break;
    case 1: //объект
      selobj();
      break;
    case 2: //документы
      dcgoto("doc.php");
      break;
    case 3: //поиск
      dcgoto("find.php");
      break;
    case 4: //ввод оценки
      dcgoto("vvod.php");
      break;
    case 5: //Пользователи
      dcgoto("admin.php");
      break;
    case 6: //помосчь
      dcgoto("dnhelp.html");
      break;
    case 7: //выход
      $_SESSION = array();
      session_destroy();
//      dcgoto("//{$_SERVER['HTTP_HOST']}");
      dcgoto("login.php");
      break;
  }

function gtempl($fname){
  //$fn = "files/templ/{$_SESSION['co_facultet']}/$fname";
  $fn = __DIR__ . "/../templates/{$_SESSION['co_facultet']}/$fname";
  if(!file_exists($fn)){
    //$fn = "files/templ/0/$fname";
    $fn = __DIR__ . "/../templates/0/$fname";
      if(!file_exists($fn)){
        echo "Шаблон $fn не найден.";
        return false;
      }
  }
  return $fn;
}

//ввод основных значений
getp('ok');
getp('cancel');
getp('add');
getp('edit');
getp('del');


?>