<?php
include "global.php";

getp('doc_id');
getp('doc_rev');
getp('ret');
if(!$ret)
  $ret = $__routedurlpage__;

if($doc_id){
  getdbrow("DOCUMENT_ITM($doc_id)",$row);
  $dtype1 = $row['DOCTYPE_ID'];
  $dtn = $row['DOCTYPE_NAME'];
  $dno1 = $row['DOCUMENT_NO'];
//  $doc_id = $row['DOCUMENT_ID'];
  $dtflag1 = $row['DOCUMENT_TEMPFLAG'];
  if($dtflag1 || $doc_rev){
    $vvod = true;
    $MAIN .= '<form method=post>';
  }
  else
    $vvod = false;
  $dstat = $row['DOCUMENT_STATUS'];
  $fp = $row['DOCUMENT_INDATE'];
  b2d($fp);
  $ddate1 = $row['DOCUMENT_OUTDATE'];
  b2d($ddate1);
  $dname1 = $row['DOCUMENT_NAME'];
  $ddesc1 = $row['DOCUMENT_DESC'];
}


getp('stat_id');
getp('fp');
getdt('gfp_x','fp');

getp('del_old');
if($del_old){
  head('Выберите дату с которой документы подлежат удалению:');
  if($cancel)
    dcgoto($ret);
  if($ok){
    d2b($fp);
    getdbrow("ACADOC_DEL({$_SESSION['co_facultet']},$fp)",$row);
    if(isset($row['RES'])&&($row['RES'] == 1)){
      $mess = urlencode('Документы удалены.');
      dcgoto("$ret?mess=$mess");
    }
    else {
      $mess = urlencode('Ошибка! Документы не удалены.');
      dcgoto("$ret?ermess=$mess");
    }
  }
  formb();
  pole("Дата удаления",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
  forme();
  mainpaint();
}

getp('sdoc_cng');
getp('st_id');

if($sdoc_cng){
  head('Изменение причины и даты');
  if($cancel)
    dcgoto("$ret?doc_id=$doc_id");
  if($ok){
    i2b($doc_id);
    i2b($st_id);
    i2b($stat_id);
    d2b($fp);
    getdbrow("STUDDOCCONT_CNG($st_id, $doc_id, $stat_id, $fp)",$row);
    dcgoto("$ret?doc_id=$doc_id");
  }
  formb();
  pole('Причина','stat_id',20,'STUDSTATUS_LST(NULL)','STUDSTATUS_NAME','STUDSTATUS_ID',true,false);
  pole("Дата",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
  forme();
  mainpaint();
}


getp('doc_close');
if($doc_close){
  getdbrow("DOCUMENT_ITM($doc_id)",$row);
  $dno1 = $row['DOCUMENT_NO'];
}

getp('cancelv');
getp('okv');
getp('dname1');
getp('ddesc1');
getp('dno1');
getp('doc_cng');


//удаление документа
fdel('doc_del','DOCUMENT_DEL','Удалить документ?');
if(isset($_REQUEST["okd"]) && isset($_REQUEST['doc_del']))
  dcgoto($ret);

//открытие документа
fdel('doc_open','DOCUMENT_OPEN','Перевести документ в состояние проекта?');
if(isset($_REQUEST["okd"]) && isset($_REQUEST['doc_open']))
  dcgoto("$ret?doc_id=$doc_id");

//удаление студента
fdel('dels','STUDDOCCONT_DEL','Удалить студента из документа?','',",$doc_id,$stat_id");


//if(isset($_REQUEST["okd"]) && isset($_REQUEST['dels']))
//  dcgoto("doc.php?doc_id=$doc_id");

//завершение
if($doc_close){
  if($cancel)
    dcgoto("doc.php?doc_id=$doc_id");
  if($ok){
    i2b($doc_close);
    s2b($dno1);
    d2b($fp);
    getdbrow("DOCUMENT_CLOSE($doc_id,$dno1,$fp)",$row);
    dcgoto("doc.php?doc_id=$doc_id");
  }
  formb();
  pole('Номер','dno1',10);
  pole("Дата завершения",'fp',10,'','','',true,true,true," <input type=image $P_CAL name=gfp>");
  forme();
  mainpaint();
}

/*
// имя/примечание
if($doc_cng){
  if($cancel)
    dcgoto("$ret?doc_id=$doc_id");
  if($ok){
    i2b($doc_cng);
    s2b($dname1);
    s2b($ddesc1);
    getdbrow("DOCUMENT_CNG($doc_id,$dname1,$ddesc1)",$row);
    dcgoto("$ret?doc_id=$doc_id");
  }
  formb();
  pole('Наименование','dname1',80);
  pole('Примечание','ddesc1',80);
  forme();
  mainpaint();
}
*/


if($doc_id){
/*
  if($cancel)
    dcgoto("$ret?doc_id=$doc_id");
  if($ok1){
    s2b($dname1);
    s2b($ddesc1);
    getdbmass("DOCUMENT_CNG($doc_id,$dname1,$ddesc1)",$mass);
    dcgoto("$ret?doc_id=$doc_id");
  }
*/
  if(($dtflag1 || $doc_rev) && (($dtype1 == 1) ||
     ($dtype1 == 8) ||
     ($dtype1 == 12) ||
     ($dtype1 == 2) ||
     ($dtype1 == 6)) 
  )
    $dno2 = "<input type=text name=dno2 value=$dno1>";
  else
    $dno2 = $dno1;

//  $MAIN .= "<b>$dtn №$dno2 $dname1 $ddesc1</b><br>";
  $MAIN .= "<b>$dtn №$dno2</b><br>";
  $MAIN .= "<b>Состояние:</b> $dstat <b>Дата издания:</b> $ddate1 <b>Дата завершения:</b> $fp<br>";

  switch($dtype1){
    case 1: // ведомость
    case 8: // ведомость должников
    case 12: // ведомость тем
      if($dtype1 == 8)
        $dolg = true;
      else
        $dolg = false;
      if($dtype1 == 12)
        $tem = true;
      else
        $tem = false;

      //ввод ведомости
      if($cancelv)
        if($doc_rev)
          dcgoto("doc.php?doc_id=$doc_id");
        else
          dcgoto($ret);
      if($okv){
        if($doc_rev)
          getdbrow("DOCUMENT_OPEN($doc_id)",$row);
        if($tem)
          getdbmass("TEMVED_LST($doc_id)", $mass);
        else
          getdbmass("EKZVED_LST($doc_id)", $mass);
        while(getrow($mass, $row)){
          $name = "res{$row['PERSPROG_ID']}";
          $namep = "pr{$row['PERSPROG_ID']}";
          if(isset($_POST[$name])){
            $res_id = $_POST[$name];
            if($tem){
              s2b($res_id);
              getdbrow("TEMVED_CNG($doc_id, {$row['PERSPROG_ID']}, $res_id)", $row1);
            }
            else
              getdbrow("EKZVED_CNG($doc_id, {$row['PERSPROG_ID']}, $res_id)", $row1);
          }
          if(isset($_POST[$namep])){
            $mprog_id = $_POST[$namep];
            getdbrow("EKZVEDMPS_CNG({$row['PERSPROG_ID']}, $mprog_id)", $row1);
          }
        }
        d2b($fp);
        getp('dno2');
        s2b($dno2);
        getdbrow("EKZVED_CLOSE($doc_id,$dno2,$fp)", $row);

        if($doc_rev)
          dcgoto("doc.php?doc_id=$doc_id");
        else
          dcgoto($ret);

      }

      getdbmass("EKZVED_ITM($doc_id)", $mass);
      getrow($mass,$row);
      $ssn = $row['SUBJ_NAME'];
      $abbr = false;
      $sem = $row['SEMESTR'];
      $docno = $row['DOCUMENT_NO'];
      $cname = $row['CONTROL_NAME'];
      $cid = $row['CONTROL_ID'];
      if(!$cid)
        $cid = 1;
      $sgan = $row['SGROUP_AUTONAME'];
      $sgp = $row['SGROUP_PERIOD'];
      $kurs = $row['KURS'];
      $vol = $row['VOLUME'];

      $MAIN .= "<b>Факультет:</b> {$row['FN']} <b>Отделение:</b> {$row['DN']}<br>";
      while(getrow($mass,$row)){
        $ssn .= ", ".$row['SUBJ_NAME'];
        $abbr = true;
      }
      if($dtype1 == 8)
        $dolg = true;
      else
        $dolg = false;
      $sem = a2r($sem);
      $grp = '';
      if(!$dolg){
        $grp .= "<b>Группа:</b> $sgan ($sgp) ";
      }
      $MAIN .= "$grp<b>Курс:</b> $kurs <b>Семестр:</b> $sem<br>";
      $MAIN .= "<b>Дисциплина:</b> $ssn ($cname) часов=$vol<br>";
      $MAIN .= "<table id=tabl1 border width=100%>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "  <td rowspan=2>№ пп</td>";
      $MAIN .= "  <td rowspan=2>№ зач.</td>";
      if($dolg)
        $MAIN .= "<td rowspan=2>Группа</td>";
      $MAIN .= "  <td rowspan=2>Фамилия и инициалы</td>";
      if($tem){
        $MAIN .= "  <td rowspan=2>Тема</td>";
        if($abbr)
          $MAIN .= "  <td rowspan=2>Дисциплина</td>";

      $MAIN .= "</tr><tr></tr>";
      }
      else{
        $MAIN .= "  <td rowspan=2>Оценка</td>";
        if($abbr)
          $MAIN .= "  <td rowspan=2>Дисциплина</td>";
        $MAIN .= "  <td align=center colspan=4>Предыдущая оценка</td>";
        $MAIN .= "</tr>";
        $MAIN .= "<tr id=head>";
        $MAIN .= "  <td>Оценка</td>";
        $MAIN .= "  <td>Тип</td>";
        $MAIN .= "  <td>Номер</td>";
        $MAIN .= "  <td>Дата</td>";
        $MAIN .= "</tr>";
      }
      $i = 1;
      if($tem)
        getdbmass("TEMVED_LST($doc_id)", $mass);
      else
        getdbmass("EKZVED_LST($doc_id)", $mass);
      $n = 0;
      getdbmass("CONTROLRESULT_LST($cid)", $massr);

      getdbmass("EKZVED_ITM($doc_id)", $massp);

      while(getrow($mass, $row)){
        $n++;
        $dolg1 = true;
        if($tem)
          $dolg1 = false;
        elseif($row['CURRES_PASSFLAG'])
          $dolg1 = false;
        elseif($row['RESULT_PASSFLAG'])
          $dolg1 = false;

        $rcolor = "id=col2";
        if($dolg1)
          $rcolor = "id=col4";
        if($n%2){
          $rcolor = "id=col1";
          if($dolg1)
            $rcolor = "id=col3";
        }
        $MAIN .= "<tr $rcolor>";
        $MAIN .= "  <td>$i.</td>";$i++;
        $MAIN .= "  <td>{$row['STUDENT_ZACHNO']}</td>";
        if($dolg)
          $MAIN .= "<td>{$row['SGROUPAUTONAME']}</td>";
        $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
        $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);
        $MAIN .= "  <td><a href='student.php?student_id={$row['STUDSGRP_ID']}'>{$row['STUDENT_LNAME']} $fn.$mn.</td>";
        $name = 'res'.$row['PERSPROG_ID'];
        $namep = 'pr'.$row['PERSPROG_ID'];

        if($tem){
          if($vvod){
            if(isset($_POST[$name]))
              $res = $_POST[$name];
            elseif($row['PERSNAME_NAME'])
              $res = $row['PERSNAME_NAME'];
            else
              $res = '';
            $MAIN .= "  <td>";
            $MAIN .= "<input type=text tabindex=$n size=80 name=$name value='$res'>";
            $MAIN .= "  </td>";
          }
          else
            $MAIN .= "  <td>{$row['PERSNAME_NAME']}</td>";
          if($abbr){
            if($vvod){
              $massp->data_seek(0);
              $option = "";
              while(getrow($massp, $rowp)){
                $sel = '';
                if($row['MPROGSUBJ_ID'] == $rowp['MPROGSUBJ_ID'])
                  $sel = 'selected';
                $option .= "<option $sel value='{$rowp['MPROGSUBJ_ID']}'>{$rowp['SUBJ_ABBR']}";
              }
              $MAIN .= "<td>";
              $MAIN .= "<select tabindex=$n name=$namep size=1>";
              $MAIN .= "$option";
              $MAIN .= "</select>";
              $MAIN .= "</td>";
            }
            else
              $MAIN .= "  <td>{$row['SUBJ_ABBR']}</td>";
          }
        }
        else{
          if($vvod){
            if(isset($_GET[$name]))
              $res = $_GET[$name];
            elseif(isset($_GET['res_id']))
              $res = $_GET['res_id'];
            elseif($row['CURRES_ID'])
              $res = $row['CURRES_ID'];
            else
              $res = 0;
            $option = "<option value=0>";
//            getdbmass("CONTROLRESULT_LST($cid)", $massr);
            $massr->data_seek(0);
            while(getrow($massr, $rowr)){
              $sel = '';
              if($res == $rowr['RESULT_ID'])
                $sel = 'selected';
              $option .= "<option $sel value='{$rowr['RESULT_ID']}'>{$rowr['RESULT_ABBR']}";
            }
            $MAIN .= "<td>";
            $MAIN .= "<select tabindex=$n name=$name size=1>";
            $MAIN .= "$option";
            $MAIN .= "</select>";
            $MAIN .= "</td>";
          }
          else
            $MAIN .= "  <td>{$row['CURRES_ABBR']}</td>";
          if($abbr){
            if($vvod){
              $massp->data_seek(0);
              $option = "";
              while(getrow($massp, $rowp)){
                $sel = '';
                if($row['MPROGSUBJ_ID'] == $rowp['MPROGSUBJ_ID'])
                  $sel = 'selected';
                $option .= "<option $sel value='{$rowp['MPROGSUBJ_ID']}'>{$rowp['SUBJ_ABBR']}";
              }
              $MAIN .= "<td>";
              $MAIN .= "<select tabindex=$n name=$namep size=1>";
              $MAIN .= "$option";
              $MAIN .= "</select>";
              $MAIN .= "</td>";
            }
            else
              $MAIN .= "  <td>{$row['SUBJ_ABBR']}</td>";
          }
          $MAIN .= "  <td>{$row['RESULT_ABBR']}</td>";
          $MAIN .= "  <td>{$row['DOCTYPE_ABBR']}</td>";
          $MAIN .= "  <td>{$row['DOCUMENT_NO']}</td>";
          $MAIN .= "  <td>{$row['DOCUMENT_INDATE']}</td>";

        }
        $MAIN .= "</tr>";
      }
      $MAIN .= "</table>";
      if($vvod){
        if(!$fp)
          $fp = date("d.m.Y");
        if($tem)
          $MAIN .= "<input type=hidden name=fp value=$fp>";
        else{
          $n++;
          pole("Дата сдачи",'fp',10,'','','',false,true,true," <input type=image $P_CAL name=gfp>");
        }
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
//        if($doc_rev)
//          $MAIN .= "<input type=hidden name=doc_rev value=$doc_rev>";
        $n++;
        $MAIN .= "<br><input tabindex=$n name=okv type=submit value='Принять'> ";
        $n++;
        $MAIN .= "<input tabindex=$n type=submit name=cancelv value='Отменить'>";
        $MAIN .= '</form>';
      }
      break;
    case 2: // лист
    case 6: // ГЭК
      
      //ввод листа
      if($cancelv)
//        dcgoto("doc.php?doc_id=$doc_id");
        dcgoto($ret);
      if($okv){
        $res_id = $_POST['res_id'];
        getp('dno2');
        s2b($dno2);
        d2b($fp);
        if($doc_rev)
          getdbrow("DOCUMENT_OPEN($doc_id)",$row);
        getdbrow("EKZL_CNG($doc_id,$dno2,$res_id,$fp)", $row);
        if(isset($_POST['pr_id']))
          getdbrow("EKZVEDMPS_CNG({$_POST['pp_id']}, {$_POST['pr_id']})", $row1);

        if($row['RES'])
          $MESS = 'Документ успешно введен.';
        else  
          $ERMESS = 'Документ не введен.';
        if($doc_rev)  
          dcgoto("doc.php?doc_id=$doc_id");
        else
          dcgoto($ret);

      }
      
      getdbrow("EKZL_ITM($doc_id)", $row);
      $pervpovt = $row['PERVPOVT'];
      $semr = a2r($row['SEMESTR']);

      $fio ="{$row['STUDENT_LNAME']} ".mb_substr($row['STUDENT_FNAME'],0,1)."."
            .mb_substr($row['STUDENT_MNAME'],0,1).".";
      $pnn = $row['PERSNAME_NAME'];
//      b2d($dt);
      $rez = "{$row['RES']} {$row['DOC_TYPE']} {$row['DOC_NO']} {$row['DOC_INDT']}";

      $MAIN .= "<b>Факультет:</b> {$row['FACULTET_NAME']} <b>Отделение:</b> {$row['DIVISION_NAME']}<br>";
      $MAIN .= "<b>Группа:</b> {$row['SGROUP_AUTONAME']} ({$row['SGROUP_PERIOD']}) <b>Курс:</b> {$row['KURS']} <b>Семестр:</b> $semr<br>";
      $MAIN .= "<b>Дисциплина:</b> {$row['SUBJ_NAME']} ({$row['CONTROL_NAME']}) часов={$row['VOLUME']}<br>";
      if($row['CONTROL_NAMED'])
        $MAIN .= "<b>Тема:</b>{$row['PERSNAME_NAME']}<br>";
      if($row['SUBJSEL'] > 1)
        $abbr = 1;
      else
        $abbr = 0;

      $MAIN .= "<table id=tabl1 border width=100%>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "  <td rowspan=2>№ пп</td>";
      $MAIN .= "  <td rowspan=2>№ зач.</td>";
      $MAIN .= "  <td rowspan=2>Фамилия и инициалы</td>";
      $MAIN .= "  <td rowspan=2>Оценка</td>";
      if($abbr)
        $MAIN .= "  <td rowspan=2>Дисциплина</td>";
      $MAIN .= "  <td align=center colspan=4>Предыдущая оценка</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr id=head>";
      $MAIN .= "  <td>Оценка</td>";
      $MAIN .= "  <td>Тип</td>";
      $MAIN .= "  <td>Номер</td>";
      $MAIN .= "  <td>Дата</td>";
      $MAIN .= "</tr>";

      $MAIN .= "<tr id=col1>";
      $MAIN .= "<td>1.</td>";
      $MAIN .= "<td>{$row['STUDENT_ZACHNO']}</td>";
      $MAIN .= "<td>$fio</td>";
      if($vvod){
        if(isset($_GET['res_id']))
          $res = $_GET['res_id'];
        elseif($row['CURRES_ID'])
          $res = $row['CURRES_ID'];
        else
          $res = 0;
        $option = "<option value=0>";
        getdbmass("CONTROLRESULT_LST({$row['CONTROL_ID']})", $massr);
        while(getrow($massr, $rowr)){
          $sel = '';
          if($res == $rowr['RESULT_ID'])
            $sel = 'selected';
          $option .= "<option $sel value='{$rowr['RESULT_ID']}'>{$rowr['RESULT_ABBR']}";
        }
        $MAIN .= "<td>";
        $MAIN .= "<select tabindex=1 name=res_id size=1>";
        $MAIN .= "$option";
        $MAIN .= "</select>";
        $MAIN .= "</td>";
        if($abbr){
          getdbmass("MPROGITEM_LST({$row['MAINPROG_ID']})",$massp);
          $option = "";
          while(getrow($massp, $rowp)){
            $sel = '';
            if($row['MPROGSUBJ_ID'] == $rowp['MPROGSUBJ_ID'])
              $sel = 'selected';
            $option .= "<option $sel value='{$rowp['MPROGSUBJ_ID']}'>{$rowp['SUBJ_ABBR']}";
          }
          $MAIN .= "<td>";
          $MAIN .= "<select tabindex=2 name=pr_id size=1>";
          $MAIN .= "$option";
          $MAIN .= "</select>";
          $MAIN .= "</td>";
          $MAIN .= "<input type=hidden name=pp_id value={$row['PERSPROG_ID']}>";
        }
      }
      else{
        $MAIN .= "<td>{$row['CURRES_ABBR']}</td>";
        if($abbr)
          $MAIN .= "  <td>{$row['SUBJ_ABBR']}</td>";

      }
      $MAIN .= "<td>{$row['RES']}</td>";
      $MAIN .= "<td>{$row['DOC_TYPE']}</td>";
      $MAIN .= "<td>{$row['DOC_NO']}</td>";
      $MAIN .= "<td>{$row['DOC_INDT']}</td>";
      $MAIN .= "</tr>";
      $MAIN .= "</table>";
      if($vvod){
        if(!$fp)
          $fp = date("d.m.Y");
        pole("Дата сдачи",'fp',10,'','','',false,true,true," <input type=image $P_CAL name=gfp>");
        $MAIN .= "<input type=hidden name=doc_id value=$doc_id>";
        $MAIN .= "<br><input tabindex=3 name=okv type=submit value='Принять'> ";
        $MAIN .= "<input tabindex=4 type=submit name=cancelv value='Отменить'>";
        $MAIN .= '</form>';
      }
      break;
    case 9:
    case 10:
    case 11:
      getdbrow("STUDDOC_LST($doc_id)", $row);
      $MAIN .= "<table id=tabl1 border width=100%>";
      $MAIN .= "<tr id=head><b><td>Отделение</td><td>Поток</td><td>Группа</td><td>Фамилия</td><td>Имя</td><td>Отчество</td><td>Лич. №</td><td>Форма обучения</td></b></tr>";
      if($row['STUDENT_ACTIVE'])
        $rcolor = "id=col1";
      else
        $rcolor = "id=col3";
      $MAIN .= "<tr $rcolor>";
      $MAIN .= "<td>{$row['DIVISION_NAME']}</td>";
      $MAIN .= "<td>{$row['SGROUP_PERIOD']}</td>";
      $MAIN .= "<td>{$row['SGROUP_AUTONAME']}</td>";
      $MAIN .= "<td>{$row['STUDENT_LNAME']}</td><td>{$row['STUDENT_FNAME']}</td><td>{$row['STUDENT_MNAME']}</td>";
      $MAIN .= "<td>{$row['STUDENT_PERSNO']}</td>";
      $MAIN .= "<td>{$row['EDUFORM_ABBR']}</td>";
      $MAIN .= "</tr>";
      $MAIN .= "</table>";
      break;
    default:// остальные
      if($dtype1 == 3){
        if($cancel)
          dcgoto("{$__routedurlpage__}?doc_id=$doc_id");
        if($ok){
          s2b($dname1);
          s2b($ddesc1);
          getdbrow("DOCUMENT_CNG($doc_id,$dname1,$ddesc1)",$row);
          dcgoto("{$__routedurlpage__}?doc_id=$doc_id");
        }
        formb();
        pole('Наименование','dname1',80,'','','',true,true,$dtflag1);
        pole('Примечание','ddesc1',80,'','','',true,true,$dtflag1);
        forme();
      }

      $stitle = '';
      $MAIN .= "<table id=tabl1 border width=100%>";
      $MAIN .= "<tr id=head><b><td>Отделение</td><td>Поток</td><td>Группа</td><td>Фамилия</td><td>Имя</td><td>Отчество</td><td>Лич. №</td><td>№ зач.<td>Форма обучения</td><td>Дата</td>";
      $n = 9;
      if($dtflag1){
        $n++;
        $MAIN .= "<td><img $P_DELT alt='удалить'></td>";
      }
      $MAIN .= "</b></tr>";
      getdbmass("STUDDOCCONT_LST($doc_id)", $mass);
      $n = 0;
      while(getrow($mass,$row)){
        $n++;
        if($stitle != $row['SUBTITLE']){
          $stitle = $row['SUBTITLE'];
          $MAIN .= "<tr><td colspan=$n><b>$stitle</b></td></tr>";
        }
        $rc = $n%2+1;
        if(!$row['STUDSTATUS_ACTIVE'])
          $rc += 2;

        $MAIN .= "<tr id=col{$rc}>";
        $a = "<a href='student.php?student_id={$row['STUDSGRP_ID']}'>";
        $MAIN .= "<td>{$row['DIVISION_NAME']}</td>";
        $MAIN .= "<td>{$row['SGROUP_PERIOD']}</td>";
        $MAIN .= "<td>{$row['SGROUP_AUTONAME']}</td>";
        $MAIN .= "<td>$a{$row['STUDENT_LNAME']}</a></td><td>{$row['STUDENT_FNAME']}</td><td>{$row['STUDENT_MNAME']}</td>";
        $MAIN .= "<td>{$row['STUDENT_PERSNO']}</td>";
        $MAIN .= "<td>{$row['STUDENT_ZACHNO']}</td>";
        $MAIN .= "<td>{$row['EDUFORM_ABBR']}</td>";
        if($dtflag1)
          $MAIN .= "<td><a href='{$__routedurlpage__}?sdoc_cng=1&doc_id=$doc_id&st_id={$row['STUDSGRP_ID']}&stat_id={$row['STUDSTATUS_ID']}&fp={$row['CONTINGENT_DATE']}'>{$row['CONTINGENT_DATE']}</a></td>";
        else
          $MAIN .= "<td>{$row['CONTINGENT_DATE']}</td>";
        if($dtflag1)
          $MAIN .= "<td><a href='{$__routedurlpage__}?doc_id=$doc_id&dels={$row['STUDSGRP_ID']}&stat_id={$row['STUDSTATUS_ID']}'><img $P_DEL alt='удалить'></a></td>";
        $MAIN .= "</tr>";
      }

      $MAIN .= "</table>";
      break;
    }


  $MENU .= "<a href='docum.php?doc_id=$doc_id&excel=1'><img $P_EXL alt='excel'></a>";
  $MENU .= "<a href='docum.php?doc_id=$doc_id'>Документ</a><br>";

  if($dtflag1){
    $MENU .= "<a href='{$__routedurlpage__}?doc_del=$doc_id'>Удалить</a><br>";
    switch($dtype1){
      case 3:// по л/с
//        $MENU .= " <a href='doc.php?doc_id=$doc_id&doc_cng=1'>Имя/прим.</a><br>";
        $MENU .= " <a href='doc.php?doc_id=$doc_id&doc_close=1'>Завершить</a><br>";
        break;
      default:
        break;
      }
  }
  else{
    switch($dtype1){
      case 2: // лист
      case 6: // ГЭК
        $MENU .= "<a href='doc.php?doc_id=$doc_id&doc_rev=1'>Реввод</a><br>";
        break;
      case 1: // ведомость
      case 8: // должники
      case 12: // ведомость тем
        $MENU .= "<a href='doc.php?doc_id=$doc_id&doc_rev=1'>Реввод</a><br>";
        $MENU .= "<a href='doc.php?&doc_id=$doc_id&doc_open=$doc_id'>Открыть</a><br>";
        break;
      default:// остальные
        $MENU .= " <a href='doc.php?&doc_id=$doc_id&doc_open=$doc_id'>В проект</a><br>";
        break;
      }
  }
  mainpaint();
}

head('Перечень незавершенных производством документов');
getdbmass("TEMPDOC_LST({$_SESSION['co_facultet']})",$mass);
messall($mass);
$MAIN .= "<table width=100%>";
$MAIN .= "<tr id=head>";
$MAIN .= "<td>№</td>";
$MAIN .= "<td>Тип</td>";
$MAIN .= "<td>№ док-та</td>";
$MAIN .= "<td>Издан</td>";
$MAIN .= "<td>Завершен</td>";
$MAIN .= "<td>Название</td>";
$MAIN .= "<td>Примечание</td>";
$MAIN .= "<td>Состояние</td>";
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
  $MAIN .= "<td>{$row['DOCTYPE_NAME']}</td>";
  $MAIN .= "<td><a href='{$__routedurlpage__}?doc_id={$row['DOCUMENT_ID']}'>{$row['DOCUMENT_NO']}</a></td>";
  b2d($row['DOCUMENT_INDATE']);
  b2d($row['DOCUMENT_OUTDATE']);
  $MAIN .= "<td>{$row['DOCUMENT_OUTDATE']}</td>";
  $MAIN .= "<td>{$row['DOCUMENT_INDATE']}</td>";
  $MAIN .= "<td>{$row['DOCUMENT_NAME']}</td>";
  $MAIN .= "<td>{$row['DOCUMENT_DESC']}</td>";
  $MAIN .= "<td>{$row['DOCUMENT_STATUS']}</td>";
  $MAIN .= "</tr>";
  if(($n >= $MAXREC) && (!isset($_GET['allview'])))
    break;
}
$MAIN .= "</table><br>";
list($cd, $cm, $cy) = sscanf(date("d.m.Y"), "%02d.%02d.%04d");
$cm--;
if($cm < 1){
  $cm = 12;
  $cy -= 1;
}
$fp = sprintf("%02d.%02d.%04d", $cd, $cm, $cy);
$MENU .= "<a href='doc.php?del_old=1&fp=$fp'><img $P_DEL alt='Удалить'> Устаревшие</a>";

mainpaint();
?>