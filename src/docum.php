<?php
if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"doc.xls\";");
include "global.php";
getp('doc_id');
getp('excel');
getp('type');
getp('sid');
getp('mp_id');
getp('pp_id');

if(!$excel)
  sst($_SERVER['HTTP_REFERER']);

$numc = 5;

if($type){
 switch($type){
   case 1: 
   case 12:
     $func = "EKZVED_ADD({$_SESSION['co_sgroup']},{$_GET['mp_id']},$type)";
     break;
   case 2:
   case 6:
     $func = "EKZL_ADD({$_GET['pp_id']})";
     break;
   case 8:
     $func = "DOLGVED_ADD({$_GET['mp_id']})";
     break;
   case 9:
     $func = "USPR_ADD($sid, 9)";
     break;
   case 10:
     $func = "USPR_ADD($sid, 10)";
     break;
   case 11:
     $func = "ASPR_ADD($sid)";
     break;
  }
  if(!isset($_SESSION['ref_doc_id'])){
    getdbrow($func,$row);
    if($row['RES'])
      $_SESSION['ref_doc_id'] = $row['RES'];
    else{
      $mess = urlencode('Выдача документа невозможна!');
      dcgoto("{$_SERVER['HTTP_REFERER']}&ermess=$mess");
    }
  }
  $doc_id = $_SESSION['ref_doc_id'];
}


getdbrow("DOCUMENT_ITM($doc_id)",$row);
$dtype1 = $row['DOCTYPE_ID'];
$gek = false;
switch($dtype1){
  case 1: //Ведомость
  case 8: //Ведомость должников
  case 12: //Ведомость тем

   if($dtype1 == 12)
      $tem = true;
    else
      $tem = false;
     if($dtype1 == 8)
      $dolg = true;
    else
      $dolg = false;

    getdbmass("EKZVED_ITM($doc_id)",$mass);
    getrow($mass,$row);
    $sn = $row['SN'];
    $sem = $row['SEMESTR'];
    $docno = $row['DOCUMENT_NO'];
    $ye = $row['UYEAR'];
    $cname = $row['CONTROL_NAME'];
    $fn = $row['FN'];
    $dn = $row['DN'];
    $kurs = $row['KURS'];
    $sgan = $row['SGROUP_AUTONAME'];
    $sgp = $row['SGROUP_PERIOD'];
    $ssn = $row['SUBJ_NAME'];
    $vol = $row['VOLUME'];
    $doc_id = $row['DOCUMENT_ID'];
    $abbr = false;
    while(getrow($mass,$row)){
      $ssn .= ", ".$row['SUBJ_NAME'];
      $abbr = true;
    }

    getdbrow("DOCUMENT_FOOTER($doc_id)",$row1);
    if($abbr)
      switch($dtype1){
        case 1:
          $nf = 'ekzva.htm';
          break;
        case 8:
          $nf = 'ekzvda.htm';
          break;
        case 12:
          $nf = 'ekzvta.htm';
          break;
      }
    else
      switch($dtype1){
        case 1:
          $nf = 'ekzv.htm';
          break;
        case 8:
          $nf = 'ekzvd.htm';
          break;
        case 12:
          $nf = 'ekzvt.htm';
          break;
      }
    $incf = gtempl($nf);
    if($incf)
      include $incf;
    exit;

    
    $MAIN .= "<table><tr>";
    if($tem){
      bar($doc_id,$npic,1);
      $MAIN .= "<td valign=top>$npic</td>";
    }
    else{
      getdbmass("BARS_ITM($doc_id)", $mass2);
      while(getrow($mass2, $row2)){
        $npic='';
        bar($row2['BARCODE'],$npic,1,$row2['RESULT_ABBR'],1);
        $MAIN .= "<td valign=top>$npic</td>";
      }
    }
    $MAIN .= "</tr></table>";

    if($dolg)
      $kols = 12;
    else
      $kols = 11;

    thead(1);

    $MAIN .= "<tr>";
    $MAIN .= "<td id=big colspan=$kols>$sn</td>";
    $MAIN .= "</tr>";
    if($tem){
      $MAIN .= "<tr>";
      $MAIN .= "<td id=med colspan=$kols>ВЕДОМОСТЬ ТЕМ № $docno</td>";
      $MAIN .= "</tr>";
    }
    else{
      $MAIN .= "<tr>";
      $MAIN .= "<td id=med colspan=$kols>ЗАЧЕТНО - ЭКЗАМЕНАЦИОННАЯ ВЕДОМОСТЬ № $docno</td>";
      $MAIN .= "</tr>";
      if($dolg)
        $MAIN .= "<tr><td align=center colspan=$kols>для имеющих академическую задолженность</td></tr>";
    }
    $MAIN .= "<tr>";
    $sem = a2r($sem);
    $MAIN .= "<td colspan=$kols>Семестр: $sem&nbsp;&nbsp;$ye учебного года</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr>";
    $MAIN .= "<tr>";
    $MAIN .= "<td colspan=$kols>Факультет: $fn</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr>";
    $MAIN .= "<td colspan=$kols>Отделение: $dn</td>";
    $MAIN .= "</tr>";
    if(!$dolg){
      $MAIN .= "<tr>";
      $MAIN .= "<td colspan=$kols>Курс: $kurs&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Группа: $sgan ($sgp)</td>";
      $MAIN .= "</tr>";
    }
    $MAIN .= "<tr>";
    $MAIN .= "<td colspan=$kols>Дисциплина: $ssn  ($cname) $vol часов</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr>";
    $MAIN .= "<td colspan=$kols>Фамилия, имя, отчество преподавателей: ________________________________________________________</td>";
    $MAIN .= "</tr>"; 
    $MAIN .= "<tr>";                                                                                                     
    $MAIN .= "<td colspan=$kols>___________________________________________________________________________________________</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr>";                                                                                                     
    $MAIN .= "<td colspan=$kols>___________________________________________________________________________________________</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr>";
    $MAIN .= "<td colspan=$kols>Дата проведения контрольного мероприятия:&nbsp;&nbsp;&quot______&quot;&nbsp;&nbsp;_____________________ 20___ г.</td>";
    $MAIN .= "</tr>";                       
    $MAIN .= "<tr>";
    $MAIN .= "<td colspan=$kols>&nbsp;</td>";
    $MAIN .= "</tr>";

    thead(2);

    $i = 1;
    if($tem)
      getdbmass("TEMVED_LST($doc_id)", $mass);
    else
      getdbmass("EKZVED_LST($doc_id)", $mass);
    while(getrow($mass, $row)){
      if($i == 21){
        $MAIN .= "</table><p id=brpage><p>";
        thead(1,"стр. 2");
        thead(2);
      }
      if($i == 51){
        $MAIN .= "</table><p id=brpage><p>";
        thead(1,"стр. 3");
        thead(2);
      }
      if($i == 81){
        $MAIN .= "</table><p id=brpage><p>";
        thead(1,"стр. 4");
        thead(2);
      }
      if($i == 111){
        $MAIN .= "</table><p id=brpage><p>";
        thead(1,"стр. 5");
        thead(2);
      }
      if($i == 141){
        $MAIN .= "</table><p id=brpage><p>";
        thead(1,"стр. 6");
        thead(2);
      }
      if($i == 171){
        $MAIN .= "</table><p id=brpage><p>";
        thead(1,"стр. 7");
        thead(2);
      }
      $MAIN .= "<tr>";
      $MAIN .= "  <td id=tcenter>$i.</td>";$i++;
      if($dolg)
        $MAIN .= "<td id=tleft>{$row['SGROUPAUTONAME']}</td>";
      $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
      $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);
      $MAIN .= "  <td id=tleft>{$row['STUDENT_LNAME']} $fn.$mn.</td>";
      $MAIN .= "  <td id=tcenter>{$row['STUDENT_ZACHNO']}</td>";
      if($abbr)
        $MAIN .= "  <td id=tcenter>{$row['SUBJ_ABBR']}</td>";
      if($tem)
        $MAIN .= "  <td id=tleft colspan=8>&nbsp</td>";
      else{
        $MAIN .= "  <td id=tcenter>{$row['RESULT_ABBR']}</td>";
        $MAIN .= "  <td id=tleft>{$row['DOCTYPE_ABBR']}</td>";
        $MAIN .= "  <td id=tleft>{$row['DOCUMENT_NO']}</td>";
        $MAIN .= "  <td id=tleft>{$row['DOCUMENT_INDATE']}</td>";
        $MAIN .= "  <td id=tleft></td>";
        $MAIN .= "  <td id=tleft></td>";
        $MAIN .= "  <td id=tleft></td>";
      }
      $MAIN .= "</tr>";
    }
    if(!$tem){
      $MAIN .= "<tr>";
      $MAIN .= "<td id=padtop></td>";     
      $MAIN .= "<td id=padtop colspan=4>Число студентов на контрольном мероприятии:</td>";
      $MAIN .= "<td id=padtop colspan=3>____________________________</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr>";
      $MAIN .= "<td></td>";     
      $MAIN .= "<td colspan=4>Из них получивших &quot;отлично&quot;:</td>";
      $MAIN .= "<td colspan=3>____________________________</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr>";
      $MAIN .= "<td></td>";     
      $MAIN .= "<td id=padleft colspan=4>получивших &quot;хорошо&quot;:</td>";
      $MAIN .= "<td colspan=3>____________________________</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr>";
      $MAIN .= "<td></td>";     
      $MAIN .= "<td id=padleft colspan=4>получивших &quot;удовлетворительно&quot;:</td>";
      $MAIN .= "<td colspan=3>____________________________</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr>";
      $MAIN .= "<td></td>";     
      $MAIN .= "<td id=padleft colspan=4>получивших &quot;неудовлетворительно&quot;:</td>";
      $MAIN .= "<td colspan=3>____________________________</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr>";
      $MAIN .= "<td></td>";     
      $MAIN .= "<td colspan=4>Число студентов не явившихся на контрольное мероприятие:</td>";
      $MAIN .= "<td colspan=3>____________________________</td>";
      $MAIN .= "</tr>";   
      $MAIN .= "<tr>"; 
      $MAIN .= "<td></td>";     
      $MAIN .= "<td colspan=4>Число студентов не допущенных к контрольному мероприятию:</td>";
      $MAIN .= "<td colspan=3>____________________________</td>";
      $MAIN .= "</tr>";
    }
    $MAIN .= "<tr>"; 
    $MAIN .= "<td id=padtop colspan=2></td>";     
    getdbrow("DOCUMENT_FOOTER($doc_id)",$row);

    $MAIN .= "<td id=padtop colspan=3>{$row['BOSSTITUL']}</td>";
    $MAIN .= "<td id=padtop colspan=3>___________ {$row['BOSSFIO']}</td>";
    $MAIN .= "</tr>";
    if(!$tem){
      $MAIN .= "<tr>"; 
      $MAIN .= "<td id=padtext colspan=8>ЗАПРЕЩАЕТСЯ:<br>
                1. Принимать экзамены от студентов, не внесенных в данную экзаменационную ведомость<br>
                2. Принимать экзамены в сроки, не установленные утвержденным расписанием, кроме случаев специально разрешенных деканатом.  
                </td>";     
      $MAIN .= "<td id=padtop colspan=3></td>";
      $MAIN .= "</tr>";
    }
    $MAIN .= "</table>";
    break;
  case 6: // ГЭК  $dtype1
    $gek = true;
  case 2: // Лист
    getdbrow("EKZL_ITM($doc_id)", $row);
    $sn = $row['SCHOOL_NAME'];
    $fn = $row['FACULTET_NAME'];
    $kurs = $row['KURS'];
    $sgan = $row['SGROUP_AUTONAME'];
    $docno = $row['DOCUMENT_NO'];
    $sem = $row['SEMESTR'];
    $dname = "Дисциплина <u>{$row['SUBJ_NAME']}</u>";
    $nzach = $row['STUDENT_ZACHNO'];
    $incf = gtempl('ekzl.htm');
    if($gek)
      $incf = gtempl('ekzlg.htm');
    $fio ="{$row['STUDENT_LNAME']} ".mb_substr($row['STUDENT_FNAME'],0,1)."."
          .mb_substr($row['STUDENT_MNAME'],0,1).".";
    $row['SEMESTR'] = a2r($row['SEMESTR']);
    getdbrow("DOCUMENT_FOOTER({$row['DOCUMENT_ID']})",$row1);


///*
    if($incf)
      include $incf;
    exit;
//*/
    $MAIN .= "<table><tr>";
    getdbmass("BARS_ITM({$row['DOCUMENT_ID']})", $mass2);
    while(getrow($mass2, $row2)){
      $npic='';
      bar($row2['BARCODE'],$npic,1,$row2['RESULT_ABBR'],1);
      $MAIN .= "<td>$npic</td>";
    }
    $MAIN .= "</tr></table>";

    $MAIN .= "<table id=width13 width=100%>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td id=big colspan=2>";
    $MAIN .= "{$row['SCHOOL_NAME']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td id=r colspan=2>";
    $MAIN .= "{$row['PERVPOVT']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td id=med colspan=2>";
    if($gek)
      $MAIN .= "ПРОТОКОЛ ГОСУДАРСТВЕННОЙ ЭКЗАМЕНАЦИОННОЙ КОМИССИИ № {$row['DOCUMENT_NO']}";
    else
      $MAIN .= "ЭКЗАМЕНАЦИОННЫЙ ЛИСТ № {$row['DOCUMENT_NO']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    if(!$gek){
      $MAIN .= "  <tr>";
      $MAIN .= "  <td colspan=2>";
      $MAIN .= "<div id=small>(для сдачи экзамена или зачета вне группы,</div>";
      $MAIN .= "<div id=small>подшиваются к основной ведомости группы)</div>";
      $MAIN .= "  </td>";
      $MAIN .= "  </tr>";
    }
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "Факультет: {$row['FACULTET_NAME']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "Курс: {$row['KURS']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Группа: {$row['SGROUP_AUTONAME']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "Дисциплина: {$row['SUBJ_NAME']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
//    $semr = a2r($row['SEMESTR']);
    $MAIN .= "Семестр: $semr, {$row['CONTROL_NAME']}, {$row['VOLUME']} часов";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    if($row['CONTROL_NAMED']){
      $pnn = '_____________________________________________________';
      if($row['PERSNAME_NAME'])
         $pnn = $row['PERSNAME_NAME'];
      $MAIN .= "  <tr>";
      $MAIN .= "  <td colspan=2>";
      $MAIN .= "Тема: $pnn";
      $MAIN .= "  </td>";
      $MAIN .= "  </tr>";
    }
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "Экзаменатор ________________________________________________";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "<div id=small>(учебное звание, фамилия, инициалы)</div>";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "№ зачетной книжки: {$row['STUDENT_ZACHNO']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $fio ="{$row['STUDENT_LNAME']} ".mb_substr($row['STUDENT_FNAME'],0,1)."."
          .mb_substr($row['STUDENT_MNAME'],0,1).".";
    $MAIN .= "Фамилия и инициалы студента: $fio";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "Дата выдачи: {$row['DOCUMENT_OUTDATE']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    getdbrow("DOCUMENT_FOOTER({$row['DOCUMENT_ID']})",$row1);
    $MAIN .= "{$row1['BOSSTITUL']} ______________________ {$row1['BOSSFIO']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "Последняя оценка: {$row['RES']} {$row['DOC_TYPE']} {$row['DOC_NO']} {$row['DOC_INDT']}";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td><br>";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td>";
    $MAIN .= "Оценка:______________________";
    $MAIN .= "  </td>";
    $MAIN .= "  <td>";
    $MAIN .= "Дата сдачи:__________________";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "<div id=pad>Подпись экзаменатора: ________________________________________</div>";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "  <tr>";
    $MAIN .= "  <td colspan=2>";
    $MAIN .= "<div id=small>Возвращается преподавателем или сотрудником кафедры</div>";
    $MAIN .= "  </td>";
    $MAIN .= "  </tr>";
    $MAIN .= "</table>";
    break;
  case 9:
    getdbrow("USPR_ITM($doc_id)",$row);
    $fio = "{$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}";
    $curs = $row['KURS'];
    $fac = $row['FACULTET_ABBR'];
    $sdep = $row['SCHOOL_DEPT'];
    $sname = strtoupper($row['SCHOOL_NAME']);
    $num = $row['DOCUMENT_NO'];
    $date = $row['DOCUMENT_INDATE'];
    $city = "г. {$row['CITY_NAME']}";
    $adr = '';
    if($row['SCHOOL_STREET'])
      $adr .= $row['SCHOOL_STREET'];
    if($row['SCHOOL_BLDNO'])
      $adr .= ", {$row['SCHOOL_BLDNO']}";
    getdbrow("DOCUMENT_FOOTER({$row['DOCUMENT_ID']})", $row);
    $decan = $row['BOSSTITUL'];
    $decanfio = $row['BOSSFIO'];
    $incf = gtempl('uspr.htm');
    if($incf)
      include $incf;
/*
    $MAIN .= "<table id=sprav1>";
    $MAIN .= "<tr><td id=width6></td><td id=width8></td></tr>";
    $MAIN .= "<tr><td align=center>";
    $MAIN .= "{$row['SCHOOL_DEPT']}<br><br>";
    $ns = strtoupper($row['SCHOOL_NAME']);
    $MAIN .= "<b>$ns</b><br>";
    $MAIN .= "№ {$row['DOCUMENT_NO']}<br>";
    $MAIN .= "от {$row['DOCUMENT_INDATE']}<br>";
    $MAIN .= "г. {$row['CITY_NAME']}<br>";
    $MAIN .= "{$row['SCHOOL_STREET']}, {$row['SCHOOL_BLDNO']}<br>";
    $MAIN .= "</td>";
    $MAIN .= "<td valign=top>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<b>СПРАВКА</b><br>";
    $MAIN .= "Дана в том, что {$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}<br>";
    $MAIN .= "является студентом {$row['KURS']} курса,<br>факультета {$row['FACULTET_ABBR']}.<br>";
    $MAIN .= "Справка дана для предъявления в<br><br>";
    $MAIN .= "____________________________<br><br>";
    $MAIN .= "____________________________<br><br>";
    $MAIN .= "____________________________";
    $MAIN .= "</td></tr>";
    $MAIN .= "<tr><td></td>";
    $MAIN .= "<td>";
    getdbrow("DOCUMENT_FOOTER({$row['DOCUMENT_ID']})", $row);
    $MAIN .= "{$row['BOSSTITUL']} ________ {$row['BOSSFIO']}<br>";
    $MAIN .= "Секретарь ____________________";
    $MAIN .= "</td></tr>";
    $MAIN .= "</table>";
*/
    break;
  case 10:
    getdbrow("STUDDOC_LST($doc_id)", $row);
    $sid = $row['STUDSGRP_ID'];
    getdbrow("USPR_ITM($doc_id)",$row);
    $MAIN .= "<table id=sprav2>";
    $MAIN .= "<tr><td id=width8></td><td id=width10></td></tr>";
    $MAIN .= "<tr><td align=center>";
    $sd = strtoupper($row['SCHOOL_DEPT']);
    $ns = strtoupper($row['SCHOOL_NAME']);
    $MAIN .= "$sd<br>$ns<br>{$row['SCHOOL_ABBR']}<br>";
    $MAIN .= "г. {$row['CITY_NAME']}<br>";
    $MAIN .= "{$row['SCHOOL_STREET']}, {$row['SCHOOL_BLDNO']}<br>";
    $MAIN .= "№ {$row['DOCUMENT_NO']} от {$row['DOCUMENT_INDATE']}<br>";
    $MAIN .= "</td><td></td></tr>";
    $MAIN .= "<tr><td colspan=2 align=center><b>Справка</b></td></tr>";
    $MAIN .= "<tr><td colspan=2>Дана в том, что<br>";
    $MAIN .= "<b>{$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}</b><br>";
    $MAIN .= "Дата рождения {$row['STUDENT_BIRTHDAY']} г.<br><br>";
    $MAIN .= "</td></tr>";
    $MAIN .= "<tr><td align=justify colspan=2>";
    $MAIN .= "Обучается в государственном образовательном учреждении: ";
    $MAIN .= "{$row['SCHOOL_NAME']} на <b>{$row['KURS']}</b> курсе, факультет: {$row['FACULTET_NAME']}<br><br>";
    $MAIN .= "Форма обучения - {$row['FED_NAME']}, {$row['DET_NAME']}, {$row['EDUFORM_NAME']}.<br>";
    $MAIN .= "Период обучения: {$row['UPERIOD']}гг.<br>";
    $MAIN .= "Обучается по направлению {$row['GOSDIR_CODE']} \"{$row['GOSDIR_NAME']}\" ";
    $MAIN .= "специальности {$row['GOSTITLE_CODE']} \"{$row['GOSTITLE_NAME']}\" ";
    if($row['SUBSPEC_CODE'])
      $MAIN .= "специализации {$row['SUBSPEC_CODE']} \"{$row['SUBSPEC_NAME']}\"";
    $MAIN .= ".<br>";
    $MAIN .= "Cправка дана для представления в территориальный орган Пенсионного фонда Российской Федерации.<br>";
    $MAIN .= "Основание выдачи справки - приказ о зачислении студента <b>№ {$row['PRIK_NO']} от {$row['PRIK_DATE']}</b><br>";
    $MAIN .= "</tr>";
    $MAIN .= "</table>";
    break;
  case 11:
    getdbrow("DOCUMENT_ITM($doc_id)",$row);
    $doc_no = $row['DOCUMENT_NO'];
    getdbrow("STUDDOC_LST($doc_id)", $row);
    $sid = $row['STUDSGRP_ID'];
    $MAIN .= "<table id=t_mprog>";
    $MAIN .= "<tr><td id=width1></td><td id=width8></td><td id=width2></td>
      <td id=width4></td><td id=width4></td></tr>";
    $MAIN .= "<tr><td id=big colspan=$numc>{$row['SCHOOL_NAME']}<br>";
    $MAIN .= "КОПИЯ АКАДЕМИЧЕСКОЙ СПРАВКИ № $doc_no</td></tr>";
    $MAIN .= "<tr><td id=left colspan=$numc>";
    $MAIN .= "студент(ка): {$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}<br>";
    $MAIN .= "Группа: {$row['SGROUP_AUTONAME']}<br>";
    $MAIN .= "Период обучения: {$row['SGROUP_PERIOD']} гг.<br>";
    $MAIN .= "Факультет: {$row['FACULTET_NAME']}<br>";
    $MAIN .= "Отделение: {$row['DIVISION_NAME']}<br>";
    getdbrow("DIVISION_ITM({$row['DIVISION_ID']})", $row1);
    if($row1['GOSTITLE_NAME'])
      $MAIN .= "Специальность: {$row1['GOSTITLE_CODE']} {$row1['GOSTITLE_NAME']}<br>";
    if($row1['SUBSPEC_NAME'])
      $MAIN .= "Специализация: {$row1['SUBSPEC_CODE']} {$row1['SUBSPEC_NAME']}<br>";
    $MAIN .= "За время обучения пройдены следующие дисциплины и сданы зачеты и экзамены:<br>";
    $MAIN .= "<tr id=head>";
    $MAIN .= "<td>№</td><td>Название дисциплины</td><td>Часов</td><td>Оценка</td><td></td>";
    $MAIN .= "</tr>";
    getdbmass("REP_STUDSEMACAD_LST({$row['STUDSGRP_ID']},NULL,NULL)", $mass);
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
      $MAIN .= "</tr>";
    }
    $MAIN .= "</table>";
    break;
  default:// Остальные
    getdbrow("DOCUMENT_ITM($doc_id)",$row);
    $doc_no = $row['DOCUMENT_NO'];
    $dt = $row['DOCUMENT_INDATE'];
    b2d($dt);
    $row['SCHOOL_DEPT'] = strtoupper($row['SCHOOL_DEPT']);
    $MAIN .= "<table width=100%><tr><td width=80%></td><td width=20%></td></tr>";
    $MAIN .= "<tr><td colspan=2 id=b14>{$row['SCHOOL_DEPT']}</td></tr>";
    $MAIN .= "<tr><td colspan=2 id=b14>{$row['SCHOOL_NAME']}</td></tr>";
    $MAIN .= "<tr><td colspan=2 id=b14>{$row['SCHOOL_ABBR']}</td></tr>";
    $MAIN .= "<tr><td colspan=2 id=big><br>ПРИКАЗ</td></tr>";
    if($dt)
      $MAIN .= "<tr><td>от {$dt}г.</td><td>№ $doc_no</td></tr>";
    else
      $MAIN .= "<tr><td>от _________</td><td>№ $doc_no</td></tr>";
    $MAIN .= "<tr><td colspan=2 id=gorod>г.{$row['CITY_NAME']}</td></tr>";
    $MAIN .= "<tr><td colspan=2>{$row['FACULTET_NAME']} факультет</td></tr>";
    $MAIN .= "</table><br>";
    while(getdbm("DOCUMENT_BODY($doc_id)", $mass)){
      $MAIN .= "<table id=tabl1 border width=100%>";
      $i=0;
      $a = array();
      $c = $mass->field_count;
      $finfo = $mass->fetch_field_direct(0);
      $title = false;
      if($finfo->name == '_TITLE_'){
        $title = true;
        $a[0] = false;
      }
      $i=0;
      $del1 = $del2 = -1;
      if(!$title){
        $MAIN .= "<tr id=head1>";
        $z = -1;
        while($finfo = $mass->fetch_field()){
          $z++;
          if(($finfo->type == 246) || ($finfo->type == 4))
            $a[$i] = true;
          else
            $a[$i] = false;
          $i++;
          if($finfo->name[0] == 'S'){
            if($del1 < 0)
              $del1 = $z;
            else 
              $del2 = $z;
          }
          else
            $MAIN .= "<td><b>{$finfo->name}</b></td>";
        }
        $MAIN .= "</tr>";
      }
      $n=0;
      while(getrow($mass, $row, false)){
        $n++;
/*
        if(!$title){
          $rcolor = "id=col4";
          if($row['STUDSTATUS_ACTIVE'])
            $rcolor = "id=col2";
          if($n%2){
            $rcolor = "id=col3";
            if($row['STUDSTATUS_ACTIVE'])
              $rcolor = "id=col1";
          }
        }
        else*/
          $rcolor = '';
        $MAIN .= "<tr $rcolor>";
        for($i=0; $i<$mass->field_count; $i++){
          if(($i == $del1) || ($i == $del2))
            continue;
          $q = $row["$i"];
          $align = '';
          if($a[$i]){
            $q = str_replace(".", ",", $q);
            $align = 'align=right';
          }
          if($title)
            $MAIN .= "<td><b>$q</b></td>";
          else
            $MAIN .= "<td $align>$q</td>";
        }
        $MAIN .= "</tr>";
      }
      $MAIN .= "</table>";
    }
    getdbrow("DOCUMENT_FOOTER($doc_id)", $row);
    $MAIN .= "<br><table><tr>";
    $MAIN .= "<td>{$row['BOSSTITUL']} _________ {$row['BOSSFIO']}</td>";
    $MAIN .= "</tr></table>";
    break;

}
if(($dtype1 == 10)||($dtype1 == 11)){
  $MAIN .= "<br>";
  $MAIN .= "<br>";
  $MAIN .= "<table width=100%>";
  //$MAIN .= "<tr><td id=width8></td><td id=width10></td></tr>";
  $MAIN .="<b>Приказы по личному составу:</b><br>";
  getdbmass("STUDCONT_LST($sid)", $mass);
  $MAIN .= "<tr id=head>";
  $MAIN .= "<td>№</td>";
  $MAIN .= "<td>Номер</td>";
  $MAIN .= "<td>Дата</td>";
  $MAIN .= "<td>Статус</td>";
  $MAIN .= "<td>Значение</td>";
  $MAIN .= "</tr>";
  $n = 0;
  while(getrow($mass, $row)){
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
  $MAIN .= "</table><br>";
  getdbrow("DOCUMENT_FOOTER($doc_id)", $row);
  $MAIN .= "<br>{$row['BOSSTITUL']} ________________________ {$row['BOSSFIO']}<br>";
}

if(!$excel)
  sst($_SERVER['HTTP_REFERER']);
echo $MAIN;
echo $DEBUG;


function thead($type, $i=""){
  global $MAIN, $abbr, $dolg, $tem;
  if($type == 1){
    $MAIN .= "<table id=tabotchet>";
    $MAIN .= "<tr>";
    $MAIN .= "  <td id=width1></td>";
    if($dolg)
      $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width4></td>";
    $MAIN .= "  <td id=width15></td>";
    if($abbr)
      $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width1></td>";
    $MAIN .= "  <td id=width1></td>";
    $MAIN .= "  <td id=width15></td>";
    $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width1></td>";
    $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width15>$i</td>";
    $MAIN .= "</tr>";
  }
  if($type == 2){
    $MAIN .= "<tr>";
    $MAIN .= "  <td id=tcenter rowspan=2>№ пп</td>";
//    $MAIN .= "  <td rowspan=2>№ пп</td>";
    if($dolg)
      $MAIN .= "  <td id=tcenter rowspan=2>Группа</td>";
    $MAIN .= "  <td id=tcenter rowspan=2>Фамилия и инициалы</td>";
    $MAIN .= "  <td id=tcenter rowspan=2>№ за-четной книжки</td>";
    if($abbr)
      $MAIN .= "  <td id=tcenter rowspan=2>Дисциплина</td>";
    if($tem){
      $MAIN .= "  <td id=tcenter rowspan=2 colspan=8>Тема</td>";
      $MAIN .= "</tr><tr>";

    }
    else{
      $MAIN .= "  <td id=tcenter colspan=4>Предыдущая оценка и документ</td>";
      $MAIN .= "  <td id=tcenter colspan=2>Экзаменационная оценка</td>";
      $MAIN .= "  <td id=tcenter rowspan=2>Подпись препода-вателя</td>";
      $MAIN .= "</tr>";
      $MAIN .= "<tr>";
      $MAIN .= "  <td id=tcenter>Рез.</td>";
      $MAIN .= "  <td id=tcenter>Тип</td>";
      $MAIN .= "  <td id=tcenter>Номер</td>";
      $MAIN .= "  <td id=tcenter>Дата</td>";
      $MAIN .= "  <td id=tcenter>цифрой</td>";
      $MAIN .= "  <td id=tcenter>прописью</td>";
    }
    $MAIN .= "</tr>";
  }
}
?>
</body> 
</html>