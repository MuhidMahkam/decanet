<?php

declare(strict_types=1);

namespace Decanet\Tests\View;

use Decanet\View\Html;
use PHPUnit\Framework\TestCase;

final class HtmlTest extends TestCase
{
    public function testItEscapesUntrustedHtml(): void
    {
        self::assertSame('&lt;script&gt;&quot;x&quot;&lt;/script&gt;', Html::escape('<script>"x"</script>'));
    }
}
