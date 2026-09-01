<?php

declare(strict_types=1);

namespace Decanet\Tests\Application;

use Decanet\Application\LegacyPageController;
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
}
