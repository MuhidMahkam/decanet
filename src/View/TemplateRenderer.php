<?php

declare(strict_types=1);

namespace Decanet\View;

use RuntimeException;

final class TemplateRenderer
{
    public function __construct(private readonly string $templateDirectory)
    {
    }

    /** @param array<string, mixed> $data */
    public function render(string $template, array $data = []): string
    {
        if (preg_match('/^[a-z0-9][a-z0-9_-]*\.php$/i', $template) !== 1) {
            throw new RuntimeException('Invalid template name.');
        }

        $file = $this->templateDirectory . '/' . $template;
        if (!is_file($file)) {
            throw new RuntimeException('Template not found.');
        }

        extract($data, EXTR_SKIP);
        ob_start();
        require $file;

        return (string) ob_get_clean();
    }
}
