<?php

declare(strict_types=1);

namespace Decanet\Tests\Application;

use Decanet\Application\LegacyPageController;
use Decanet\Http\Request;
use PHPUnit\Framework\TestCase;

final class LegacyPageControllerTest extends TestCase
{
    public function testItSupportsOnlyPhpUrls(): void
    {
        $routes = LegacyPageController::routes();

        self::assertContains('/login.php', $routes);
        self::assertContains('/student.php', $routes);
        self::assertNotContains('/login.sit', $routes);
    }

    public function testItReturnsTheLegacyPageForGlobalScopeRendering(): void
    {
        $directory = sys_get_temp_dir() . '/decanet-route-test-' . bin2hex(random_bytes(4));
        mkdir($directory);
        file_put_contents($directory . '/login.php', '<?php');
        $_SERVER['REQUEST_METHOD'] = 'GET';
        $_SERVER['REQUEST_URI'] = '/login.php';
        $_SERVER['QUERY_STRING'] = '';

        self::assertSame($directory . '/login.php', (new LegacyPageController($directory))(Request::fromGlobals()));
        unlink($directory . '/login.php');
        rmdir($directory);
    }
}
