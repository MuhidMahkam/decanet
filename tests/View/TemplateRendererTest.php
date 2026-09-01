<?php

declare(strict_types=1);

namespace Decanet\Tests\View;

use Decanet\View\TemplateRenderer;
use PHPUnit\Framework\TestCase;
use RuntimeException;

final class TemplateRendererTest extends TestCase
{
    public function testItRendersTemplateDataWithoutOverwritingLocalVariables(): void
    {
        $directory = sys_get_temp_dir() . '/decanet-template-' . bin2hex(random_bytes(4));
        mkdir($directory);
        file_put_contents($directory . '/welcome.php', 'Hello <?= $name ?>');

        $renderer = new TemplateRenderer($directory);

        self::assertSame('Hello Ada', $renderer->render('welcome.php', ['name' => 'Ada']));
        unlink($directory . '/welcome.php');
        rmdir($directory);
    }

    public function testItRejectsPathTraversal(): void
    {
        $this->expectException(RuntimeException::class);
        (new TemplateRenderer(sys_get_temp_dir()))->render('../secret.php');
    }
}
