<?php

declare(strict_types=1);

namespace Decanet\Application;

use Decanet\Http\Request;
use RuntimeException;

final class LegacyPageController
{
    /** @var array<string, string> */
    private const PAGES = [
        '/admin.php' => 'admin.php', '/bask.php' => 'bask.php',
        '/doc.php' => 'doc.php', '/docum.php' => 'docum.php', '/error.php' => 'error.php',
        '/find.php' => 'find.php', '/karta.php' => 'karta.php',
        '/listgrp.php' => 'listgrp.php', '/log.php' => 'log.php', '/login.php' => 'login.php',
        '/otchet.php' => 'otchet.php', '/protokol.php' => 'protokol.php',
        '/sgroup.php' => 'sgroup.php', '/student.php' => 'student.php',
        '/svodka.php' => 'svodka.php', '/vipiska.php' => 'vipiska.php', '/vvod.php' => 'vvod.php',
        '/dnhelp.html' => 'dnhelp.html',
    ];

    /** @var array<string, string> */
    private const FORM_FALLBACKS = [
        '/facultet.php' => 'facultet.php',
        '/division.php' => 'division.php',
    ];

    public function __construct(private readonly string $legacyDirectory)
    {
    }

    /** @return list<string> */
    public static function routes(): array
    {
        return array_keys(self::PAGES);
    }

    /** @return list<string> */
    public static function formRoutes(): array
    {
        return array_keys(self::FORM_FALLBACKS);
    }

    public function __invoke(Request $request): string
    {
        return $this->page($request->path, self::PAGES, 'Unknown legacy route.');
    }

    public function formFallback(Request $request): string
    {
        return $this->page($request->path, self::FORM_FALLBACKS, 'Unknown legacy form fallback.');
    }

    /** @param array<string, string> $pages */
    private function page(string $path, array $pages, string $error): string
    {
        $page = $pages[$path] ?? null;
        if ($page === null) {
            throw new RuntimeException($error);
        }

        $file = $this->legacyDirectory . '/' . $page;
        if (!is_file($file)) {
            throw new RuntimeException('Legacy page is missing.');
        }

        return $file;
    }
}
