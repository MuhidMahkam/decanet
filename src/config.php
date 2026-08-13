<?php

  if (PHP_OS == 'WINNT') {  
  //   Win
    $debug = true;
  }
  else {  
  //   Linux
    $debug = false;
  }

  //$debug = true;
  $debug = false;

  // $demouser = true;
  $demouser = false;

  //$nogoto = true;
  $nogoto = false;

  mysqli_report(MYSQLI_REPORT_OFF);

  error_reporting(0);

  $__logintimeout__ = 15*60; //15 минут бездействия

?>