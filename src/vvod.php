<?php
if(!isset($_POST['doc_no']) && !isset($_REQUEST['glm']))
  $body = "<body onload=this.document.vvod.doc_no.focus()>";
include "global.php";
getp('doc_no');
getp('doc_open');
getp('res_id');

if($doc_no){
  getdbrow("ACADOCINPUT('$doc_no')", $row);
  $doc_id = $row['DOCUMENT_ID'];
  if(!$row){
    $mess = urlencode("Ошибка! Документ № $doc_no не найден, возможно уже был введен!");
    dcgoto("vvod.php?ermess=$mess");
  }
  $res = $row['RESULT_ID'];
  if($res)
    $res_id = "&res_id=$res";
  else
    $res_id = '';
  dcgoto("doc.php?doc_id=$doc_id$res_id");
}

head('Ввод данных академической успеваемости');
$MAIN .= "<form name=vvod method=post>"; 
$MAIN .= "Номер документа: <input name=doc_no tabindex=1 type=text><br><br>";
$MAIN .= "<input type=submit value='Поиск'>";
$MAIN .= "</form>";
mainpaint();
?>