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

    public function testItPublishesTheCurrentRouteForLegacyHelpers(): void
    {
        $directory = sys_get_temp_dir() . '/decanet-route-test-' . bin2hex(random_bytes(4));
        mkdir($directory);
        file_put_contents(
            $directory . '/login.php',
            '<?php $GLOBALS["legacy_route_seen"] = $GLOBALS["__routedurlpage__"];'
        );
        $_SERVER['REQUEST_METHOD'] = 'GET';
        $_SERVER['REQUEST_URI'] = '/login.php';
        $_SERVER['QUERY_STRING'] = '';

        (new LegacyPageController($directory))(Request::fromGlobals());

        self::assertSame('/login.php', $GLOBALS['legacy_route_seen']);
        unlink($directory . '/login.php');
        rmdir($directory);
        unset($GLOBALS['legacy_route_seen'], $GLOBALS['__routedurlpage__']);
    }
}
