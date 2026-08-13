<?php
$focus = '';
//if(!isset($_REQUEST['nschet']))
//  $focus = 'onload=this.document.vvod.nschet.focus()';
$body = "<body $focus>";
include "global.php";

getp('fp');
getdt('gfp_x','fp',1);
getp('tp');
getdt('gtp_x','tp',1);

if($edit){
  head('Событие');
  getdbrow("DCLOG_ITM($edit)", $row);
  $tp = $row['DCLOG_DT'];
  $login = $row['DUNAME'];
  $fn = $row['DUSER_FNAME'];
  $ln = $row['DUSER_LNAME'];
  $mn = $row['DUSER_MNAME'];
  $type = $row['MANAGERTYPE_NAME'];
  $query = htmlentities($row['DCLOG_EXPRESSION'],ENT_QUOTES,'utf-8');
  $errno = $row['DCLOG_IRESULT'];
  $error = htmlentities($row['DCLOG_SRESULT'],ENT_QUOTES,'utf-8');
  $iret = $row['DCLOG_IRET'];
  formb();
/*
  pole('время','tp', 20,'','','',true,true,false);
  pole('логин','login', 20,'','','',true,true,false);
  pole('фамилия','ln', 20,'','','',true,true,false);
  pole('имя','fn', 20,'','','',true,true,false);
  pole('отчество','mn', 20,'','','',true,true,false);
  pole('тип','type', 20,'','','',true,true,false);
  pole('запрос','query', 80,'','','',true,true,false);
  pole('errno','errno', 10,'','','',true,true,false);
  pole('error','error', 80,'','','',true,true,false);
  pole('результат','iret', 10,'','','',true,true,false);
*/
  pole('время','tp', 20);
  pole('логин','login',20);
  pole('фамилия','ln', 20);
  pole('имя','fn', 20);
  pole('отчество','mn', 20);
  pole('тип','type', 20);
  pole('запрос','query', 80);
  pole('errno','errno', 10);
  pole('error','error', 80);
  pole('результат','iret', 10);
  forme(false);
  mainpaint();
}

head('Лог файл');

getp('slogin');
getp('login');
getp('fam');
getp('query');
getp('errno');
getp('error');
getp('type');
getp('iret');

if($cancel)
  dcgoto('admin.php');
formb();
pole('slogin','slogin', 10,'','','',false);
pole('логин','login', 10,'','','',false);
pole('фамилия','fam', 10,'','','',false);
pole('запрос','query', 40,'','','',false);
$MAIN .='<br>';
//pole('errno','errno', 10,'','','',false);
pole('error','error', 10,'','','',false);
pole('результат','iret', 10,'','','',false);
pole('тип','type', 10, 'MANTYPE_LST()','MANAGERTYPE_NAME','MANAGERTYPE_ID',false,true);
pole("от",'fp',10,'','','',false,true,true," <input type=image $P_CAL name=gfp>");
pole("до",'tp',10,'','','',false,true,true," <input type=image $P_CAL name=gtp>");
forme();

//i2b($errno);
i2b($type);
d2b($fp);
d2b($tp);
s2b($slogin);
s2b($login);
s2b($fam);
s2b($query);
s2b($error);
s2b($iret);

getdbmass("DCLOG_LST($slogin,$login,$fam,$query,$error,$iret,$type,$fp,$tp)", $mass);
messall($mass);
$MAIN .= "<table width=100%>";
$MAIN .= "<tr id=head1>";
$MAIN .= "<td>№</td>";
$MAIN .= "<td>Время</td>";
$MAIN .= "<td>Логин</td>";
$MAIN .= "<td>Строка запроса</td>";
$MAIN .= "<td>Возврат</td>";
$MAIN .= "</tr>";
$n=0;
while(getrow($mass, $row)){
  $n++;
  $col = $n%2+1;
  if($row['DCLOG_IRESULT'])
    $col+=2;
  $MAIN .= "<tr id=col{$col}>";
  $MAIN .= "<td><a href='{$__routedurlpage__}?edit={$row['DCLOG_ID']}'>$n</td>";
  $MAIN .= "<td>{$row['DCLOG_DT']}</td>";
  $MAIN .= "<td>{$row['DUNAME']}</td>";
  $MAIN .= "<td>{$row['DCLOG_EXPRESSION']}</td>";
  $MAIN .= "<td>{$row['DCLOG_IRET']}</td>";
  $MAIN .= "</tr>";
  if(($n >= $MAXREC) && (!isset($_GET['allview'])))
    break;
}
$MAIN .= "</table>";

mainpaint();
?>