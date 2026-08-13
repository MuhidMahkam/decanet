<?php
if(isset($_GET['excel']))
  header("Content-Disposition: attachment; filename=\"listgr.xls\";");
include "global.php";
$sgr = getTFN($_SESSION['sgrm1']);
getp('type');
getdbmass("STUDENT_LST({$_SESSION['co_sgroup']},$sgr)", $mass);
sst($_SERVER['HTTP_REFERER']);
if($type == 1)
  $kols = 7;
elseif($type == 2)
  $kols = 3;
elseif($type == 3)
  $kols = 4;
elseif($type == 4)
  $kols = 6;

$MAIN .= "<table id=tabotchet>";
$MAIN .= "<tr>";
$MAIN .= "  <td id=width1></td>";
$MAIN .= "  <td id=width8></td>";
if($type == 1){
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
}elseif($type == 2){
  $MAIN .= "  <td id=width8></td>";
}elseif($type == 3){
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
}elseif($type == 4){
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
  $MAIN .= "  <td id=width2></td>";
}
$MAIN .= "</tr>";

if($type == 4){
  $MAIN .= "<tr>";
  $MAIN .= "<td id=med colspan=$kols>ЗАЧЕТНО - ЭКЗАМЕНАЦИОННАЯ ВЕДОМОСТЬ № __________</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=$kols>Семестр: _____   _________учебного года</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);  
  $MAIN .= "<td colspan=$kols>Факультет: {$row["FACULTET_NAME"]}</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row);
  $MAIN .= "<td colspan=$kols>Отделение: {$row["DIVISION_NAME"]}</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
  $MAIN .= "<td colspan=$kols>Курс: ____________  Группа: {$row['SGROUP_AUTONAME']} ({$row['SGROUP_PERIOD']})</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  $MAIN .= "<td colspan=$kols>Дисциплина: ________________________________________________________________ ____ часов</td>";
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
    $fn = mb_substr($row['STUDENT_FNAME'], 0, 1);
    $mn = mb_substr($row['STUDENT_MNAME'], 0, 1);
    $MAIN .= "  <td id=tleft>{$row['STUDENT_LNAME']} $fn.$mn.</td>";
    $MAIN .= "  <td id=tcenter>{$row['STUDENT_ZACHNO']}</td>";
    $MAIN .= "  <td id=tleft></td>";
    $MAIN .= "  <td id=tleft></td>";
    $MAIN .= "  <td id=tleft></td>";
    $MAIN .= "</tr>";
  }
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
//  $MAIN .= "<tr>"; 
//  $MAIN .= "<td id=padtop colspan=2></td>";     
//  getdbrow("DOCUMENT_FOOTER($doc_id)",$row);
//  $MAIN .= "<td id=padtop colspan=3>{$row['BOSSTITUL']}</td>";
//  $MAIN .= "<td id=padtop colspan=3>___________ {$row['BOSSFIO']}</td>";
//  $MAIN .= "</tr>";
  $MAIN .= "<tr>"; 
  $MAIN .= "<td id=padtext colspan=8>ЗАПРЕЩАЕТСЯ:<br>
            1. Принимать экзамены от студентов, не внесенных в данную экзаменационную ведомость<br>
            2. Принимать экзамены в сроки, не установленные утвержденным расписанием, кроме случаев специально разрешенных деканатом.  
            </td>";     
  $MAIN .= "<td id=padtop colspan=3></td>";
  $MAIN .= "</tr>";
  $MAIN .= "</table>";  
}
else{ 
  $MAIN .= "<tr>";
  getdbrow("SCHOOL_ITM({$_SESSION['co_school']})", $row);
  $MAIN .= "  <td id=big colspan=$kols>".$row["SCHOOL_NAME"]."</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  getdbrow("FACULTET_ITM({$_SESSION['co_facultet']})", $row);
  getdbrow("DIVISION_ITM({$_SESSION['co_division']})", $row1);
  $MAIN .= "  <td id=left colspan=$kols>факультет: {$row["FACULTET_NAME"]}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;отделение: {$row1["DIVISION_NAME"]}</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr>";
  getdbrow("SGROUP_ITM({$_SESSION['co_sgroup']})", $row);
  $MAIN .= "  <td id=med colspan=$kols>Список учебной группы {$row['SGROUP_AUTONAME']} ({$row['SGROUP_PERIOD']}):</td>";
  $MAIN .= "</tr>";
  $MAIN .= "<tr id=head>";
  $MAIN .= "  <td id=tcenter>№</td>";
  $MAIN .= "  <td id=tleft>ФИО студента</td>";
  if($type == 1){
    $MAIN .= "  <td id=tleft>Номер</td>";
    $MAIN .= "  <td id=tleft>№ зачет. книжки</td>";
    $MAIN .= "  <td id=tleft>№ страх. полиса</td>";
    $MAIN .= "  <td id=tleft>Форма обучения</td>";
  }elseif($type == 2){
    $MAIN .= "  <td id=tleft>Адрес</td>";
  }elseif($type == 3){
    $MAIN .= "  <td id=tcenter>Номер</td>";
    $MAIN .= "  <td id=tleft>Дата рождения</td>";
  }

  $MAIN .= "</tr>";
  $n=0;
  while(getrow($mass, $row))
  {
    $n++;
    $MAIN .= "<tr>";
    $MAIN .= "  <td id=tcenter>$n</td>";
    $MAIN .= "  <td id=tleft>{$row['STUDENT_LNAME']} {$row['STUDENT_FNAME']} {$row['STUDENT_MNAME']}</td>";
    if($type == 1){
      $MAIN .= "  <td id=tleft>{$row['STUDENT_PERSNO']}</td>";
      $MAIN .= "  <td id=tleft>{$row['STUDENT_ZACHNO']}</td>";
      $MAIN .= "  <td id=tleft>{$row['STUDENT_STRAHNO']}</td>";
      $MAIN .= "  <td id=tleft>{$row['EDUFORM_ABBR']}</td>";
    }elseif($type == 2){
      $adr = '';
      getdbrow("STUDADD_ITM({$row['STUDSGRP_ID']})", $row1);
      if($row1['STUDENT_POSTINDEX'])
        $adr .= $row1['STUDENT_POSTINDEX'].' ';
      if($row1['COUNTRY_ID']){
        getdbrow("COUNTRY_ITM({$row['COUNTRY_ID']})", $row2);
        if($row2['COUNTRY_SNAME'])
          $adr .= $row2['COUNTRY_SNAME'].' ';
      }
      if($row1['CITY_ID']){
        getdbrow("CITY_ITM({$row1['CITY_ID']})", $row2);
        if($row2['CITY_NAME'])
          $adr .= 'г. '.$row2['CITY_NAME'].' ';
      }
      if($row1['STUDENT_NPUNKT'])
        $adr .= $row1['STUDENT_NPUNKT'].' ';
      if($row1['STUDENT_STREET'])
        $adr .= 'ул. '.$row1['STUDENT_STREET'].' ';
      if($row1['STUDENT_BLDNO'])
        $adr .= 'д. '.$row1['STUDENT_BLDNO'].' ';
      if($row1['STUDENT_FLATNO'])
        $adr .= 'кв. '.$row1['STUDENT_FLATNO'].' ';
      $MAIN .= "<td id=tleft>$adr</td>";


    }elseif($type == 3){
      $MAIN .= "  <td id=tcenter>{$row['STUDENT_PERSNO']}</td>";
      getdbrow("STUDADD_ITM({$row['STUDSGRP_ID']})", $row1);
      $dr = $row1['STUDENT_BIRTHDAY'];
      b2d($dr);
      $MAIN .= "  <td id=tleft>$dr</td>";
      
    }

    $MAIN .= "</tr>";
  }
  $MAIN .= "</table>";
}  
sst($_SERVER['HTTP_REFERER']);
echo $MAIN;
echo $DEBUG;


function thead($type, $i=""){
  global $MAIN;
  if($type == 1){
    $MAIN .= "<table id=tabotchet>";
    $MAIN .= "<tr>";
    $MAIN .= "  <td id=width1></td>";
    $MAIN .= "  <td id=width8></td>";
    $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width2></td>";
    $MAIN .= "  <td id=width2>$i</td>";
    $MAIN .= "</tr>";
  }
  if($type == 2){
    $MAIN .= "<tr>";
    $MAIN .= "  <td id=tcenter rowspan=2>№ пп</td>";
//    $MAIN .= "  <td rowspan=2>№ пп</td>";
    $MAIN .= "  <td id=tcenter rowspan=2>Фамилия и инициалы</td>";
    $MAIN .= "  <td id=tcenter rowspan=2>№ зачетной книжки</td>";
    $MAIN .= "  <td id=tcenter colspan=2>Экзаменационная оценка</td>";
    $MAIN .= "  <td id=tcenter rowspan=2>Подпись препода-вателя</td>";
    $MAIN .= "</tr>";
    $MAIN .= "<tr>";
    $MAIN .= "  <td id=tcenter>цифрой</td>";
    $MAIN .= "  <td id=tcenter>прописью</td>";
    $MAIN .= "</tr>";
  }
}
?>
</body> 
</html>