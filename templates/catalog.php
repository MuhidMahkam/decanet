<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <title><?= $title ?></title>
    <?= $styles ?>
</head>
<body>
<table id="menu" cellspacing="0" border height="100%" width="100%">
    <tr>
        <td><a href="earth.php"><img src="/dnllogo.gif" alt="Деканет"></a></td>
        <td width="100%"><?= $object ?></td>
    </tr>
    <tr>
        <td align="center"><?= $version ?></td>
        <td><span id="redtext"><?= $error ?></span><span id="greentext"><?= $message ?></span></td>
    </tr>
    <tr valign="top" height="100%">
        <td><?= $menu ?></td>
        <td>
            <table id="main" cellspacing="0" height="100%" width="100%">
                <tr height="100%"><td valign="top" width="100%">
                    <table width="100%"><tr><td id="prochead"><?= $title ?></td></tr></table>
                    <?= $table ?>
                </td></tr>
                <tr><td align="right"><a href="http://saxoft/index.htm">(c)Saxoft</a></td></tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
