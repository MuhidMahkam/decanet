<?php

declare(strict_types=1);

namespace Decanet\Application;

use Decanet\Http\Request;
use RuntimeException;

final class LegacyPageController
{
    /** @var array<string, string> */
    private const PAGES = [
        '/admin.php' => 'admin.php', '/bask.php' => 'bask.php', '/division.php' => 'division.php',
        '/doc.php' => 'doc.php', '/docum.php' => 'docum.php', '/error.php' => 'error.php',
        '/facultet.php' => 'facultet.php', '/find.php' => 'find.php', '/karta.php' => 'karta.php',
        '/listgrp.php' => 'listgrp.php', '/log.php' => 'log.php', '/login.php' => 'login.php',
        '/otchet.php' => 'otchet.php', '/protokol.php' => 'protokol.php',
        '/school.php' => 'school.php', '/sgroup.php' => 'sgroup.php', '/student.php' => 'student.php',
        '/svodka.php' => 'svodka.php', '/vipiska.php' => 'vipiska.php', '/vvod.php' => 'vvod.php',
        '/dnhelp.html' => 'dnhelp.html',
    ];

    public function __construct(private readonly string $legacyDirectory)
    {
    }

    /** @return list<string> */
    public static function routes(): array
    {
        return array_keys(self::PAGES);
    }

    public function __invoke(Request $request): string
    {
        $page = self::PAGES[$request->path] ?? null;
        if ($page === null) {
            throw new RuntimeException('Unknown legacy route.');
        }

        $file = $this->legacyDirectory . '/' . $page;
        if (!is_file($file)) {
            throw new RuntimeException('Legacy page is missing.');
        }

        return $file;
    }
}
