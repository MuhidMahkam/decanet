<?php

declare(strict_types=1);

namespace Decanet\View;

final class Html
{
    public static function escape(string|int|float|null $value): string
    {
        return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }
}
