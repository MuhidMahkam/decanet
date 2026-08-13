<?php
include "global.php";
if(isset($_GET['sgroup_id'])){
  getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
  $_SESSION['mpyear'] = $row['STREAM_FROMYEAR'];
}
unset($_SESSION['ref_doc_id']);
$sgrm = array('Группа:','состав', 'успеваемость');
$sgrm1 = array('Студенты:','активные', 'отчисленные', 'все');
$MAIN .= menu('sgrm');
$sgr = getTFN($_SESSION['sgrm1']);
if($_SESSION['sgrm'] == 0){
  if($add){
    $MAIN = '';
    if(isset($_SESSION['zach_st']))
      $stat_id = $_SESSION['zach_st'];
    if(isset($_SESSION['zach_dt']))
      $fp = $_SESSION['zach_dt'];
    getp('eduf_id');
    getp('doc_id');
    getp('stat_id');
    getp('fp');
    getdt('gfp_x','fp');
    getp('pno');
    getp('fn');
    getp('mn');
    getp('ln');
    getp('newdoc');

    if($newdoc){
      head("Создание проекта приказа по личному составу");
      newdoc('&add=1');
    }
    if(!$doc_id){
      head("Выбор проекта приказа по личному составу");
      getdoc('&add=1');
    }
    head("Включение студента в проект приказа по личному составу");

    if($cancel)
      dcgoto($__routedurlpage__);
    if($ok){
      $_SESSION['zach_st'] = $stat_id;
      $_SESSION['zach_dt'] = $fp;
      i2b($eduf_id);
      i2b($doc_id);
      i2b($stat_id);
      d2b($fp);
      s2b($pno);
      s2b($fn);
      s2b($mn);
      s2b($ln);
      getdbrow("STUDENT_ADD({$_SESSION['co_sgroup']},$eduf_id,$doc_id,$stat_id,$fp,$pno,$fn,$mn,$ln)", $row);
      if($row['RES']){
        $mess = urlencode('Студент включен в проект приказа по личному составу');
        dcgoto("{$__routedurlpage__}?mess=$mess");
      }
      else{
        $mess = urlencode('Ошибка! Студент не включен в проект приказа по личному составу');
        dcgoto("{$__routedurlpage__}?ermess=$mess");
      }
    }
    else{
      formb();
      $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
      pole('Форма обучения','eduf_id',20,'EDUFORM_LST()','EDUFORM_NAME','EDUFORM_ID',true,false);
      pole('Причина','stat_id',20,'STUDSTATUS_LST(1)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
      pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
      pole('Личный №','pno',80);
      pole('Фамилия','ln',80);
      pole('Имя','fn',80);
      pole('Отчество','mn',80);
      forme();
      mainpaint();
    }
  }
  else{
    $MAIN .= menu('sgrm1');
    $MENU .= "<a href={$__routedurlpage__}?add=1><img $P_ADD alt='Добавить'> студента</a><br>";
    $MENU .= "<a href='listgrp.php?type=1&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href=listgrp.php?type=1>\"Список 1\"</a><br>";
    $MENU .= "<a href='listgrp.php?type=2&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href=listgrp.php?type=2>\"Список 2\"</a><br>";
    $MENU .= "<a href='listgrp.php?type=3&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href=listgrp.php?type=3>\"Список 3\"</a><br>";
    $MENU .= "<a href='listgrp.php?type=4&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href=listgrp.php?type=4>\"БланкВед\"</a><br>";
    listobj(7); // список студентов в группе
  }
}
else{
  getp('mp_id');
  getp('mps_id');
  if($mp_id){
    if($mps_id){
      if($ok)
        getdbrow("SGRPPROGSUBJ_CNG({$_SESSION['co_sgroup']}, $mp_id, $mps_id)",$row);
      elseif(!$cancel){
        formb();
        $MAIN .= 'Установить дисциплину из набора всей группе?';
        forme();
        mainpaint();
      }
    }

  //изменение дисциплины по выбору
    if(isset($_GET['ch_pp']) && isset($_GET['pp_id']))
      getdbmass("PPROGSUBJ_CNG({$_GET['pp_id']},{$_GET['ch_pp']})", $mass);

    if(isset($_GET['change_pp']) && isset($_GET['pp_id']) && isset($_GET['mp_id'])){
      $pp_id = $_GET['pp_id'];
      $mp_id = $_GET['mp_id'];
      head('Выбор дисциплины из набора');
      getdbmass("MPROGITEM_LST($mp_id)", $mass);
      messall($mass);
      $MAIN .= "<table width='100%'>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "<td>Дисциплина</td>";
      $MAIN .= "</tr>";
      $n=0;
      while(getrow($mass, $row)){
        $n++;
        $rcolor = "id=col2";
        if($n%2)
          $rcolor = "id=col1";
        $MAIN .= "<tr $rcolor>";
        getp('ret');
        $MAIN .= "<td><a href='sgroup.php?pp_id=$pp_id&ch_pp={$row['MPROGSUBJ_ID']}&mp_id=$mp_id'>{$row['SUBJ_NAME']}</a></td>";
        $MAIN .= "</tr>";
        if(($n >= $MAXREC) && (!isset($_GET['allview'])))
          break;
      }
      $MAIN .= "</table>";
      mainpaint();
    }


//    head('Данные академической успеваемости группы');

//академ. успеваемость группы по выбранной программе
    if(!isset($_SESSION['cursem']) || ($_SESSION['cursem'] < 0))
      $_SESSION['cursem'] = 0;
    $cs = a2r($_SESSION['cursem'] + 1);
    $MAIN .= "$cs семестр ";
    $abbr = false;
    getdbrow("MPROGITEM_CNT($mp_id)", $row);
    if($row['CNT'] > 1){
      $abbr = true;
      $MAIN .= "Дисциплина по выбору: ";
      }
    else
      $MAIN .= "Дисциплина: ";
    getdbmass("MPROGITEM_LST($mp_id)", $mass);
    $cn = $vol = '';
    $first = true;
    $menu = '';
    while(getrow($mass, $row)){
      if(!$first && $abbr)
        $MAIN .= ", ";
      $first = false;
      $contr = $row['CONTROL_NAMED'];
      if($abbr){
        $MAIN .= $row['SUBJ_ABBR'];
        $menu .= "<a href='{$__routedurlpage__}?mps_id={$row['MPROGSUBJ_ID']}&mp_id=$mp_id'>Всем {$row['SUBJ_ABBR']}</a><br>";
      }
      else
        $MAIN .= $row['SUBJ_NAME'];
      $cn = $row['CONTROL_NAME'];
      $vol = $row['VOLUME'];
    }
    $MAIN .= " ($cn) часов: $vol<br>";

    
//Выдача ведомости
    $MENU .= "<a href='docum.php?type=1&mp_id=$mp_id'>\"Ведомость\"</a><br>";
    if($contr){
      $MENU .= "<a href='docum.php?type=12&mp_id=$mp_id'>\"Ведомость_тем\"</a><br>";
    }

    $MENU .= $menu;
//Отчет
    $MENU .= "<a href='otchet.php?mp_id=$mp_id&excel=1'><img $P_EXL alt='excel'></a>";
    $MENU .= "<a href='otchet.php?mp_id=$mp_id'>\"Успеваемость\"</a><br>";

    if($contr){
      $MENU .= "<a href='otchet.php?mp_id=$mp_id&excel=1&tem=1'><img $P_EXL alt='excel'></a>";
      $MENU .= "<a href='otchet.php?mp_id=$mp_id&tem=1'>\"Темы\"</a><br>";
    }

    getdbmass("GRPACADMPROG_LST({$_SESSION['co_sgroup']},$mp_id,$sgr)", $mass);
    messall($mass);
    $n = $nn = $sid = 0;
    $MAIN .= "<table width='100%'>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>№</td>";
    $MAIN .= "<td>ФИО</td>";
    if($abbr)
      $MAIN .= "<td>Дисциплина</td>";
    $MAIN .= "<td>Оценка</td>";
    $MAIN .= "<td>Тип док.</td>";
    $MAIN .= "<td>№ док.</td>";
    $MAIN .= "<td>Дата док.</td>";
    $MAIN .= "</tr>";

    while(getrow($mass, $row))
    {
      $n++;
      $dolg = false;
      if(!$row['RESULT_PASSFLAG'])
        $dolg = true;
      $rcolor = "id=col2";
      if($dolg)
        $rcolor = "id=col4";
      if($n%2){
        $rcolor = "id=col1";
        if($dolg)
          $rcolor = "id=col3";
      }
      $MAIN .= "<tr $rcolor>";
      if($row['STUDSGRP_ID'] != $sid){
        $sid = $row['STUDSGRP_ID'];
        $nn++;
        $MAIN .= "<td>$nn</td>";
        $MAIN .= "<td><a href='student.php?stm=2&student_id=$sid&pp_id={$row['PERSPROG_ID']}'>";
        $MAIN .= "{$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}";
        $MAIN .= "</a></td>";
        }
      else
        $MAIN .="<td></td><td></td>";
      if($abbr)
        $MAIN .= "<td><a href='sgroup.php?change_pp=1&pp_id={$row['PERSPROG_ID']}&mp_id=$mp_id'>{$row['SUBJ_ABBR']}</a></td>";
      $MAIN .= "<td width=30>{$row['RESULT_ABBR']}</td>";
      $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
      $ret = $__routedurlpage__;
      if($_SERVER['QUERY_STRING'])
      $ret .= '?'.$_SERVER['QUERY_STRING'];
      $ret = urlencode($ret);

      $MAIN .= "<td><a href='doc.php?ret=$ret&doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
      $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
      $MAIN .= "</tr>";
      if(($n >= $MAXREC) && (!isset($_GET['allview'])))
        break;
    }
    $MAIN .= "</table>";
  
    mainpaint();
  }
  
  if(isset($_GET['prot'])){
    $ex = '';
    getp('excel');
    if($excel)
      $ex = "&excel=$excel";
    $MAIN .= "<form action='protokol.php?$ex' method=post>";
    if(!isset($_SESSION['cursem']) || ($_SESSION['cursem'] < 0))
      $_SESSION['cursem'] = 0;
    $cs = a2r($_SESSION['cursem'] + 1);
    head("Протокол за $cs семестр.");
    head("Выбор фаз сессии для учёта при составлении протокола:");
    getdbmass("SESSPHASE_LST()", $mass);
    $n=0;
    while(getrow($mass,$row)){
      $n++;
      $MAIN .= "<input type=checkbox checked name=s$n value={$row['SESSPHASE_ID']}>{$row['SESSPHASE_NAME']}<br>";
    }
    $MAIN .= " <input type=submit name=ok value='Выбрать'>";
    $MAIN .= "</form>";
    mainpaint();
    
  }
  if(isset($_GET['svodka'])){
    $ex = '';
    getp('excel');
    if($excel)
      $ex = "&excel=$excel";
    $MAIN .= "<form action='svodka.php?$ex' method=post>";
    if(!isset($_SESSION['cursem']) || ($_SESSION['cursem'] < 0))
      $_SESSION['cursem'] = 0;
    $cs = a2r($_SESSION['cursem'] + 1);
    head("Сводка за $cs семестр:");

    $MAIN .= "<select name=sfase size=1>";
    $MAIN .= "<option value=NULL>Все";
    getdbmass("SESSPHASE_LST()", $mass);  
    while(getrow($mass, $row))
      $MAIN .= "<option value={$row['SESSPHASE_ID']}>{$row['SESSPHASE_NAME']}";
    $MAIN .= "</select> ";
    $MAIN .= "<input type=checkbox checked name=itogi value=1>Итоги ";
    $MAIN .= "<input type=checkbox name=blank value=1>Бланк ";
    $MAIN .= "<input type=checkbox name=setka value=1>Сетка ";
    $MAIN .= " <input type=submit name=ok value='Выбрать'>";

/*
    getdbmass("SESSPHASE_LST()", $mass);
    $MAIN .= "<a href='svodka.php?sfase=NULL$ex'>Все</a><br>";
    while(getrow($mass,$row)){
      $MAIN .= "<a href='svodka.php?sfase={$row['SESSPHASE_ID']}$ex'>{$row['SESSPHASE_NAME']}</a><br>";
    }
*/
    $MAIN .= "</form>";

    $MAIN .= "<br>Или выберите произвольный набор контрольных мероприятий:";
    $MAIN .= " <a href='{$__routedurlpage__}?svodka=1$ex&clear=1'>очистить все</a>";
    getp('clear');
    if($clear){
      $_SESSION['MPL'] = array();
      $_SESSION['MPL'][] = 0;
    }
    $MAIN .= "<form action='svodka.php?vs=1$ex' method=post>";
    getdbmass("VSAI_ALLMP_LST({$_SESSION['co_sgroup']})", $mass);
    $mpid = 0;
    $n=$r=0;
    $nn=0;
    $f=0;
    $mcol = 5;
    $width = 100/$mcol;
    $MAIN .= '<table><tr>';
    for($i=0;$i<$mcol;$i++)
      $MAIN .= "<td width=1%></td><td width=$width%></td>";
    $MAIN .= '</tr>';
    $sem=0;
    while(getrow($mass,$row)){
      if($row['SEMESTR'] != $sem){
        $sem = $row['SEMESTR'];
        $semr = a2r($sem);
        $MAIN .= '<tr>';
        $MAIN .= "<td colspan=$mcol><u><b>$semr семестр:</b></u></td>";
        $MAIN .= '</tr>';
        $n=$r=0;
      }
      $n++;
      $nn++;
      if(!(($n-1)%$mcol)){
        $r++;
        if($r > 1)
          $MAIN .= '</tr>';
        if($r%2)
          $rc = 1;
        else
          $rc = 2;
        $MAIN .= '<tr id=col{$rc}>';
      }

      if(array_search($row['MAINPROG_ID'], $_SESSION['MPL']))
        $check = 'checked';
      else
        $check = '';

      $MAIN .= "<td><input type=checkbox $check name=mp{$nn} value={$row['MAINPROG_ID']}></td>";
      if($row['CONTROL_ID'] == 1){
        $bold_b = '<b>';
        $bold_e = '</b>';
      }
      else{
        $bold_b = '';
        $bold_e = '';
      }
      if($row['SUBJSEL'] > 1)
        $ssel = '...';
      else
        $ssel = '';
      $MAIN .= "<td>$bold_b{$row['SUBJ_ABBR']}$ssel({$row['CONTROL_ABBR']})$bold_e</td>";

    }
    while($n%$mcol){
      $MAIN .= "<td></td><td></td>";
      $n++;
    }
    $MAIN .= "</tr>";
    $MAIN .= "</table>";
    $MAIN .= " <input type=checkbox checked name=itogi value=1>Итоги ";
    $MAIN .= " <input type=checkbox name=blank value=1>Бланк ";
    $MAIN .= " <input type=checkbox name=setka value=1>Сетка ";

    $MAIN .= " <input type=submit name=ok value='Выбрать'>";
    $MAIN .= "</form>";

    mainpaint();
  }

  //текущий семестр
  setcursem();
  $curs = $_SESSION['cursem'] + 1;

//-----------проверить работу этого блока !!!
  getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
  $_SESSION['mpyear'] = $row['STREAM_FROMYEAR'];
//-----------конец блока

  getdbrow("DSESSION_ITM({$_SESSION['co_division']}, {$_SESSION['mpyear']}, $curs)", $row);
  b2d($row['DSESSION_BEGDATE']);
  b2d($row['DSESSION_ENDDATE']);
  if(!$row['DSESSION_BEGDATE'])
    $row['DSESSION_BEGDATE'] = 'не указано ';
  if(!$row['DSESSION_ENDDATE'])
    $row['DSESSION_ENDDATE'] = 'не указано ';

    $dstype = $uyear = '';
    if(isset($row['DSESSTYPE']))
      $dstype = $row['DSESSTYPE'];
    if(isset($row['UYEAR']))
      $uyear = $row['UYEAR'];
    $MAIN .= "<b>$dstype сессия $uyear уч.года, начало:</b> {$row['DSESSION_BEGDATE']} <b>окончание:</b> {$row['DSESSION_ENDDATE']}<br>";

//  $MAIN .= "<b>{$row['DSESSTYPE']} сессия {$row['UYEAR']} уч.года, начало:</b> {$row['DSESSION_BEGDATE']} <b>окончание:</b> {$row['DSESSION_ENDDATE']}<br>";

    $usp = array('Успеваемость:','текущая','основная');
    $MAIN .= menu('usp');
    if($_SESSION['usp'])
      $usp = 'FALSE';
    else
      $usp = 'TRUE';

  getdbmass("GRPSEMMPROG_LST({$_SESSION['co_sgroup']}, $curs, $usp)", $mass);
  messall($mass);
  $MAIN .= "<table id=ofh width='100%'>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td>";
  $MAIN .= "<td>Название дисциплины</td>";
  $MAIN .= "<td>Аббр.</td>";
  $MAIN .= "<td>Контр.</td>";
  $MAIN .= "<td>Часов</td>";
  $MAIN .= "<td>Тип</td>";
  $MAIN .= "<td>№ док.</td>";
  $MAIN .= "<td>Дата</td>";
  $MAIN .= "</tr>";
  $n=1;
  $n = $nn = $mpid = 0;
  while(getrow($mass, $row))
  {
    $n++;
    $rcolor = "id=col2";
    if($n%2)
      $rcolor = "id=col1";
    $MAIN .= "<tr $rcolor>";
    if($row['MAINPROG_ID'] != $mpid){
      $mpid = $row['MAINPROG_ID'];
      $nn++;
      $MAIN .= "<td>$nn</td>";
      $MAIN .= "<td id=ofh><a href='sgroup.php?mp_id=$mpid'>{$row['SUBJ_NAME']}</a></td>";
      $MAIN .= "<td>{$row['SUBJ_ABBR']}</td>";
      $MAIN .= "<td>{$row['CONTROL_ABBR']}</td>";
      $MAIN .= "<td>{$row['VOLUME']}</td>";
      $MAIN .= "<td>{$row['DOCTYPE_ABBR']}</td>";
      $ret = $__routedurlpage__;
      if($_SERVER['QUERY_STRING'])
      $ret .= '?'.$_SERVER['QUERY_STRING'];
      $ret = urlencode($ret);
      $MAIN .= "<td><a href='doc.php?ret={$ret}&sgroup.php&doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
      $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
    }
    else
      $MAIN .="<td></td><td>{$row['SUBJ_NAME']}</td><td>{$row['SUBJ_ABBR']}</td><td></td><td></td><td></td><td></td><td></td>";
    $MAIN .= "</tr>";
    if(($n >= $MAXREC) && (!isset($_GET['allview'])))
      break;
  }
  $MAIN .= "</table>";
  $MENU .= "<a href='{$__routedurlpage__}?svodka=1&excel=1'><img $P_EXL alt='excel'></a>";
  $MENU .= "<a href='{$__routedurlpage__}?svodka=1'>\"Сводка\"</a> ";
  $MENU .= "<a href='{$__routedurlpage__}?prot=1?excel=1'><img $P_EXL alt='excel'></a>";
  $MENU .= "<a href='{$__routedurlpage__}?prot=1'>\"Протокол\"</a> ";
}
mainpaint();
?>