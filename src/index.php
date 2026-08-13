<html>
<head>
<meta http-equiv=Content-Type content="text/html; charset=utf-8">
<style>
a:link img, a:visited img {border-style: none;padding:0;margin:0; }
</style>
</head>
<body>
<?php
session_start();
$_SESSION = array();
session_destroy();
header("Location: login.php");
?>
<a href="login.php"><img src=begin.gif alt='Вход в DecaNet'></a>
</body> 
</html>