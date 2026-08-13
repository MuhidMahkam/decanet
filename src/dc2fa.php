<?php

  declare(strict_types=1);

  use chillerlan\Authenticator\{Authenticator, AuthenticatorOptionsTrait};
  use chillerlan\Authenticator\Authenticators\AuthenticatorInterface;
  use chillerlan\QRCode\{QRCode, QROptionsTrait};
  use chillerlan\QRCode\Data\QRMatrix;
  use chillerlan\QRCode\Output\QRMarkupSVG;
  use chillerlan\Settings\SettingsContainerAbstract;

  function set2FAoptions()
  {

    // create a new options container on the fly that hosts both, authenticator and qrcode
    $options = new class extends SettingsContainerAbstract{
    	use AuthenticatorOptionsTrait, QROptionsTrait;
    };

    // AuthenticatorOptionsTrait
    $options->mode                 = AuthenticatorInterface::TOTP;
    $options->digits               = 6;
    $options->algorithm            = AuthenticatorInterface::ALGO_SHA1;

    // QROptionsTrait
    $options->version              = 7;
    $options->addQuietzone         = false;
    $options->outputInterface      = QRMarkupSVG::class;
    $options->outputBase64         = false;
    $options->svgAddXmlHeader      = false;
    $options->cssClass             = 'my-qrcode';
    $options->drawLightModules     = false;
    $options->svgUseFillAttributes = false;
    $options->drawCircularModules  = true;
    $options->circleRadius         = 0.4;
    $options->connectPaths         = true;
//    $imageTransparent              = true;
    $options->keepAsSquare         = [
    	QRMatrix::M_FINDER_DARK,
    	QRMatrix::M_FINDER_DOT,
    	QRMatrix::M_ALIGNMENT_DARK,
    ];
    $options->svgDefs              = '
    	<linearGradient id="gradient" x1="1" y2="1">
    		<stop id="stop1" offset="0" />
    		<stop id="stop2" offset="0.5"/>
    		<stop id="stop3" offset="1"/>
    	</linearGradient>';

    return $options;
  }

  function gen2FAsecret($opt)
  {

    // invoke the worker instances
    $dcauth   = new Authenticator($opt);

    // create a secret and URI, generate the QR Code
    $secret = $dcauth->createSecret(24);
    $secret_b32 = $dcauth->getSecret();
    return $secret_b32;
  }

  function make2FAsvg($opt, $sec)
  {

    // invoke the worker instances
    $dcauth   = new Authenticator($opt);
    $dcqrcode = new QRCode($opt);

    // create a secret and URI, generate the QR Code
    $secret = $dcauth->setSecret($sec);
    $uri    = $dcauth->getUri('decanet 2fa', 'decanet.ru');
    //$uri    = $dcauth->getUri('DEMO', 'decanet.ru');
    // skey DEMO: 4OILM2GTNJU7PBKOJSFPCGFJXNBINVLS3UWMOZY
    $svg    = $dcqrcode->render($uri);
    return $svg;
  }

  function verify2FAcode($opt, $sec, $code)
  {

    // invoke the worker instances
    $dcauth   = new Authenticator($opt);

    $dcauth->setSecret($sec);

    $result = $dcauth->verify($code);

    return $result;
  }

?>

